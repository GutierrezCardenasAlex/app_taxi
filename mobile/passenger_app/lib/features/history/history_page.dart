import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final token = ref.read(authControllerProvider).token;
      if (token != null) {
        ref.read(tripControllerProvider.notifier).fetchHistory(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: tripState.history.isEmpty
          ? const Center(child: Text('Aun no tienes viajes registrados'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: tripState.history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = tripState.history[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF122117),
                            child: Icon(Icons.receipt_long_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              trip['dropoff_address']?.toString() ?? 'Destino',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ),
                          Text(
                            trip['status']?.toString() ?? 'sin estado',
                            style: const TextStyle(color: Color(0xFF1FA35B), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Recojo: ${trip['pickup_address'] ?? '-'}'),
                      const SizedBox(height: 6),
                      Text('Destino: ${trip['dropoff_address'] ?? '-'}'),
                      const SizedBox(height: 6),
                      Text('Estimado: Bs ${(trip['estimated_fare'] ?? '-').toString()}'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

