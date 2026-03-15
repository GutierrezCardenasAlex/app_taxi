import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';

class DriverAuthState {
  const DriverAuthState({
    this.isInitialized = false,
    this.phoneNumber = '',
    this.token,
    this.user,
    this.driver,
    this.isOtpSent = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isInitialized;
  final String phoneNumber;
  final String? token;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? driver;
  final bool isOtpSent;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  DriverAuthState copyWith({
    bool? isInitialized,
    String? phoneNumber,
    String? token,
    Map<String, dynamic>? user,
    Map<String, dynamic>? driver,
    bool? isOtpSent,
    bool? isLoading,
    String? errorMessage,
    bool clearToken = false,
    bool clearUser = false,
    bool clearDriver = false,
    bool clearError = false,
  }) {
    return DriverAuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      driver: clearDriver ? null : (driver ?? this.driver),
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OfferItem {
  const OfferItem({
    required this.tripId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
  });

  final String tripId;
  final String pickupAddress;
  final String dropoffAddress;
  final num estimatedFare;
}

class DriverTripState {
  const DriverTripState({
    this.status = 'offline',
    this.currentTrip,
    this.offers = const [],
    this.currentLocation,
    this.errorMessage,
    this.isBusy = false,
    this.history = const [],
    this.notifications = const [],
  });

  final String status;
  final Map<String, dynamic>? currentTrip;
  final List<OfferItem> offers;
  final LatLng? currentLocation;
  final String? errorMessage;
  final bool isBusy;
  final List<Map<String, dynamic>> history;
  final List<String> notifications;

  DriverTripState copyWith({
    String? status,
    Map<String, dynamic>? currentTrip,
    List<OfferItem>? offers,
    LatLng? currentLocation,
    String? errorMessage,
    bool? isBusy,
    List<Map<String, dynamic>>? history,
    List<String>? notifications,
    bool clearTrip = false,
    bool clearError = false,
  }) {
    return DriverTripState(
      status: status ?? this.status,
      currentTrip: clearTrip ? null : (currentTrip ?? this.currentTrip),
      offers: offers ?? this.offers,
      currentLocation: currentLocation ?? this.currentLocation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBusy: isBusy ?? this.isBusy,
      history: history ?? this.history,
      notifications: notifications ?? this.notifications,
    );
  }
}

class DriverAuthController extends StateNotifier<DriverAuthState> {
  DriverAuthController(this._api) : super(const DriverAuthState());

  final ApiService _api;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token');
    final phone = prefs.getString('driver_phone') ?? '';
    state = state.copyWith(isInitialized: true, token: token, phoneNumber: phone);
    if (token != null && token.isNotEmpty) {
      await refreshProfile();
    }
  }

  Future<String?> sendOtp(String phone) async {
    state = state.copyWith(isInitialized: true, phoneNumber: phone, isLoading: true, clearError: true);
    try {
      final response = await _api.sendOtp(phone);
      state = state.copyWith(isLoading: false, isOtpSent: true);
      return response.data['otp'] as String?;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'No se pudo enviar el OTP');
      rethrow;
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.verifyOtp(state.phoneNumber, otp);
      state = state.copyWith(token: response.data['token'] as String?, user: Map<String, dynamic>.from(response.data['user'] as Map), isLoading: false);
      await _persist();
      await refreshProfile();
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'OTP incorrecto');
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    if (state.token == null) return;
    final me = await _api.fetchMe(state.token!);
    final driver = await _api.fetchDriverProfile(state.token!);
    state = state.copyWith(
      user: Map<String, dynamic>.from(me.data as Map),
      driver: driver.data == null ? null : Map<String, dynamic>.from(driver.data as Map),
      isInitialized: true,
    );
    await _persist();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_token');
    await prefs.remove('driver_phone');
    state = const DriverAuthState(isInitialized: true);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.token != null) {
      await prefs.setString('driver_token', state.token!);
    }
    await prefs.setString('driver_phone', state.phoneNumber);
  }
}

class DriverTripController extends StateNotifier<DriverTripState> {
  DriverTripController(this._api, this._socketService, this._locationService) : super(const DriverTripState());

  final ApiService _api;
  final SocketService _socketService;
  final LocationService _locationService;
  StreamSubscription? _locationSub;
  StreamSubscription? _socketSub;
  WebSocketChannel? _socket;
  String? _driverId;

