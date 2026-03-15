import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/providers.dart';
import '../../widgets/app_drawer.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  Position? _position;
  bool _loadingLocation = true;
  LatLng _mapCenter = const LatLng(-19.5836, -65.7531);
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  WebSocketChannel? _tripSocket;
  String? _subscribedTripId;

  final List<_NearbyDriver> _drivers = const [
    _NearbyDriver('T-101', LatLng(-19.5862, -65.7494), DriverState.available),
    _NearbyDriver('T-223', LatLng(-19.5797, -65.7578), DriverState.arriving),
    _NearbyDriver('T-847', LatLng(-19.5904, -65.7608), DriverState.onTrip),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocation();
    Future.microtask(() {
      final token = ref.read(authControllerProvider).token;
      if (token != null) {
        ref.read(tripControllerProvider.notifier).fetchHistory(token);
        ref.read(tripControllerProvider.notifier).refreshCurrentTrip(token);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tripSocket?.sink.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _position = position;
        _mapCenter = point;
        _loadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(point, 15);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _requestTrip() async {
    final auth = ref.read(authControllerProvider);
    if (auth.token == null) return;

    try {
      await ref.read(tripControllerProvider.notifier).requestTrip(
            token: auth.token!,
            pickup: _mapCenter,
            pickupAddress: 'Recojo en mapa (${_mapCenter.latitude.toStringAsFixed(4)}, ${_mapCenter.longitude.toStringAsFixed(4)})',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taxi solicitado correctamente')),
      );
    } catch (error) {
      if (!mounted) return;
      final tripState = ref.read(tripControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tripState.errorMessage ?? error.toString())),
      );
    }
  }

  void _bindTripRealtime(String? tripId) {
    if (tripId == null || tripId.isEmpty || tripId == _subscribedTripId) return;
    _subscribedTripId = tripId;
    _tripSocket?.sink.close();
    _tripSocket = ref.read(socketServiceProvider).connectLocations(tripId: tripId);
    _tripSocket!.stream.listen((message) {
      final decoded = jsonDecode(message as String);
      if (decoded is Map<String, dynamic>) {
        ref.read(tripControllerProvider.notifier).applyRealtimeUpdate(decoded);
      } else if (decoded is Map) {
        ref.read(tripControllerProvider.notifier).applyRealtimeUpdate(Map<String, dynamic>.from(decoded));
      }
    });
  }

  void _openSearch() {
    final tripController = ref.read(tripControllerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F2E6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _searchController.text.trim().toLowerCase();
            final results = potosiPlaces.where((place) {
              return place.name.toLowerCase().contains(query) ||
                  place.subtitle.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buscar destino',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 120), () {
                        if (mounted) setModalState(() {});
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ej. Terminal, mercado, plaza...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final place = results[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: ListTile(
                            onTap: () {
                              tripController.setDestination(place);
                              _mapController.move(place.location, 15);
                              Navigator.pop(context);
                              setState(() {});
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEEF6F0),
                              child: const Icon(Icons.place_rounded, color: Color(0xFF1FA35B)),
                            ),
                            title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(place.subtitle),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final tripState = ref.watch(tripControllerProvider);
    _bindTripRealtime(tripState.currentTrip?['id']?.toString());

    final currentPoint = _position == null
        ? const LatLng(-19.5836, -65.7531)
        : LatLng(_position!.latitude, _position!.longitude);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPoint,
              initialZoom: 14,
              onPositionChanged: (position, _) {
                setState(() => _mapCenter = position.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taxiya.passenger',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: const LatLng(-19.5836, -65.7531),
                    radius: 15000,
                    useRadiusInMeter: true,
                    color: const Color(0x221FA35B),
                    borderColor: const Color(0xAA1FA35B),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPoint,
                    width: 90,
                    height: 90,
                    child: const _PulseMarker(color: Color(0xFF1E88E5), icon: Icons.person_pin_circle_rounded),
                  ),
                  ..._drivers.map(
                    (driver) => Marker(
                      point: driver.location,
                      width: 80,
                      height: 80,
                      child: _PulseMarker(color: driver.color, icon: Icons.local_taxi_rounded),
                    ),
                  ),
                  if (tripState.selectedDestination != null)
                    Marker(
                      point: tripState.selectedDestination!.location,
                      width: 90,
                      height: 90,
                      child: const _PulseMarker(color: Color(0xFFF4A422), icon: Icons.flag_rounded),
                    ),
                  if (tripState.driverMarker != null)
                    Marker(
                      point: tripState.driverMarker!,
                      width: 90,
                      height: 90,
                      child: const _PulseMarker(color: Color(0xFFD84E4E), icon: Icons.directions_car_filled_rounded),
                    ),
                ],
              ),
            ],
          ),
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: const _CenterPickupPin(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  _TopSearchBar(
                    subtitle: authState.user?['phone_number']?.toString() ?? authState.phoneNumber,
                    destinationLabel: tripState.selectedDestination?.name ?? 'Buscar destino',
                    onSearchTap: _openSearch,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.11,
            minChildSize: 0.09,
            maxChildSize: 0.56,
            builder: (context, scrollController) {
              return _BottomRidePanel(
                controller: scrollController,
                isLoadingLocation: _loadingLocation,
                mapCenter: _mapCenter,
                currentTrip: tripState.currentTrip,
                destination: tripState.selectedDestination,
                selectedRide: tripState.selectedRide,
                errorMessage: tripState.errorMessage,
                isSubmitting: tripState.isLoading,
                onSelectRide: ref.read(tripControllerProvider.notifier).setRide,
                onRequestTaxi: _requestTrip,
                onOpenSearch: _openSearch,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    required this.subtitle,
    required this.destinationLabel,
    required this.onSearchTap,
  });

  final String subtitle;
  final String destinationLabel;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (context) => IconButton.filled(
            onPressed: () => Scaffold.of(context).openDrawer(),
            style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF122117)),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF0D1C14),
                    child: Icon(Icons.search_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destinationLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text(
                          subtitle.isEmpty ? 'Taxi Ya Passenger' : subtitle,
                          style: const TextStyle(color: Color(0xFF66786B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomRidePanel extends StatelessWidget {
  const _BottomRidePanel({
    required this.controller,
    required this.isLoadingLocation,
    required this.mapCenter,
    required this.currentTrip,
    required this.destination,
    required this.selectedRide,
    required this.errorMessage,
    required this.isSubmitting,
    required this.onSelectRide,
    required this.onRequestTaxi,
    required this.onOpenSearch,
  });

  final ScrollController controller;
  final bool isLoadingLocation;
  final LatLng mapCenter;
  final Map<String, dynamic>? currentTrip;
  final SavedPlace? destination;
  final String selectedRide;
  final String? errorMessage;
  final bool isSubmitting;
  final void Function(String) onSelectRide;
  final VoidCallback onRequestTaxi;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F2E6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -8)),
        ],
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD6CCBB),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Listo para tu proximo viaje', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            isLoadingLocation
                ? 'Detectando tu ubicacion actual...'
                : 'Punto de recojo en ${mapCenter.latitude.toStringAsFixed(4)}, ${mapCenter.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: Color(0xFF59695D)),
          ),
          const SizedBox(height: 18),
          _AddressField(
            icon: Icons.radio_button_checked_rounded,
            iconColor: const Color(0xFF1FA35B),
            label: 'Recojo',
            value: 'Puntero central del mapa',
          ),
          const SizedBox(height: 10),
          _AddressField(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFF4A422),
            label: 'Destino',
            value: destination?.name ?? 'Toca para buscar destino',
            onTap: onOpenSearch,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _RideTypeCard(
                  title: 'Economico',
                  eta: '3 min',
                  price: 'Bs 10-14',
                  color: const Color(0xFF1FA35B),
                  selected: selectedRide == 'Economico',
                  onTap: () => onSelectRide('Economico'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RideTypeCard(
                  title: 'Rapido',
                  eta: '1 min',
                  price: 'Bs 14-18',
                  color: const Color(0xFFF4A422),
                  selected: selectedRide == 'Rapido',
                  onTap: () => onSelectRide('Rapido'),
                ),
              ),
            ],
          ),
          if (currentTrip != null) ...[
            const SizedBox(height: 18),
            _CurrentTripCard(trip: currentTrip!),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(errorMessage!, style: const TextStyle(color: Color(0xFFC54B4B))),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onRequestTaxi,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111A12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                isSubmitting ? 'Solicitando...' : 'Pedir taxi ahora',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentTripCard extends StatelessWidget {
  const _CurrentTripCard({required this.trip});

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF122117),
                child: Icon(Icons.route_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Viaje en curso', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              Text(
                trip['status']?.toString() ?? 'requested',
                style: const TextStyle(color: Color(0xFF1FA35B), fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Destino: ${trip['dropoff_address'] ?? '-'}'),
          const SizedBox(height: 6),
          Text('Estimado: Bs ${(trip['estimated_fare'] ?? '-').toString()}'),
          if (trip['driver_name'] != null) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Tu taxista', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${trip['driver_name']}  •  ${trip['driver_phone'] ?? ''}'),
            const SizedBox(height: 4),
            Text('Vehiculo: ${trip['vehicle_make'] ?? ''} ${trip['vehicle_model'] ?? ''}'),
            const SizedBox(height: 4),
            Text('Placa: ${trip['vehicle_plate'] ?? '-'}'),
            const SizedBox(height: 4),
            Text('Calificacion: ${(trip['driver_rating'] ?? '-').toString()}'),
          ],
          const SizedBox(height: 6),
          const Text('Tracking del conductor se actualiza automaticamente cuando el viaje sea aceptado.'),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Color(0xFF6C7C70))),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideTypeCard extends StatelessWidget {
  const _RideTypeCard({
    required this.title,
    required this.eta,
    required this.price,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String eta;
  final String price;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.20),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(Icons.local_taxi_rounded, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(eta, style: const TextStyle(color: Color(0xFF6B7B70))),
              const SizedBox(height: 8),
              Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterPickupPin extends StatelessWidget {
  const _CenterPickupPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Color(0xFF111A12),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 10)),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Color(0xFFF4A422), size: 30),
        ),
        Container(width: 4, height: 18, color: const Color(0xFF111A12)),
      ],
    );
  }
}

class _PulseMarker extends StatelessWidget {
  const _PulseMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.24),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ],
    );
  }
}

enum DriverState { available, arriving, onTrip }

class _NearbyDriver {
  const _NearbyDriver(this.code, this.location, this.state);

  final String code;
  final LatLng location;
  final DriverState state;

  Color get color {
    switch (state) {
      case DriverState.available:
        return const Color(0xFF1FA35B);
      case DriverState.arriving:
        return const Color(0xFFF4A422);
      case DriverState.onTrip:
        return const Color(0xFFD84E4E);
    }
  }
}
