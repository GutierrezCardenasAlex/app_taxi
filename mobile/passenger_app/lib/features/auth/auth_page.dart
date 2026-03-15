import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.title});

  final String title;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _controller = TextEditingController();
  final _api = ApiService();
  bool _loading = false;

  Future<void> _sendOtp() async {
    final phone = _controller.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu numero de telefono')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _api.sendOtp(phone);
      final otp = response.data['otp'];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            otp == null
                ? 'OTP enviado correctamente'
                : 'OTP enviado. Codigo de prueba: $otp',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando OTP: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _sendOtp,
              child: Text(_loading ? 'Sending...' : 'Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