  Future<void> initialize(String token, Map<String, dynamic>? driver) async {
    _driverId = driver?['driver_id']?.toString();
    if (_driverId == null || _driverId!.isEmpty) return;
    final activeTrip = await _api.fetchActiveTrip(token);
    final offersResponse = await _api.fetchOffers(token);
    final historyResponse = await _api.fetchDriverHistory(token);
    state = state.copyWith(
      currentTrip: activeTrip.data == null ? null : Map<String, dynamic>.from(activeTrip.data as Map),
      offers: (offersResponse.data as List)
          .map((e) => OfferItem(
                tripId: e['id'].toString(),
                pickupAddress: e['pickup_address'].toString(),
                dropoffAddress: e['dropoff_address'].toString(),
                estimatedFare: e['estimated_fare'] as num? ?? 0,
              ))
          .toList(),
      status: driver?['status']?.toString() ?? state.status,
      history: (historyResponse.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
    _bindSocket();
  }

  void _bindSocket() {
    if (_driverId == null) return;
    _socket?.sink.close();
    _socket = _socketService.connectDriverFeed(driverId: _driverId, tripId: state.currentTrip?['id']?.toString());
    _socketSub?.cancel();
    _socketSub = _socket!.stream.listen((message) {
      final decoded = jsonDecode(message as String);
      final payload = decoded is Map<String, dynamic> ? decoded : Map<String, dynamic>.from(decoded as Map);
      final type = payload['type']?.toString();
      if (type == 'dispatch.offer') {
        final offer = OfferItem(
          tripId: payload['tripId'].toString(),
          pickupAddress: payload['pickupAddress'].toString(),
          dropoffAddress: payload['dropoffAddress'].toString(),
          estimatedFare: payload['estimatedFare'] as num? ?? 0,
        );
        state = state.copyWith(
          offers: [offer, ...state.offers],
          notifications: ['Nueva oferta de viaje hacia ${offer.dropoffAddress}', ...state.notifications],
        );
      } else if (type == 'trip.accepted' || type == 'trip.started' || type == 'trip.completed') {
        final trip = Map<String, dynamic>.from(payload['trip'] as Map);
        final note = type == 'trip.completed'
            ? 'Viaje completado'
            : type == 'trip.started'
                ? 'Viaje en curso'
                : 'Viaje aceptado';
        state = state.copyWith(
          currentTrip: trip,
          offers: [],
          status: trip['status'] == 'completed' ? 'available' : 'busy',
          notifications: [note, ...state.notifications],
        );
      } else if (type == 'trip.arriving') {
        final trip = Map<String, dynamic>.from(payload['trip'] as Map);
        state = state.copyWith(
          currentTrip: trip,
          notifications: ['Marcaste que llegaste al pasajero', ...state.notifications],
        );
      }
    });
  }

  Future<void> setStatus(String token, String status) async {
    final response = await _api.updateStatus(token, status);
    state = state.copyWith(status: response.data['status']?.toString() ?? status);
  }

  Future<void> beginLiveTracking(String token) async {
    final driverId = _driverId;
    if (driverId == null) return;
    await _locationSub?.cancel();
    _locationSub = _locationService.track().listen((position) async {
      final currentTripId = state.currentTrip?['id']?.toString();
      state = state.copyWith(currentLocation: LatLng(position.latitude, position.longitude));
      await _api.sendLocation(token, {
        'driverId': driverId,
        if (currentTripId != null) 'tripId': currentTripId,
        'lat': position.latitude,
        'lng': position.longitude,
        'heading': position.heading,
        'speedKmh': position.speed * 3.6,
      });
    });
  }

  Future<void> acceptOffer(String token, OfferItem offer) async {
    final driverId = _driverId;
    if (driverId == null) return;
    final response = await _api.acceptTrip(token, offer.tripId, driverId);
    state = state.copyWith(
      currentTrip: Map<String, dynamic>.from(response.data as Map),
      offers: [],
      status: 'busy',
      notifications: ['Aceptaste un viaje hacia ${offer.dropoffAddress}', ...state.notifications],
    );
    _bindSocket();
  }

  Future<void> markArrived(String token) async {
    final tripId = state.currentTrip?['id']?.toString();
    if (tripId == null) return;
    final response = await _api.markArrived(token, tripId);
    state = state.copyWith(currentTrip: Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> startTrip(String token) async {
    final tripId = state.currentTrip?['id']?.toString();
    if (tripId == null) return;
    final response = await _api.startTrip(token, tripId);
    state = state.copyWith(currentTrip: Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> endTrip(String token) async {
    final tripId = state.currentTrip?['id']?.toString();
    if (tripId == null) return;
    final response = await _api.endTrip(token, tripId, 18);
    state = state.copyWith(currentTrip: Map<String, dynamic>.from(response.data as Map), status: 'available');
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _socketSub?.cancel();
    _socket?.sink.close();
    super.dispose();
  }
}

final apiServiceProvider = Provider((ref) => ApiService());
final socketServiceProvider = Provider((ref) => SocketService());
final locationServiceProvider = Provider((ref) => LocationService());

final driverAuthControllerProvider = StateNotifierProvider<DriverAuthController, DriverAuthState>(
  (ref) => DriverAuthController(ref.read(apiServiceProvider)),
);

final driverTripControllerProvider = StateNotifierProvider<DriverTripController, DriverTripState>(
  (ref) => DriverTripController(
    ref.read(apiServiceProvider),
    ref.read(socketServiceProvider),
    ref.read(locationServiceProvider),
  ),
);
