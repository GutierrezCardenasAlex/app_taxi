import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class DriverNotificationsPage extends ConsumerWidget {
  const DriverNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(driverTripControllerProvider).notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: notifications.isEmpty
          ? const Center(child: Text('Sin notificaciones'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(notifications[index]),
              ),
            ),
    );
  }
}

