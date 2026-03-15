import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class DriverProfilePage extends ConsumerWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(driverAuthControllerProvider);
    final driver = auth.driver;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.user?['full_name']?.toString() ?? 'Conductor Taxi Ya', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(auth.phoneNumber),
                const SizedBox(height: 14),
                Text('Placa: ${driver?['plate_number'] ?? '-'}'),
                Text('Vehiculo: ${driver?['make'] ?? ''} ${driver?['model'] ?? ''}'),
                Text('Color: ${driver?['color'] ?? '-'}'),
                Text('Licencia: ${driver?['license_number'] ?? '-'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

