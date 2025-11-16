// 📄 client_detail_screen.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_model.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import 'map_screen.dart';
import 'payment_screen.dart';
import 'customer_support_screen.dart'; // ✅ Added import

class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;
  final String collectorName;
  final UserRole userRole;

  const ClientDetailScreen({
    super.key,
    required this.client,
    required this.collectorName,
    required this.userRole,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late ClientModel client;
  final TextEditingController _noteController = TextEditingController();
  bool _savingNote = false;
  bool _refreshing = false;

  String get currentMonthKey {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    client = widget.client;
    _noteController.text = client.note ?? '';
  }

  Future<void> _refreshClient() async {
    setState(() => _refreshing = true);
    try {
      final updated = await ApiService.getClientInfo(client.wifiId);
      if (updated != null) {
        setState(() {
          client = updated;
          _noteController.text = client.note ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error refreshing client: $e');
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _saveRemarks() async {
    setState(() => _savingNote = true);
    try {
      await ApiService.updateClient(
        wifiId: client.wifiId,
        note: _noteController.text.trim(),
        latitude: client.latitude,
        longitude: client.longitude,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Remarks updated!')));
      await _refreshClient();
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      setState(() => _savingNote = false);
    }
  }

  Future<void> _printReceipt() async {
    final printer = BlueThermalPrinter.instance;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString('printerAddress');
      final devices = await printer.getBondedDevices();

      if (devices.isEmpty) {
        _showDialog('Printer Error', 'No paired Bluetooth printers found.');
        return;
      }

      BluetoothDevice? selectedDevice;

      if (savedAddress != null) {
        selectedDevice = devices.firstWhere(
          (d) => d.address == savedAddress,
          orElse: () => devices.first,
        );
      } else {
        selectedDevice = await showDialog<BluetoothDevice>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select a printer'),
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

        if (selectedDevice == null) return;

        await prefs.setString('printerAddress', selectedDevice.address ?? '');
        await prefs.setString('printerName', selectedDevice.name ?? '');
      }

      if (await printer.isConnected ?? false) {
        await printer.disconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      await printer.connect(selectedDevice);
      await Future.delayed(const Duration(seconds: 2));

      final status =
          client.monthlyStatus['Status_$currentMonthKey'] ?? 'Unpaid';
      final isPaid = status.toLowerCase() == 'paid';
      final amountPaid = isPaid
          ? client.payments['AmountPaid_$currentMonthKey'] ?? '-'
          : '-';
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      printer.printNewLine();
      printer.printCustom("JD Billing", 3, 1);
      printer.printNewLine();
      printer.printCustom("Client: ${client.name}", 1, 0);
      printer.printCustom("Plan: ${client.planSpeed}", 1, 0);
      printer.printCustom("Discount: ${client.promoDiscount}", 1, 0);
      printer.printCustom("Amount: $amountPaid", 1, 0);
      printer.printCustom("Date: $dateStr", 1, 0);
      printer.printCustom("Collector: ${widget.collectorName}", 1, 0);
      printer.printNewLine();
      printer.printCustom("Scan this:", 1, 1);
      printer.printQRcode(client.wifiId, 250, 250, 1);
      printer.printNewLine();
      printer.paperCut();

      await Future.delayed(const Duration(seconds: 1));
      await printer.disconnect();
    } catch (e) {
      debugPrint('Print error: $e');
      _showDialog('Print Error', 'Failed to print: $e');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = client.monthlyStatus['Status_$currentMonthKey'] ?? 'Unpaid';
    final amountPaid = client.payments['AmountPaid_$currentMonthKey'];
    final hasPaid = status.toLowerCase() == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Client',
            onPressed: _refreshClient,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_refreshing) const LinearProgressIndicator(),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          client.phone,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.speed,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Plan: ${client.planSpeed} – ₱${client.planAmount}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Status: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            color: hasPaid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (hasPaid && amountPaid != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.payments,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Paid: ₱$amountPaid',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MapScreen(client: client)),
                );
              },
            ),
            const SizedBox(height: 10),
            // Payment Processing - Only for roles that can process payments
            if (widget.userRole.canProcessPayments())
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Payment Processing'),
                onPressed: hasPaid
                    ? null
                    : () {
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
            if (widget.userRole.canProcessPayments()) const SizedBox(height: 10),
            // Print Receipt - Only for roles that can process payments
            if (widget.userRole.canProcessPayments())
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Print Receipt'),
                onPressed: _printReceipt,
              ),
            if (widget.userRole.canProcessPayments()) const SizedBox(height: 10),
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.support_agent),
              label: const Text('Customer Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerSupportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
