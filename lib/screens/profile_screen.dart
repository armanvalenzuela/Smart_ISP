// 📄 profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'all_clients_map_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String collectorName;
  final String collectorTown;

  const ProfileScreen({
    super.key,
    required this.collectorName,
    required this.collectorTown,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedPrinterName;
  String? _selectedPrinterAddress;
  int _collectedThisMonth = 0;
  bool _isLoading = true; // ✅ added loading flag

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _showLogoutDialog(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log Out?', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 10,
              endIndent: 10,
              ),
          ],
        ),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF4093FF), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) await _logout();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterName = prefs.getString('printerName');
      _selectedPrinterAddress = prefs.getString('printerAddress');
    });

    final clients = await ApiService.getClientsByTown(widget.collectorTown);
    int count = 0;
    for (final client in clients) {
      if (client.statusThisMonth == 'Paid' &&
          client.collectorThisMonth == widget.collectorName) {
        count++;
      }
    }

    setState(() {
      _collectedThisMonth = count;
      _isLoading = false; // ✅ finished loading
    });
  }

  Future<void> _selectPrinter() async {
    final printer = BlueThermalPrinter.instance;
    final devices = await printer.getBondedDevices();

    if (devices.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No Printers'),
                        const SizedBox(height: 8),
                        const Divider(thickness: 1),
                      ],
                    ),
          content: Text('No paired Bluetooth printers found.'),
        ),
      );
      return;
    }

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
              final d = devices[index];
              return ListTile(
                title: Text(d.name ?? 'Unknown'),
                subtitle: Text(d.address ?? ''),
                onTap: () => Navigator.pop(context, d),
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

      setState(() {
        _selectedPrinterName = selected.name;
        _selectedPrinterAddress = selected.address;
      });

      try {
        await printer.connect(selected);
        await Future.delayed(const Duration(milliseconds: 500));
        printer.printNewLine();
        printer.printCustom('✅ Printer connected!', 1, 1);
        printer.printNewLine();
        printer.paperCut();
        printer.disconnect();
      } catch (_) {}
    }
  }

  Future<void> _testPrint() async {
    final prefs = await SharedPreferences.getInstance();
    final addr = prefs.getString('printerAddress');
    if (addr == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No printer selected.')));
      return;
    }

    final printer = BlueThermalPrinter.instance;
    final devices = await printer.getBondedDevices();
    final selected = devices.firstWhere(
      (d) => d.address == addr,
      orElse: () => devices.first,
    );

    try {
      await printer.connect(selected);
      await Future.delayed(const Duration(milliseconds: 300));
      printer.printNewLine();
      printer.printCustom('🧾 Test Print from Profile', 1, 1);
      printer.printCustom('Printer: ${selected.name}', 0, 0);
      printer.printNewLine();
      printer.paperCut();
      printer.disconnect();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test print failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  

  @override
  Widget build(BuildContext context) {
  // theme brightness not required here after UI updates

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4093FF),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.collectorName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_city, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Assigned Town: ${widget.collectorTown}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Default Printer'),
                subtitle:
                    (_selectedPrinterName != null &&
                        _selectedPrinterAddress != null)
                    ? Text('$_selectedPrinterName\n$_selectedPrinterAddress')
                    : const Text('No printer selected'),
                trailing: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _selectPrinter,
                ),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: (_selectedPrinterAddress == null) ? null : _testPrint,
              icon: const Icon(Icons.print),
              label: const Text('Test Print'),
            ),
            const SizedBox(height: 20),
            // ✅ Loading or show result
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(
                        'Clients Collected This Month: $_collectedThisMonth',
                      ),
                      subtitle: const Text('Based on Paid status this month'),
                    ),
                  ),

            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(height: 8),
            const Text(
              'Collector App v1.0.0 by SMART Solutions',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Powered by Flutter & Google Sheets',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      // Bottom navigation bar so the Profile tab appears highlighted while on this screen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: const Color(0xFF4093FF),
        onTap: (index) async {
          switch (index) {
            case 0: // Subscribers
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    collectorName: widget.collectorName,
                    collectorTown: widget.collectorTown,
                  ),
                ),
              );
              break;
            case 1: // Profile (current)
              // nothing
              break;
            case 2: // Map
              final clients = await ApiService.getClientsByTown(widget.collectorTown);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AllClientsMapScreen(
                    clients: clients,
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
}
