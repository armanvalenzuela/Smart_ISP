import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/client_model.dart';
import 'payment_screen.dart';

class AllClientsMapScreen extends StatefulWidget {
  final List<ClientModel> clients;
  final String collectorName;

  const AllClientsMapScreen({
    super.key,
    required this.clients,
    required this.collectorName,
  });

  @override
  State<AllClientsMapScreen> createState() => _AllClientsMapScreenState();
}

class _AllClientsMapScreenState extends State<AllClientsMapScreen> {
  String _statusFilter = 'All';
  DateTime? _selectedMonth;
  LatLng? _currentPosition;

  final List<String> _statusOptions = ['All', 'Paid', 'Unpaid'];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _initMonth();
  }

  Future<void> _fetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
    }
  }

  void _initMonth() {
    final keys = widget.clients
        .expand((c) => c.monthlyStatus.keys)
        .where((k) => k.startsWith('Status_'))
        .toSet();

    final parsedDates = keys.map((k) {
      final parts = k.split('_');
      return DateTime(int.parse(parts[1]), int.parse(parts[2]));
    }).toList()
      ..sort((a, b) => b.compareTo(a));

    if (parsedDates.isNotEmpty) {
      _selectedMonth = parsedDates.first;
    }
  }

  List<ClientModel> get filteredClients {
    if (_selectedMonth == null) return [];

    final key = 'Status_${_selectedMonth!.year}_${_selectedMonth!.month.toString().padLeft(2, '0')}';

    return widget.clients.where((client) {
      if (client.latitude == 0 && client.longitude == 0) return false;

      final status = client.monthlyStatus[key]?.toString() ?? 'Unpaid';

      if (_statusFilter == 'All') return true;
      return status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();
  }

  int get paidCount => filteredClients.where((c) {
    final key = 'Status_${_selectedMonth?.year}_${_selectedMonth?.month.toString().padLeft(2, '0')}';
    return c.monthlyStatus[key]?.toString().toLowerCase() == 'paid';
  }).length;

  int get unpaidCount => filteredClients.length - paidCount;

  List<DropdownMenuItem<DateTime>> get _monthOptions {
    final keys = widget.clients
        .expand((c) => c.monthlyStatus.keys)
        .where((k) => k.startsWith('Status_'))
        .toSet();

    final dates = keys.map((k) {
      final parts = k.split('_');
      return DateTime(int.parse(parts[1]), int.parse(parts[2]));
    }).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return dates.map((d) {
      final label = DateFormat('MMMM yyyy').format(d);
      return DropdownMenuItem(value: d, child: Text(label));
    }).toList();
  }

  void _showClientOptions(ClientModel client) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('📱 ${client.phone}'),
                  Text(
                    '💰 Status: ${client.monthlyStatus['Status_${_selectedMonth?.year}_${_selectedMonth?.month.toString().padLeft(2, '0')}'] ?? 'Unpaid'}',
                    style: TextStyle(
                      color: client.statusThisMonth == 'Paid' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Go to Payment Screen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      client: client,
                      collectorName: widget.collectorName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Open in Google Maps'),
              onTap: () {
                Navigator.pop(context);
                final url = 'https://www.google.com/maps/dir/?api=1&destination=${client.latitude},${client.longitude}';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> clientMarkers = filteredClients.map((client) {
      final key = 'Status_${_selectedMonth?.year}_${_selectedMonth?.month.toString().padLeft(2, '0')}';
      final status = client.monthlyStatus[key]?.toString().toLowerCase() ?? 'unpaid';

      return Marker(
        width: 40,
        height: 40,
        point: LatLng(client.latitude, client.longitude),
        child: GestureDetector(
          onTap: () => _showClientOptions(client),
          child: Icon(
            Icons.location_pin,
            color: status == 'paid' ? Colors.green : Colors.red,
            size: 36,
          ),
        ),
      );
    }).toList();

    final List<Marker> allMarkers = [
      ...clientMarkers,
      if (_currentPosition != null)
        Marker(
          width: 40,
          height: 40,
          point: _currentPosition!,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Client Map View')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<DateTime>(
              value: _selectedMonth,
              items: _monthOptions,
              onChanged: (value) => setState(() => _selectedMonth = value),
              decoration: const InputDecoration(labelText: 'Select Month'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => setState(() => _statusFilter = value!),
              decoration: const InputDecoration(labelText: 'Filter by Status'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '📦 Paid: $paidCount    ❌ Unpaid: $unpaidCount',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _currentPosition ??
                    (widget.clients.isNotEmpty
                        ? LatLng(widget.clients.first.latitude, widget.clients.first.longitude)
                        : const LatLng(15.0, 120.0)), // default fallback
                zoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.collector_jd',
                ),
                MarkerLayer(
                  markers: allMarkers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
