import 'package:flutter/material.dart';

import '../features/auth/auth_page.dart';

class TaxiYaPassengerApp extends StatelessWidget {
  const TaxiYaPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Ya Passenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const AuthPage(title: 'Taxi Ya Passenger'),
    );
  }
}

