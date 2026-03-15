import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';

class AuthState {
  const AuthState({
    this.isInitialized = false,
    this.phoneNumber = '',
    this.token,
    this.user,
    this.isOtpSent = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isInitialized;
  final String phoneNumber;
  final String? token;
  final Map<String, dynamic>? user;
  final bool isOtpSent;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    bool? isInitialized,
    String? phoneNumber,
    String? token,
    Map<String, dynamic>? user,
    bool? isOtpSent,
    bool? isLoading,
    String? errorMessage,
    bool clearToken = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SavedPlace {
  const SavedPlace({
    required this.name,
    required this.subtitle,
    required this.location,
  });

  final String name;
  final String subtitle;
  final LatLng location;
}

const potosiPlaces = <SavedPlace>[
  SavedPlace(name: 'Terminal de Buses Potosi', subtitle: 'Transporte interdepartamental', location: LatLng(-19.5717, -65.7558)),
  SavedPlace(name: 'Mercado Central', subtitle: 'Centro comercial popular', location: LatLng(-19.5844, -65.7538)),
  SavedPlace(name: 'Plaza 10 de Noviembre', subtitle: 'Centro historico', location: LatLng(-19.5837, -65.7530)),
  SavedPlace(name: 'Hospital Daniel Bracamonte', subtitle: 'Emergencias y consultas', location: LatLng(-19.5765, -65.7589)),
  SavedPlace(name: 'Universidad Tomas Frias', subtitle: 'Campus universitario', location: LatLng(-19.5748, -65.7480)),
  SavedPlace(name: 'Cerro Rico', subtitle: 'Zona turistica', location: LatLng(-19.6074, -65.7413)),
];

class TripState {
  const TripState({
    this.selectedDestination,
    this.selectedRide = 'Economico',
    this.currentTrip,
    this.history = const [],
    this.driverMarker,
    this.isLoading = false,
    this.panelExpanded = false,
    this.errorMessage,
  });

  final SavedPlace? selectedDestination;
  final String selectedRide;
  final Map<String, dynamic>? currentTrip;
  final List<Map<String, dynamic>> history;
  final LatLng? driverMarker;
  final bool isLoading;
  final bool panelExpanded;
  final String? errorMessage;

  TripState copyWith({
    SavedPlace? selectedDestination,
    String? selectedRide,
    Map<String, dynamic>? currentTrip,
    List<Map<String, dynamic>>? history,
    LatLng? driverMarker,
    bool? isLoading,
    bool? panelExpanded,
    String? errorMessage,
    bool clearTrip = false,
    bool clearError = false,
    bool clearDestination = false,
    bool clearDriver = false,
  }) {
    return TripState(
      selectedDestination: clearDestination ? null : (selectedDestination ?? this.selectedDestination),
      selectedRide: selectedRide ?? this.selectedRide,
      currentTrip: clearTrip ? null : (currentTrip ?? this.currentTrip),
      history: history ?? this.history,
      driverMarker: clearDriver ? null : (driverMarker ?? this.driverMarker),
      isLoading: isLoading ?? this.isLoading,
      panelExpanded: panelExpanded ?? this.panelExpanded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._apiService) : super(const AuthState());

  final ApiService _apiService;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final phoneNumber = prefs.getString('auth_phone') ?? '';
    final phoneUser = prefs.getString('auth_user_phone');

    state = state.copyWith(
      isInitialized: true,
      phoneNumber: phoneNumber,
      token: token,
      user: token == null || token.isEmpty ? null : {'phone_number': phoneUser ?? phoneNumber},
    );
  }

  Future<String?> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isInitialized: true,
      phoneNumber: phoneNumber,
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await _apiService.sendOtp(phoneNumber);
      final otp = response.data['otp'] as String?;
      state = state.copyWith(isLoading: false, isOtpSent: true);
      return otp;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'No se pudo enviar el OTP');
      rethrow;
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isInitialized: true, isLoading: true, clearError: true);

    try {
      final response = await _apiService.verifyOtp(state.phoneNumber, otp);
      state = state.copyWith(
        isLoading: false,
        token: response.data['token'] as String?,
        user: Map<String, dynamic>.from(response.data['user'] as Map),
      );
      await _persistSession();
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'OTP incorrecto o expirado');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _clearSession();
    state = const AuthState(isInitialized: true);
  }

