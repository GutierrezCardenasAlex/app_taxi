import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class DriverAuthPage extends ConsumerStatefulWidget {
  const DriverAuthPage({super.key});

  @override
  ConsumerState<DriverAuthPage> createState() => _DriverAuthPageState();
}

class _DriverAuthPageState extends ConsumerState<DriverAuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8) return;
    final otp = await ref.read(driverAuthControllerProvider.notifier).sendOtp(phone);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(otp == null ? 'OTP enviado' : 'OTP de prueba: $otp')),
    );
  }

  Future<void> _verifyOtp() async {
    await ref.read(driverAuthControllerProvider.notifier).verifyOtp(_otpController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(driverAuthControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF17120D), Color(0xFF3B2810), Color(0xFFF3EEE2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.40, 0.40],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4A422),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.local_taxi_rounded),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Conduce con Taxi Ya en Potosi.',
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recibe solicitudes, activa tu ubicacion en vivo y gestiona tus viajes desde una sola vista.',
                  style: TextStyle(color: Color(0xFFE6D9C9)),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    children: [
                      TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Telefono'), keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: auth.isLoading ? null : _sendOtp, child: const Text('Enviar OTP')),
                      if (auth.isOtpSent) ...[
                        const SizedBox(height: 16),
                        TextField(controller: _otpController, decoration: const InputDecoration(labelText: 'Codigo OTP'), maxLength: 6, keyboardType: TextInputType.number),
                        OutlinedButton(onPressed: auth.isLoading ? null : _verifyOtp, child: const Text('Ingresar')),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
