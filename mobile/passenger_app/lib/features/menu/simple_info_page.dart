import 'package:flutter/material.dart';

class SimpleInfoPage extends StatelessWidget {
  const SimpleInfoPage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF243328),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
