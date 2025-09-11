import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Manila coordinates
    final LatLng manilaCoords = LatLng(14.5995, 120.9842);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Map"),
        backgroundColor: Colors.blue,
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: manilaCoords, initialZoom: 13),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.smart_isp',
          ),

          // Marker in Manila
          MarkerLayer(
            markers: [
              Marker(
                point: manilaCoords,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
