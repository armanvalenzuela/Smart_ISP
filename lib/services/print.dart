import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

Future<void> printReceipt({
  required BuildContext context,
  required dynamic client,
  required double amountPaid,
  required String collectorName,
}) async {
  final printer = BlueThermalPrinter.instance;
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

  final device = devices.first;
  await printer.connect(device);

  printer.printNewLine();
  printer.printCustom("Billing", 3, 1); // header
  printer.printNewLine(); //spacing

  printer.printCustom("Client: ${client.name}", 1, 0); // left align text
  // printer.printCustom("Address: ${client.home}", 1, 0); // Optional
  printer.printCustom("Plan: ${client.planSpeed}", 1, 0); // left align text
  printer.printCustom("Discount: ${client.promoDiscount}", 1, 0); // left align text
  printer.printCustom("Amount: ₱$amountPaid", 1, 0); // left align text
  printer.printCustom("Date: ${DateTime.now().toLocal()}", 1, 0); // left align text
  printer.printCustom("Collector: $collectorName", 1, 0); // left align text
  printer.printNewLine(); // spacing

  printer.printCustom("Scan this:", 1, 1); // left align text
  printer.printQRcode(client.wifiId, 250, 250, 1); // QR code generate 250px size, align center
  printer.printNewLine(); // spacing
  printer.paperCut(); // disconnect sa printer alternative code for disconnecting  to printer "await _printer.disconnect();""
}
