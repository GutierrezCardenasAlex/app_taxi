import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/history/history_page.dart';
import '../features/menu/simple_info_page.dart';
import '../features/profile/profile_page.dart';
import '../features/safety/safety_page.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Drawer(
      backgroundColor: const Color(0xFF102116),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF163221), Color(0xFF0F1F16)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A422),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.local_taxi_rounded, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    authState.user?['full_name']?.toString() ?? 'Pasajero Taxi Ya',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.phoneNumber.isEmpty ? 'Sin telefono' : authState.phoneNumber,
                    style: const TextStyle(color: Color(0xFFC8D8CC)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _DrawerTile(
                    icon: Icons.person_rounded,
                    label: 'Perfil',
                    subtitle: 'Tus datos y preferencias',
                    onTap: () => _push(context, const ProfilePage()),
                  ),
                  _DrawerTile(
                    icon: Icons.location_city_rounded,
                    label: 'Ciudad',
                    subtitle: 'Cobertura y zonas activas',
                    onTap: () => _pushInfo(
                      context,
                      title: 'Ciudad',
                      description: 'Taxi Ya opera solo dentro de un radio de 15 km desde el centro de Potosi.',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.history_rounded,
                    label: 'Historial',
                    subtitle: 'Tus viajes recientes',
                    onTap: () => _push(context, const HistoryPage()),
                  ),
                  _DrawerTile(
                    icon: Icons.security_rounded,
                    label: 'Seguridad',
                    subtitle: 'Comparte trayecto y emergencia',
                    onTap: () => _push(context, const SafetyPage()),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_rounded,
                    label: 'Configuraciones',
                    subtitle: 'Preferencias de la app',
                    onTap: () => _pushInfo(
                      context,
                      title: 'Configuraciones',
                      description: 'Aqui iran idioma, notificaciones, privacidad y preferencias de viaje.',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.help_center_rounded,
                    label: 'Ayuda',
                    subtitle: 'Preguntas frecuentes',
                    onTap: () => _pushInfo(
                      context,
                      title: 'Ayuda',
                      description: 'Preguntas frecuentes sobre OTP, GPS, viajes cancelados y problemas de ubicacion.',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.support_agent_rounded,
                    label: 'Soporte',
                    subtitle: 'Atencion al pasajero',
                    onTap: () => _pushInfo(
                      context,
                      title: 'Soporte',
                      description: 'Canales de atencion, reporte de conductor, objetos perdidos e incidencias operativas.',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF365243)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesion'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _pushInfo(BuildContext context, {required String title, required String description}) {
    _push(context, SimpleInfoPage(title: title, description: description));
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.white.withValues(alpha: 0.04),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF214431),
          child: Icon(icon, color: const Color(0xFFF4A422)),
        ),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFFC4D3C7))),
        onTap: onTap,
      ),
    );
  }
}