  Future<void> refreshMe() async {
    if (state.token == null) return;
    final response = await _apiService.fetchMe(state.token!);
    state = state.copyWith(user: Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.token != null) {
      await prefs.setString('auth_token', state.token!);
    }
    await prefs.setString('auth_phone', state.phoneNumber);
    await prefs.setString('auth_user_phone', state.user?['phone_number']?.toString() ?? state.phoneNumber);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_phone');
    await prefs.remove('auth_user_phone');
  }
}

class TripController extends StateNotifier<TripState> {
  TripController(this._apiService) : super(const TripState());

  final ApiService _apiService;
  Timer? _poller;

  void setDestination(SavedPlace place) {
    state = state.copyWith(selectedDestination: place, clearError: true);
  }

  void setRide(String ride) {
    state = state.copyWith(selectedRide: ride);
  }

  void setPanelExpanded(bool expanded) {
    state = state.copyWith(panelExpanded: expanded);
  }

  Future<void> fetchHistory(String token) async {
    try {
      final response = await _apiService.fetchTripHistory(token);
      final list = (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      state = state.copyWith(history: list, clearError: true);
      if (state.currentTrip == null) {
        await refreshCurrentTrip(token);
      }
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo cargar el historial');
    }
  }

  Future<void> requestTrip({
    required String token,
    required LatLng pickup,
    required String pickupAddress,
  }) async {
    final destination = state.selectedDestination;
    if (destination == null) {
      state = state.copyWith(errorMessage: 'Selecciona un destino primero');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.requestTrip({
        'pickupAddress': pickupAddress,
        'dropoffAddress': destination.name,
        'pickupLat': pickup.latitude,
        'pickupLng': pickup.longitude,
        'dropoffLat': destination.location.latitude,
        'dropoffLng': destination.location.longitude,
      }, token);
      final trip = Map<String, dynamic>.from(response.data as Map);
      state = state.copyWith(
        isLoading: false,
        currentTrip: trip,
        history: [trip, ...state.history],
      );
      _startPolling(token, trip['id']?.toString() ?? '');
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'No se pudo pedir el taxi');
      rethrow;
    }
  }

  Future<void> refreshCurrentTrip(String token) async {
    try {
      final currentTripId = state.currentTrip?['id']?.toString();
      final response = currentTripId == null || currentTripId.isEmpty
          ? await _apiService.fetchCurrentTrip(token)
          : await _apiService.fetchTripStatus(currentTripId, token);
      if (response.data == null || response.data == "") return;
      final trip = Map<String, dynamic>.from(response.data as Map);
      state = state.copyWith(currentTrip: trip, clearError: true);
      if (trip['status'] == 'accepted' || trip['status'] == 'in_progress') {
        state = state.copyWith(driverMarker: const LatLng(-19.5828, -65.7518));
      }
      if (['completed', 'cancelled'].contains(trip['status'])) {
        _poller?.cancel();
      }
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo actualizar el viaje');
    }
  }

  void applyRealtimeUpdate(Map<String, dynamic> message) {
    final type = message['type']?.toString();
    if (type == 'driver.location') {
      final lat = (message['lat'] as num?)?.toDouble();
      final lng = (message['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        state = state.copyWith(driverMarker: LatLng(lat, lng));
      }
      return;
    }

    final trip = message['trip'];
    if (trip is Map) {
      state = state.copyWith(currentTrip: Map<String, dynamic>.from(trip));
    }
  }

  void _startPolling(String token, String tripId) {
    if (tripId.isEmpty) return;
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshCurrentTrip(token),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}

final apiServiceProvider = Provider((ref) => ApiService());
final socketServiceProvider = Provider((ref) => SocketService());
final locationServiceProvider = Provider((ref) => LocationService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(apiServiceProvider)),
);

final tripControllerProvider = StateNotifierProvider<TripController, TripState>(
  (ref) => TripController(ref.read(apiServiceProvider)),
);
