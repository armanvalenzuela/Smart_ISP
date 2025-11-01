import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client_model.dart';
import '../services/paymongo_service.dart';

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
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  String? _checkoutUrl;

  void _createPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    final link = await PaymongoService.createCheckout(amount);
    setState(() {
      _checkoutUrl = link;
      _isLoading = false;
    });

    if (link != null && await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    return Scaffold(
      appBar: AppBar(
        title: Text("Payment for ${client.name}"),
        backgroundColor: const Color(0xFF4093FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Collector: ${widget.collectorName}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              "Client Name: ${client.name}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              "Phone: ${client.phone}",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (PHP)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _createPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text("Pay Now"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4093FF),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
            const SizedBox(height: 10),
            if (_checkoutUrl != null)
              Text(
                "Checkout link generated successfully.",
                style: TextStyle(color: Colors.green[700]),
              ),
          ],
        ),
      ),
    );
  }
}