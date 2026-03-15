import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxi Ya Driver')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: const MapOptions(initialCenter: LatLng(-19.5836, -65.7531), initialZoom: 13),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: FilledButton(onPressed: () {}, child: const Text('Go Available'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Go Offline'))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

