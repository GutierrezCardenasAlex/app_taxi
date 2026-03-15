import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class DriverProfilePage extends ConsumerStatefulWidget {
  const DriverProfilePage({super.key});

  @override
  ConsumerState<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends ConsumerState<DriverProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _licenseController;
  late final TextEditingController _plateController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _colorController;
  late final TextEditingController _yearController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(driverAuthControllerProvider);
    final driver = auth.driver;
    _nameController = TextEditingController(text: auth.user?['full_name']?.toString() ?? '');
    _licenseController = TextEditingController(text: driver?['license_number']?.toString() ?? '');
    _plateController = TextEditingController(text: driver?['plate_number']?.toString() ?? '');
    _makeController = TextEditingController(text: driver?['make']?.toString() ?? '');
    _modelController = TextEditingController(text: driver?['model']?.toString() ?? '');
    _colorController = TextEditingController(text: driver?['color']?.toString() ?? '');
    _yearController = TextEditingController(text: driver?['year']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = ref.read(driverAuthControllerProvider);
    final token = auth.token;
    if (token == null) return;

    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateAuthProfile(token, _nameController.text.trim().isEmpty ? 'Conductor Taxi Ya' : _nameController.text.trim());
      await api.saveDriverProfile(token, {
        'licenseNumber': _licenseController.text.trim(),
        'plateNumber': _plateController.text.trim(),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'color': _colorController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()),
      });
      await ref.read(driverAuthControllerProvider.notifier).refreshProfile();
      final refreshed = ref.read(driverAuthControllerProvider);
      await ref.read(driverTripControllerProvider.notifier).initialize(token, refreshed.driver);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de conductor actualizado')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del conductor')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre completo')),
                const SizedBox(height: 12),
                TextField(controller: _licenseController, decoration: const InputDecoration(labelText: 'Numero de licencia')),
                const SizedBox(height: 12),
                TextField(controller: _plateController, decoration: const InputDecoration(labelText: 'Placa')),
                const SizedBox(height: 12),
                TextField(controller: _makeController, decoration: const InputDecoration(labelText: 'Marca')),
                const SizedBox(height: 12),
                TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Modelo')),
                const SizedBox(height: 12),
                TextField(controller: _colorController, decoration: const InputDecoration(labelText: 'Color')),
                const SizedBox(height: 12),
                TextField(controller: _yearController, decoration: const InputDecoration(labelText: 'Anio'), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
