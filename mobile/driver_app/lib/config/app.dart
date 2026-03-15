import 'package:flutter/material.dart';

import '../features/driver/driver_home_page.dart';

class TaxiYaDriverApp extends StatelessWidget {
  const TaxiYaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Ya Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const DriverHomePage(),
    );
  }
}

