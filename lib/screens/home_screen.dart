import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final List<String> _statusOptions = ['All', 'Paid', 'Unpaid', 'Nearest'];

  int _paidCount = 0;
  int _unpaidCount = 0;

  // Bottom navigation state
  int _selectedBottomIndex = 0;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedBottomIndex = widget.initialIndex;
    _loadClients();
    _loadDefaultPrinter();
  }

  Future<bool?> _showFiltersDialog() async {
    String tempStatus = _statusFilter;

    final dialogWidth =
        MediaQuery.of(context).size.width -
        48; // align with header padding (12 left + 12 right + extra)

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: dialogWidth,
          child: AlertDialog(
            title: Text('Filters', style: GoogleFonts.poppins()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status radio options (more compact)
                Column(
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
                          // force rebuild of dialog
                          (context as Element).markNeedsBuild();
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
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
    // Show a calendar-style date picker. We only care about month+year; when user
    // picks a date we store the month from that date.
    final firstDate = DateTime(2000);
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select month',
      initialDatePickerMode: DatePickerMode.day,
      // Cannot change the theme font of the native picker easily; keep Poppins where we control dialogs.
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
  // Month options builder removed - month selection now uses a calendar-style
  // date picker via showDatePicker and we store month/year from the picked date.

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
        title: Text(
          'Subscribers',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4093FF),
        elevation: 0,
      ),
      body: Column(
        children: [
          // header section
          Container(
            width: double.infinity,
            color: const Color(0xFF4093FF),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Search field (reduced height, preserved rounded corners on focus)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Material(
                            color: Colors.white,
                            child: TextField(
                              style: GoogleFonts.poppins(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: GoogleFonts.poppins(fontSize: 15),
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              onChanged: (value) {
                                _searchTerm = value;
                                _applyFilters();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Filters button (opens dialog for Status + Month)
                    ElevatedButton.icon(
                      onPressed: _showFiltersDialog,
                      icon: const Icon(
                        Icons.filter_list,
                        color: Colors.black87,
                      ),
                      label: Text(
                        _statusFilter == 'All'
                            ? 'Filters'
                            : 'Filters (${_statusFilter})',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(80, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 Filter by Month (button opens dialog) — size matches search field
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final ok = await _showMonthDialog();
                          if (ok == true) {
                            // month already applied inside dialog
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                const SizedBox(height: 6),
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

          // 🔸 List section (white background)
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadClients,
                    child: _filteredClients.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No clients found.')),
                            ],
                          )
                        : ListView.builder(
                            controller: _listScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
          ),
        ],
      ),
      // Bottom navigation bar (replaces FAB)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedBottomIndex,
        selectedItemColor: const Color(0xFF4093FF),
        onTap: (index) async {
          setState(() => _selectedBottomIndex = index);
          switch (index) {
            case 0: // Subscribers
              break;
            case 1: // Profile
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___,) => ProfileScreen(
                    collectorName: widget.collectorName,
                    collectorTown: widget.collectorTown,
                    initialIndex: 1,
                  ),
                ),
              );
              break;
            case 2: // Map
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___,) => AllClientsMapScreen(
                    clients: _clients,
                    collectorName: widget.collectorName,
                  ),
                ),
              );
              break;
            case 3: // Printer
              await _selectPrinter();
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Subscribers',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: 'Printer'),
        ],
      ),
    );
  }

  // NOTE: Floating mini-FABs were replaced by a BottomNavigationBar for
  // improved usability. If you want to reintroduce mini FABs, re-add them here.
}
