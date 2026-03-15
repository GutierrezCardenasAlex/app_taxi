import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  Future<void> _sendOtp() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.length < 8) {
      _showMessage('Ingresa un numero valido');
      return;
    }

    try {
      final otp = await ref.read(authControllerProvider.notifier).sendOtp(phoneNumber);
      if (!mounted) return;
      _showMessage(
        otp == null
            ? 'Codigo enviado correctamente'
            : 'Codigo de prueba enviado: $otp',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo enviar el OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage('El codigo debe tener 6 digitos');
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(otp);
      if (!mounted) return;
      _showMessage('Bienvenido a Taxi Ya');
    } catch (_) {
      if (!mounted) return;
      _showMessage('OTP incorrecto');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1C14), Color(0xFF1E3B2E), Color(0xFFF7F2E8)],
            stops: [0.0, 0.42, 0.42],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4A422),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.local_taxi_rounded, color: Colors.black87, size: 30),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pide tu taxi en Potosi sin rodeos.',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Login rapido por telefono, seguimiento en vivo y cobertura solo dentro de la ciudad.',
                  style: TextStyle(fontSize: 16, color: Color(0xFFD5E6D7)),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 24,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingresa con tu telefono',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Te enviaremos un codigo OTP para entrar.',
                        style: TextStyle(color: Color(0xFF55685B)),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numero de telefono',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: authState.isLoading ? null : _sendOtp,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1FA35B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(authState.isLoading ? 'Enviando...' : 'Enviar OTP'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: authState.isOtpSent
                            ? Column(
                                key: const ValueKey('otp-form'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 28),
                                  const Text(
                                    'Verifica el codigo',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    decoration: const InputDecoration(
                                      labelText: 'Codigo OTP',
                                      prefixIcon: Icon(Icons.lock_clock_rounded),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: authState.isLoading ? null : _verifyOtp,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        side: const BorderSide(color: Color(0xFF1FA35B), width: 1.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: Text(authState.isLoading ? 'Verificando...' : 'Entrar'),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (authState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Color(0xFFC54B4B)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: _FeatureChip(icon: Icons.gps_fixed_rounded, label: 'GPS en vivo')),
                    SizedBox(width: 12),
                    Expanded(child: _FeatureChip(icon: Icons.shield_rounded, label: 'Solo Potosi')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
