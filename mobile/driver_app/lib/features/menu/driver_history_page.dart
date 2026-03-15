import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class DriverHistoryPage extends ConsumerWidget {
  const DriverHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(driverTripControllerProvider).history;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: history.isEmpty
          ? const Center(child: Text('Sin viajes registrados'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final trip = history[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip['dropoff_address']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Pasajero: ${trip['passenger_name'] ?? '-'}'),
                      const SizedBox(height: 4),
                      Text('Estado: ${trip['status'] ?? '-'}'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

