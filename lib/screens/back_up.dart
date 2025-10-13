// 📄 client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../services/api_service.dart';
import 'map_screen.dart';
import 'payment_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;
  final String collectorName;

  const ClientDetailScreen({
    super.key,
    required this.client,
    required this.collectorName,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late ClientModel client;
  bool _loading = true;

  String get currentMonthKey {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    client = widget.client;
    _fetchClientFromDatabase();
  }

  Future<void> _fetchClientFromDatabase() async {
    setState(() => _loading = true);
    try {
      final updated = await ApiService.getClientInfo(widget.client.wifiId);
      if (updated != null) {
        setState(() => client = updated);
      } else {
        //ScaffoldMessenger.of(context).showSnackBar(
        //  const SnackBar(content: Text('❌ Failed to load client from database.')),
        //);
      }
    } catch (e) {
      debugPrint('Initial client load error: $e');
      //ScaffoldMessenger.of(context).showSnackBar(
      //  SnackBar(content: Text('Error: ${e.toString()}')),
      //);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshClient() async {
    await _fetchClientFromDatabase();
  }

  Future<void> _printReceipt() async {
    final printer = BlueThermalPrinter.instance;

    try {
      final devices = await printer.getBondedDevices();
      if (devices.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Printer Error'),
            content: Text('No paired Bluetooth printers found.'),
          ),
        );
        return;
      }

      final selectedDevice = await showDialog<BluetoothDevice>(
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

      bool? isConnected = await printer.isConnected;
      if (isConnected == true) {
        await printer.disconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      await printer.connect(selectedDevice);
      await Future.delayed(const Duration(seconds: 2));

      final amountPaid = client.payments['AmountPaid_$currentMonthKey'];
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
      printer.printQRcode(widget.client.wifiId, 250, 250, 1);
      printer.printNewLine();
      printer.printNewLine();
      printer.paperCut();

      await Future.delayed(const Duration(seconds: 1));
      await printer.disconnect();
    } catch (e) {
      debugPrint('Print error: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Print Error'),
          content: Text('Failed to print: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = client.monthlyStatus['Status_$currentMonthKey'] ?? 'Unpaid';
    final amountPaid = client.payments['AmountPaid_$currentMonthKey'];
    final hasPaid = status == 'Paid';

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
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📱 ${client.phone}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('🚀 Plan: ${client.planSpeed} – ₱${client.planAmount}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    //Text('🎁 Promo: ₱${client.promoDiscount} (${client.promoRemarks})'),
                    //const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('💳 Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      Text('💸 Paid: ₱$amountPaid'),
                    const SizedBox(height: 10),
                    //Text('🌐 Connection: ${client.connectionStatus}'),
                    //const SizedBox(height: 10),
                    const Text('📝 Remarks:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(client.note),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Pay Now'),
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
            const SizedBox(height: 10),
            /*ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Print Receipt'),
              onPressed: hasPaid ? _printReceipt : null,
            ),*/
          ],
        ),
      ),
    );
  }
}
