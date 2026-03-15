import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/menu/driver_history_page.dart';
import '../features/menu/driver_notifications_page.dart';
import '../features/menu/driver_profile_page.dart';
import '../features/menu/driver_simple_page.dart';

class DriverDrawer extends ConsumerWidget {
  const DriverDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(driverAuthControllerProvider);
    return Drawer(
      backgroundColor: const Color(0xFF18120D),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: const Color(0xFFF4A422), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.local_taxi_rounded),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.phoneNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _item(context, 'Perfil', Icons.person_rounded, const DriverProfilePage()),
                  _item(context, 'Ciudad', Icons.location_city_rounded, const DriverSimplePage(title: 'Ciudad', description: 'Taxi Ya conductor opera dentro de Potosi y su radio operativo.')),
                  _item(context, 'Historial', Icons.history_rounded, const DriverHistoryPage()),
                  _item(context, 'Seguridad', Icons.security_rounded, const DriverSimplePage(title: 'Seguridad', description: 'Comparte ruta, reporta incidentes y usa soporte si detectas una emergencia.')),
                  _item(context, 'Configuraciones', Icons.settings_rounded, const DriverSimplePage(title: 'Configuraciones', description: 'Preferencias del conductor, notificaciones y disponibilidad.')),
                  _item(context, 'Soporte', Icons.support_agent_rounded, const DriverSimplePage(title: 'Soporte', description: 'Contacto operativo para viajes, incidentes y asistencia.')),
                  _item(context, 'Notificaciones', Icons.notifications_rounded, const DriverNotificationsPage()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(driverAuthControllerProvider.notifier).logout(),
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

  Widget _item(BuildContext context, String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF4A422)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }
}
