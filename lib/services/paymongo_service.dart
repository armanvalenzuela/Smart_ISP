import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymongoService {
  static final String _apiKey = dotenv.env['PAYMONGO_API_KEY'] ?? '';
  static const String _baseUrl = "https://api.paymongo.com/v1/checkout_sessions";

  static Future<String?> createCheckout(double amount) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Basic ${base64Encode(utf8.encode("$_apiKey:"))}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "data": {
            "attributes": {
              "cancel_url": "https://smartisp.example/cancel",
              "success_url": "https://smartisp.example/success",
              "billing": {"name": "Smart ISP Subscriber"},
              "description": "Internet bill payment",
              "line_items": [
                {
                  "name": "Smart ISP Bill",
                  "amount": (amount * 100).toInt(),
                  "currency": "PHP",
                  "quantity": 1
                }
              ],
              "payment_method_types": ["gcash", "paymaya", "card"]
            }
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["data"]["attributes"]["checkout_url"];
      } else {
        print(response.body);
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}
