import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class SafetyPage extends ConsumerWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripControllerProvider).currentTrip;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF102116),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Viaja con mas control', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text(
                  'Comparte tu trayecto, revisa datos del viaje y contacta soporte o emergencia si algo sale mal.',
                  style: TextStyle(color: Color(0xFFD2DED5), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SafetyAction(
            icon: Icons.share_location_rounded,
            title: 'Compartir trayecto',
            subtitle: 'Copia un resumen del viaje para enviarlo por WhatsApp o SMS',
            onTap: () async {
              final summary = trip == null
                  ? 'Taxi Ya: aun no hay un viaje activo.'
                  : 'Taxi Ya viaje ${trip['id']} - estado ${trip['status']} - destino ${trip['dropoff_address']}';
              await Clipboard.setData(ClipboardData(text: summary));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resumen del viaje copiado')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _SafetyAction(
            icon: Icons.sos_rounded,
            title: 'Boton de emergencia',
            subtitle: 'Muestra una alerta inmediata dentro de la app',
            danger: true,
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Emergencia'),
                  content: const Text('Contacta a emergencias locales y comparte tu ubicacion actual con un familiar o soporte.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SafetyAction extends StatelessWidget {
  const _SafetyAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: danger ? const Color(0xFFFDEAEA) : const Color(0xFFEEF6F0),
                child: Icon(icon, color: danger ? const Color(0xFFD84E4E) : const Color(0xFF1FA35B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF5B6D61))),
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
