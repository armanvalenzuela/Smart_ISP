import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/client_model.dart';
import '../services/api_service.dart';
import 'client_detail_screen.dart';
import 'profile_screen.dart';
import 'all_clients_map_screen.dart';

class HomeScreen extends StatefulWidget {
  final String collectorName;
  final String collectorTown;

  const HomeScreen({
    super.key,
    required this.collectorName,
    required this.collectorTown,
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

  final List<String> _statusOptions = ['All', 'Paid', 'Unpaid', 'Nearest'];

  int _paidCount = 0;
  int _unpaidCount = 0;

  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadDefaultPrinter();
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

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      final list = await ApiService.getClientsByTown(widget.collectorTown);
      _clients = list;
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
    setState(() => _loading = false);
  }

  double _distanceValue(ClientModel client) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      client.latitude,
      client.longitude,
    );
  }

  void _applyFilters() {
    final key = _getStatusKeyForMonth(_selectedMonth);

    _paidCount = 0;
    _unpaidCount = 0;

    _filteredClients = _clients.where((client) {
      final matchesSearch =
          client.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          client.phone.contains(_searchTerm);

      final status = client.monthlyStatus[key]?.toString().toLowerCase() ?? '';
      final matchesFilter =
          _statusFilter == 'All' ||
          _statusFilter == 'Nearest' ||
          (_statusFilter == 'Paid' && status == 'paid') ||
          (_statusFilter == 'Unpaid' && status != 'paid');

      return matchesSearch && matchesFilter;
    }).toList();

    for (final client in _filteredClients) {
      final status = client.monthlyStatus[key]?.toString().toLowerCase() ?? '';
      if (status == 'paid') {
        _paidCount++;
      } else {
        _unpaidCount++;
      }
    }

    if (_statusFilter == 'Nearest') {
      _filteredClients.sort(
        (a, b) => _distanceValue(a).compareTo(_distanceValue(b)),
      );
    } else {
      _filteredClients.sort((a, b) {
        final aPaid =
            (a.monthlyStatus[key]?.toString().toLowerCase() ?? '') == 'paid';
        final bPaid =
            (b.monthlyStatus[key]?.toString().toLowerCase() ?? '') == 'paid';
        if (aPaid != bPaid) return aPaid ? 1 : -1;
        return 0;
      });
    }

    setState(() {});
  }

  String _getStatusKeyForMonth(DateTime month) {
    return 'Status_${month.year}_${month.month.toString().padLeft(2, '0')}';
  }

  List<DropdownMenuItem<DateTime>> _buildMonthOptions() {
    final Set<String> uniqueKeys = {};

    for (final client in _clients) {
      uniqueKeys.addAll(
        client.monthlyStatus.keys.where((k) => k.startsWith('Status_')),
      );
    }

    final List<DateTime> dates = uniqueKeys.map((key) {
      final parts = key.split('_');
      final year = int.tryParse(parts[1]) ?? DateTime.now().year;
      final month = int.tryParse(parts[2]) ?? DateTime.now().month;
      return DateTime(year, month);
    }).toList();

    // Remove duplicates, sort descending
    final uniqueDates = dates.toSet().toList()..sort((a, b) => b.compareTo(a));

    return uniqueDates.map((date) {
      final label = DateFormat('MMMM yyyy').format(date);
      return DropdownMenuItem(value: date, child: Text(label));
    }).toList();
  }

  /*
  List<DropdownMenuItem<DateTime>> _buildMonthOptions() {
    final now = DateTime.now();
    final Set<DateTime> dates = {
      ...List.generate(12, (i) => DateTime(now.year, now.month - i, 1)),
      _selectedMonth,
    };

    final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));

    return sortedDates.map((date) {
      final label = DateFormat('MMMM yyyy').format(date);
      return DropdownMenuItem(value: date, child: Text(label));
    }).toList();
  }*/

  Future<void> _selectPrinter() async {
    final printer = BlueThermalPrinter.instance;
    final devices = await printer.getBondedDevices();
    if (devices.isEmpty || !mounted) return;

    final selected = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name ?? 'Unknown'),
                subtitle: Text(device.address ?? ''),
                onTap: () => Navigator.pop(context, device),
              );
            },
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
        title: const Text('Subscribers'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4093FF),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadClients,
        child: Column(
          children: [
            // header section
            Container(
              width: double.infinity,
              color: const Color(0xFF4093FF),
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                          ),
                          onChanged: (value) {
                            _searchTerm = value;
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Status dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                                _applyFilters();
                              });
                            },
                            items: _statusOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔹 Filter by Month
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<DateTime>(
                      value:
                          _buildMonthOptions().any(
                            (item) => item.value == _selectedMonth,
                          )
                          ? _selectedMonth
                          : (_buildMonthOptions().isNotEmpty
                                ? _buildMonthOptions().first.value
                                : null),
                      items: _buildMonthOptions(),
                      decoration: const InputDecoration(
                        labelText: 'Filter by month',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMonth = value;
                            _applyFilters();
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Paid/Unpaid summary
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
                ],
              ),
            ),

            // 🔸 List section (white background)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredClients.isEmpty
                  ? const Center(child: Text('No clients found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = _filteredClients[index];
                        final distance = _distanceValue(client) / 1000;
                        final key = _getStatusKeyForMonth(_selectedMonth);
                        final status =
                            client.monthlyStatus[key]
                                ?.toString()
                                .toLowerCase() ??
                            '';
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
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
                                Text('📱 ${client.phone}'),
                                Text(
                                  '💰 Status: ${status == 'paid' ? 'Paid' : 'Unpaid'}',
                                  style: TextStyle(
                                    color: status == 'paid'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_currentPosition != null)
                                  Text(
                                    '📍 ${distance.toStringAsFixed(2)} km away',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
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

      // Floating buttons (unchanged)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fabExpanded) ...[
            _buildMiniFab(Icons.map, 'Map View', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllClientsMapScreen(
                    clients: _clients,
                    collectorName: widget.collectorName,
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            _buildMiniFab(Icons.refresh, 'Refresh', _loadClients),
            const SizedBox(height: 10),
            _buildMiniFab(Icons.account_circle, 'Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    collectorName: widget.collectorName,
                    collectorTown: widget.collectorTown,
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            _buildMiniFab(Icons.print, 'Select Printer', _selectPrinter),
            const SizedBox(height: 10),
          ],
          FloatingActionButton(
            onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
            child: Icon(_fabExpanded ? Icons.close : Icons.menu),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFab(IconData icon, String tooltip, VoidCallback onPressed) {
    return FloatingActionButton(
      mini: true,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
