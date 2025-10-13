// 📄 PART 8: map_screen.dart (improved marker and Google Maps launcher)
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client_model.dart';

class MapScreen extends StatelessWidget {
  final ClientModel client;

  const MapScreen({super.key, required this.client});

  void _openExternalNavigation(BuildContext context) async {
    final lat = client.latitude;
    final lng = client.longitude;

    // Try native Google Maps intent first
    final googleMapsIntent = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final canLaunchIntent = await canLaunchUrl(googleMapsIntent);

    if (canLaunchIntent) {
      await launchUrl(googleMapsIntent, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to browser version
    final webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      //ScaffoldMessenger.of(context).showSnackBar(
      //  const SnackBar(content: Text('Could not open Google Maps.')),
      //);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng latlng = LatLng(client.latitude, client.longitude);

    return Scaffold(
      appBar: AppBar(title: Text('Map – ${client.name}')),
      body: FlutterMap(
        options: MapOptions(
          center: latlng,
          zoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.collectorapp',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80,
                height: 80,
                point: latlng,
                child: GestureDetector(
                  onTap: () => _openExternalNavigation(context),
                  child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.directions),
        label: const Text('Open in Maps'),
        onPressed: () => _openExternalNavigation(context),
      ),
    );
  }
}
