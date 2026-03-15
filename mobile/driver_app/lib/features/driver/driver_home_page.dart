import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/providers.dart';
import '../../widgets/driver_drawer.dart';

class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = ref.read(driverAuthControllerProvider);
      final token = auth.token;
      if (token != null) {
        await ref.read(driverTripControllerProvider.notifier).initialize(token, auth.driver);
        await ref.read(driverTripControllerProvider.notifier).beginLiveTracking(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(driverAuthControllerProvider);
    final trip = ref.watch(driverTripControllerProvider);
    final point = trip.currentLocation ?? const LatLng(-19.5836, -65.7531);

    return Scaffold(
      drawer: const DriverDrawer(),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taxiya.driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 90,
                    height: 90,
                    child: const _BlueDriverMarker(),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton.filled(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu_rounded),
                          style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10))],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(auth.user?['phone_number']?.toString() ?? auth.phoneNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text('Estado: ${trip.status}', style: const TextStyle(color: Color(0xFF67786C))),
                                  ],
                                ),
                              ),
                              Switch(
                                value: trip.status == 'available',
                                onChanged: (value) async {
                                  final token = auth.token;
                                  if (token == null) return;
                                  await ref.read(driverTripControllerProvider.notifier).setStatus(token, value ? 'available' : 'offline');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3EEE2),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ofertas y viaje activo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        if (trip.currentTrip != null) _ActiveTripCard(trip: trip.currentTrip!),
                        if (trip.offers.isNotEmpty) ...trip.offers.take(2).map((offer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OfferCard(offer: offer, onAccept: () async {
                            final token = auth.token;
                            if (token == null) return;
                            await ref.read(driverTripControllerProvider.notifier).acceptOffer(token, offer);
                          }),
                        )),
                        if (trip.currentTrip == null && trip.offers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Sin ofertas por ahora. Mantente disponible y con GPS activo.'),
                          ),
                        if (trip.currentTrip != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () async {
                                    final token = auth.token;
                                    if (token == null) return;
                                    await ref.read(driverTripControllerProvider.notifier).markArrived(token);
                                  },
                                  child: const Text('Llegue'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    final token = auth.token;
                                    if (token == null) return;
                                    await ref.read(driverTripControllerProvider.notifier).startTrip(token);
                                  },
                                  child: const Text('Iniciar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final token = auth.token;
                                    if (token == null) return;
                                    await ref.read(driverTripControllerProvider.notifier).endTrip(token);
                                  },
                                  child: const Text('Finalizar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onAccept});

  final OfferItem offer;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer.dropoffAddress, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Recojo: ${offer.pickupAddress}'),
          const SizedBox(height: 6),
          Text('Estimado: Bs ${offer.estimatedFare}'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAccept, child: const Text('Aceptar viaje')),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip});

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Viaje activo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Estado: ${trip['status']}'),
          const SizedBox(height: 4),
          Text('Pasajero: ${trip['passenger_name'] ?? '-'}'),
          const SizedBox(height: 4),
          Text('Telefono: ${trip['passenger_phone'] ?? '-'}'),
          const SizedBox(height: 4),
          Text('Destino: ${trip['dropoff_address']}'),
        ],
      ),
    );
  }
}

class _BlueDriverMarker extends StatelessWidget {
  const _BlueDriverMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.24),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF1E88E5),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
