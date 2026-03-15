import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  bool _shareTrip = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    _nameController = TextEditingController(text: auth.user?['full_name']?.toString() ?? '');
    _emergencyNameController = TextEditingController(text: auth.user?['emergency_contact_name']?.toString() ?? '');
    _emergencyPhoneController = TextEditingController(text: auth.user?['emergency_contact_phone']?.toString() ?? '');
    _shareTrip = auth.user?['share_trip_default'] == true;
    _notifications = auth.user?['notifications_enabled'] != false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = ref.read(authControllerProvider);
    final token = auth.token;
    if (token == null) return;
    final api = ref.read(apiServiceProvider);

    await api.updateProfile(token, _nameController.text.trim().isEmpty ? 'Pasajero Taxi Ya' : _nameController.text.trim());
    await api.updateSettings(token, {
      'emergencyContactName': _emergencyNameController.text.trim(),
      'emergencyContactPhone': _emergencyPhoneController.text.trim(),
      'shareTripDefault': _shareTrip,
      'notificationsEnabled': _notifications,
      'preferredRideType': 'economico',
    });
    await ref.read(authControllerProvider.notifier).refreshMe();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(color: Color(0xFF122117), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 14),
                Text(auth.phoneNumber, style: const TextStyle(color: Color(0xFF5C6E62))),
                const SizedBox(height: 18),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre completo')),
                const SizedBox(height: 12),
                TextField(controller: _emergencyNameController, decoration: const InputDecoration(labelText: 'Contacto de emergencia')),
                const SizedBox(height: 12),
                TextField(controller: _emergencyPhoneController, decoration: const InputDecoration(labelText: 'Telefono de emergencia')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _shareTrip,
            onChanged: (value) => setState(() => _shareTrip = value),
            title: const Text('Compartir viaje por defecto'),
          ),
          SwitchListTile(
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
            title: const Text('Notificaciones activas'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Guardar cambios')),
        ],
      ),
    );
  }
}
