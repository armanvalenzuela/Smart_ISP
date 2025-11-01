import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:geocode/geocode.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_model.dart';
import '../services/api_service.dart';
import 'all_clients_map_screen.dart';
import 'client_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String collectorName;
  final String collectorTown;
  final int initialIndex;

  const HomeScreen({
    super.key,
    required this.collectorName,
    required this.collectorTown,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _loading = true;
  String _searchTerm = '';
  String _statusFilter = 'All';
  DateTime _selectedMonth = DateTime.now();

  Position? _currentPosition;
  BluetoothDevice? _selectedPrinter;
  Map<String, double> _clientDistances = {};

  final List<String> _statusOptions = ['All', 'Paid', 'Unpaid', 'Nearest'];
  int _paidCount = 0;
  int _unpaidCount = 0;

  int _selectedBottomIndex = 0;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _getCurrentLocation();
    await _loadClients();
    await _computeClientDistances();
    await _loadDefaultPrinter();
    setState(() => _selectedBottomIndex = widget.initialIndex);
  }

  Future<bool?> _showFiltersDialog() async {
    String tempStatus = _statusFilter;
    final dialogWidth = MediaQuery.of(context).size.width - 48;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: dialogWidth,
          child: AlertDialog(
            title: Text('Filters', style: GoogleFonts.poppins()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: _statusOptions.map((s) {
                return RadioListTile<String>(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(s, style: GoogleFonts.poppins(fontSize: 14)),
                  value: s,
                  groupValue: tempStatus,
                  onChanged: (val) {
                    if (val != null) {
                      tempStatus = val;
                      (context as Element).markNeedsBuild();
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = tempStatus;
                    _applyFilters();
                  });
                  Navigator.pop(context, true);
                },
                child: Text(
                  'Apply',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return result == true;
  }

  Future<bool?> _showMonthDialog() async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select month',
      initialDatePickerMode: DatePickerMode.day,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _applyFilters();
      });
      return true;
    }
    return false;
  }

  Future<void> _loadDefaultPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString('printerAddress');
      if (savedAddress == null) return;

      final printer = BlueThermalPrinter.instance;
      final devices = await printer.getBondedDevices();

      for (final d in devices) {
        if ((d.address ?? '') == savedAddress) {
          setState(() => _selectedPrinter = d);
          break;
        }
      }
    } catch (e) {
      debugPrint("Error loading printer: $e");
    }
  }

  Future<double> _getDistanceFromTown(String town) async {
  final geo = GeoCode();
  try {
    final location = await geo.forwardGeocoding(
      address: '$town, Philippines',
    );

    if (location.latitude == null || location.longitude == null) {
      print('⚠️ Could not find coordinates for $town');
      return 0;
    }

    final distanceMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      location.latitude!,
      location.longitude!,
    );
    return distanceMeters / 1000;
  } catch (e) {
    print('❌ Geocoding failed for $town: $e');
    return 0;
  }
}

  Future<void> _computeClientDistances() async {
    if (_currentPosition == null) await _getCurrentLocation();
    if (_currentPosition == null) return;

    Map<String, double> distances = {};
    for (final client in _clients) {
      double distance = 0.0;
      if (client.latitude != 0 && client.longitude != 0) {
        distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          client.latitude,
          client.longitude,
        ) / 1000;
      } else if (client.town.isNotEmpty) {
        distance = await _getDistanceFromTown(client.town);
      }
      distances[client.name] = distance;
    }

    setState(() => _clientDistances = distances);
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getSubscribers();
      _clients = list.map<ClientModel>((item) => ClientModel.fromJson(item)).toList();
      _applyFilters();
    } catch (e, st) {
      debugPrint('Error loading clients: $e\n$st');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final key = _getStatusKeyForMonth(_selectedMonth);
    List<ClientModel> filtered = _clients.where((client) {
      final status = client.monthlyStatus[key]?.toLowerCase() ?? '';
      final matchesSearch = _searchTerm.isEmpty ||
          client.name.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Paid' && status == 'paid') ||
          (_statusFilter == 'Unpaid' && status != 'paid');
      return matchesSearch && matchesStatus;
    }).toList();

    if (_statusFilter == 'Nearest' && _clientDistances.isNotEmpty) {
      filtered.sort((a, b) {
        final da = _clientDistances[a.name] ?? double.infinity;
        final db = _clientDistances[b.name] ?? double.infinity;
        return da.compareTo(db);
      });
    }

    int paid = 0, unpaid = 0;
    for (final c in filtered) {
      final s = c.monthlyStatus[key]?.toLowerCase() ?? '';
      if (s == 'paid') paid++;
      else unpaid++;
    }

    setState(() {
      _filteredClients = filtered;
      _paidCount = paid;
      _unpaidCount = unpaid;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  String _getStatusKeyForMonth(DateTime m) =>
      'Status_${m.year}_${m.month.toString().padLeft(2, '0')}';

  Future<void> _selectPrinter() async {
    final printer = BlueThermalPrinter.instance;
    final devices = await printer.getBondedDevices();
    if (devices.isEmpty) return;
    final selected = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: devices
                .map(
                  (d) => ListTile(
                    title: Text(d.name ?? 'Unknown'),
                    subtitle: Text(d.address ?? ''),
                    onTap: () => Navigator.pop(context, d),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printerName', selected.name ?? '');
      await prefs.setString('printerAddress', selected.address ?? '');
      setState(() => _selectedPrinter = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ⛔ Removes back arrow
        title: Text(
          'Subscribers',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4093FF),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: Column(
          children: [
            // Header and Filters UI
            Container(
              width: double.infinity,
              color: const Color(0xFF4093FF),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            _searchTerm = v;
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _showFiltersDialog,
                        icon: const Icon(Icons.filter_list, color: Colors.black87),
                        label: Text(
                          _statusFilter == 'All'
                              ? 'Filters'
                              : 'Filters ($_statusFilter)',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _showMonthDialog,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: GoogleFonts.poppins(fontSize: 15),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Paid: $_paidCount     Unpaid: $_unpaidCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      _selectedPrinter != null
                          ? 'Printer: ${_selectedPrinter!.name ?? _selectedPrinter!.address}'
                          : 'Printer: Not selected',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Client List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredClients.isEmpty
                      ? const Center(child: Text('No clients found.'))
                      : ListView.builder(
                          controller: _listScrollController,
                          padding: const EdgeInsets.all(10),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            final distance = _clientDistances[client.name] ?? 0.0;
                            final key = _getStatusKeyForMonth(_selectedMonth);
                            final status = client.monthlyStatus[key]?.toLowerCase() ?? '';
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_android,
                                            size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Text(client.phone),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: status == 'paid'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Status: ${status == 'paid' ? 'Paid' : 'Unpaid'}',
                                          style: TextStyle(
                                            color: status == 'paid'
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_currentPosition != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${distance.toStringAsFixed(2)} km away',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing:
                                    const Icon(Icons.arrow_forward_ios, size: 18),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ClientDetailScreen(
                                        client: client,
                                        collectorName: widget.collectorName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedBottomIndex,
        selectedItemColor: const Color(0xFF4093FF),
        onTap: (index) async {
          setState(() => _selectedBottomIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => ProfileScreen(
                    collectorName: widget.collectorName,
                    collectorTown: widget.collectorTown,
                    initialIndex: 1,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllClientsMapScreen(
                    clients: _clients,
                    collectorName: widget.collectorName,
                    collectorTown: widget.collectorTown,
                  ),
                ),
              );
              break;
            case 3:
              await _selectPrinter();
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Subscribers'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: 'Printer'),
        ],
      ),
    );
  }
}
