import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 12),
            FilledButton(onPressed: () {}, child: const Text('Send OTP')),
          ],
        ),
      ),
    );
  }
}

