import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_model.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final ClientModel client;
  final String collectorName;

  const PaymentScreen({
    super.key,
    required this.client,
    required this.collectorName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late ClientModel client;
  bool _processing = false;
  bool _hasPaid = false;
  String _message = '';
  BluetoothDevice? _selectedPrinter;
  List<String> _unpaidKeys = [];
  String? _selectedMonthKey;
  bool _loading = true;
  String _paymentType = 'Cash';
  bool _savingRemarks = false;

  final TextEditingController _customRemarksController =
      TextEditingController();
  bool _showCustomInput = false;

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    client = widget.client;
    _loading = false;
    _determineUnpaidMonths();
  }

  @override
  void dispose() {
    _customRemarksController.dispose();
    super.dispose();
  }

  Future<void> _refreshClient() async {
    setState(() => _loading = true);
    try {
      final updated = await ApiService.getClientInfo(widget.client.wifiId);
      if (updated != null) {
        client = updated;
        _determineUnpaidMonths();
      }
    } catch (e) {
      debugPrint('Client refresh error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _determineUnpaidMonths() {
    final unpaid =
        client.monthlyStatus.entries
            .where(
              (entry) =>
                  entry.key.startsWith('Status_') &&
                  (entry.value == null ||
                      entry.value.toString().trim().toLowerCase() != 'paid'),
            )
            .map((entry) => entry.key)
            .toList()
          ..sort();

    setState(() {
      _unpaidKeys = unpaid;
      if (unpaid.length == 1) {
        _selectedMonthKey = unpaid.first;
      }
      _hasPaid = unpaid.isEmpty;
    });
  }

  Future<void> _updateRemarksOnly() async {
    if (_paymentType == 'Custom' &&
        _customRemarksController.text.trim().isEmpty) {
      setState(() => _message = 'Please enter custom remarks.');
      return;
    }

    setState(() {
      _processing = true;
      _message = '';
    });

    try {
      await ApiService.updateClient(
        wifiId: client.wifiId,
        note: _paymentType == 'Custom'
            ? _customRemarksController.text.trim()
            : _paymentType,
        latitude: client.latitude,
        longitude: client.longitude,
      );

      setState(() => _message = ' Remarks updated successfully!');
    } catch (e) {
      debugPrint('Failed to update remarks: $e');
      setState(() => _message = ' Failed to update remarks.');
    }

    setState(() => _processing = false);
  }

  Future<void> _submitPayment() async {
    if (_unpaidKeys.length > 1 && _selectedMonthKey == null) {
      setState(() => _message = ' Please select a month to pay.');
      return;
    }

    if (_paymentType == 'Custom' &&
        _customRemarksController.text.trim().isEmpty) {
      setState(() => _message = ' Please enter custom remarks.');
      return;
    }

    setState(() {
      _processing = true;
      _message = '';
    });

    final payKey = _selectedMonthKey ?? _unpaidKeys.first;
    final parts = payKey.split('_');
    final year = parts[1];
    final month = parts[2];

    final success = await ApiService.payClient(
      wifiId: client.wifiId,
      year: year,
      month: month,
      collectorName: widget.collectorName,
    );

    if (success) {
      setState(() => _savingRemarks = true);
      try {
        await ApiService.updateClient(
          wifiId: client.wifiId,
          note: _paymentType == 'Custom'
              ? _customRemarksController.text.trim()
              : _paymentType,
          latitude: client.latitude,
          longitude: client.longitude,
        );
      } catch (e) {
        debugPrint('Failed to save payment type as remarks: $e');
      } finally {
        setState(() => _savingRemarks = false);
      }

      await _refreshClient();
      setState(() {
        _message = '✅ Payment successful for $year-$month!';
        _hasPaid = true;
      });
    } else {
      setState(() => _message = 'Payment failed!.');
    }

    setState(() => _processing = false);
  }

  Future<void> _printReceipt() async {
    try {
      if (_selectedPrinter == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedAddress = prefs.getString('printerAddress');

        final devices = await _printer.getBondedDevices();
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

        if (savedAddress != null) {
          _selectedPrinter = devices.firstWhere(
            (device) => device.address == savedAddress,
            orElse: () => devices.first,
          );
        } else {
          _selectedPrinter = await showDialog<BluetoothDevice>(
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

          if (_selectedPrinter == null) return;

          await prefs.setString(
            'printerAddress',
            _selectedPrinter!.address ?? '',
          );
          await prefs.setString('printerName', _selectedPrinter!.name ?? '');
        }
      }

      await _printer.connect(_selectedPrinter!);
      await Future.delayed(const Duration(seconds: 2));

      final f = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);

      final payKey = _selectedMonthKey ?? _unpaidKeys.first;
      final parts = payKey.split('_');
      final year = parts[1];
      final month = parts[2];
      final paidMonthLabel =
          '${DateFormat.MMMM().format(DateTime(int.parse(year), int.parse(month)))} $year';

      final remarks = _paymentType == 'Custom'
          ? _customRemarksController.text.trim()
          : _paymentType;

      // Subscriber Copy
      _printer.printNewLine();
      _printer.printCustom("JD Solutions", 3, 1);
      _printer.printCustom("Telecommunication Services", 1, 1);
      _printer.printCustom("0977 7777 105", 1, 1);
      _printer.printCustom("Subscribers Copy", 1, 1);
      _printer.printNewLine();
      _printer.printCustom("Subscriber: ${client.name}", 1, 0);
      _printer.printCustom("Plan: ${client.planSpeed}", 1, 0);
      _printer.printCustom("Month Paid: $paidMonthLabel", 1, 0);
      _printer.printCustom("Amount: ${f.format(client.planAmount)}", 1, 0);
      _printer.printCustom("Date: $dateStr", 1, 0);
      _printer.printCustom("Collector: ${widget.collectorName}", 1, 0);
      _printer.printCustom("Payment Type: $remarks", 1, 0);
      _printer.printNewLine();
      _printer.printCustom("Scan This!", 1, 1);
      _printer.printQRcode(client.wifiId, 250, 250, 1);
      _printer.printNewLine();
      _printer.printCustom("=================", 1, 1);
      _printer.printNewLine();

      // Collector Copy
      _printer.printCustom("JD Solutions", 3, 1);
      _printer.printCustom("Telecommunication Services", 1, 1);
      _printer.printCustom("Collectors Copy", 1, 1);
      _printer.printNewLine();
      _printer.printCustom("Subscriber: ${client.name}", 1, 0);
      _printer.printCustom("Plan: ${client.planSpeed}", 1, 0);
      _printer.printCustom("Month Paid: $paidMonthLabel", 1, 0);
      _printer.printCustom("Amount: ${f.format(client.planAmount)}", 1, 0);
      _printer.printCustom("Date: $dateStr", 1, 0);
      _printer.printCustom("Payment Type: $remarks", 1, 0);
      _printer.printNewLine();

      _printer.paperCut();
      await Future.delayed(const Duration(seconds: 1));
      await _printer.disconnect();
    } catch (e) {
      debugPrint('Print error: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Print Error'),
          content: Text('Failed to print: $e'),
        ),
      );
      try {
        await _printer.disconnect();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final plan = f.format(client.planAmount);

    void _showGcashQRCode(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gcash QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/gcash_qr.png', // Put your GCash QR here
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              const Text('Scan this QR code to pay via Gcash'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Payment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                client.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android,
                                size: 18,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                              Text('Phone: ${client.phone}'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                size: 18,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                              Text('Plan Amount: $plan'),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Month dropdown (if multiple unpaid months)
                  if (_unpaidKeys.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedMonthKey,
                      decoration: const InputDecoration(
                        labelText: 'Select month to pay',
                        border: OutlineInputBorder(),
                      ),
                      items: _unpaidKeys.map((key) {
                        final parts = key.split('_');
                        final year = parts[1];
                        final month = parts[2];
                        final label =
                            '${DateFormat.MMMM().format(DateTime(int.parse(year), int.parse(month)))} $year';
                        return DropdownMenuItem(value: key, child: Text(label));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedMonthKey = value),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Payment type dropdown
                  DropdownButtonFormField<String>(
                    value: _paymentType,
                    decoration: const InputDecoration(
                      labelText: 'Payment Type (Remarks)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Gcash', child: Text('Gcash')),
                      DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentType = value;
                          _showCustomInput = value == 'Custom';
                        });
                      }
                    },
                  ),

                  // Custom remarks input
                  if (_showCustomInput) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customRemarksController,
                      decoration: const InputDecoration(
                        labelText: 'Enter custom remarks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  // ✅ Gcash QR Code Button
                  if (_paymentType == "Gcash") ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code),
                      label: const Text('QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: () => _showGcashQRCode(context),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit payment button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: _processing
                        ? const Text('Processing...')
                        : const Text('Submit Payment'),
                    onPressed: _processing || _savingRemarks
                        ? null
                        : _submitPayment,
                  ),

                  // Message display
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _message,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _message.contains('success')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],

                  // Update Remarks button
                  if (_paymentType == "Custom") ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Update Remarks Only'),
                      onPressed: _processing || _savingRemarks
                          ? null
                          : _updateRemarksOnly,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Print receipt
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print Receipt'),
                    onPressed: _printReceipt,
                  ),
                ],
              ),
            ),
    );
  }
}
