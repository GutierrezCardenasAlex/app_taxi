import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(tripControllerProvider).notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: notifications.isEmpty
          ? const Center(child: Text('Sin notificaciones por ahora'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(notifications[index], style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
    );
  }
}
