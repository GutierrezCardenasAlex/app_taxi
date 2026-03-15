import 'package:flutter/material.dart';

class DriverSimplePage extends StatelessWidget {
  const DriverSimplePage({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Text(description, style: const TextStyle(height: 1.5)),
        ),
      ),
    );
  }
}

