// 📄 PART 2: api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:4000/api';

  // 🧩 Get all subscribers
  static Future<List<dynamic>> getSubscribers() async {
    final uri = Uri.parse('$_baseUrl/subscribers');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch subscribers');
    }
  }

  // 🧩 Add or update subscriber
  static Future<bool> addOrUpdateSubscriber({
    required String name,
    required String plan,
    required String town,
    required String serial,
  }) async {
    final uri = Uri.parse('$_baseUrl/subscribers');
    final body = {
      'name': name,
      'plan': plan,
      'town': town,
      'serial': serial,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    final data = json.decode(res.body);
    return data['message'] == 'Subscriber saved';
  }

  // 🧩 Get merged subscriber + device data
  static Future<List<dynamic>> getMergedData() async {
    final uri = Uri.parse('$_baseUrl/merged');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch merged data');
    }
  }

  static Future<bool> addPayment({
  required String serial,
  required int amount,
  required String collector,
}) async {
  final uri = Uri.parse('$_baseUrl/payments');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'serial': serial,
      'amount': amount,
      'collector': collector,
      'date': DateTime.now().toIso8601String(),
    }),
  );

  final data = json.decode(res.body);
  return data['message'] == 'Payment recorded';
}


  // 🔐 Login
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl?action=login&username=$username&password=$password',
    );
    final res = await http.get(uri);
    final data = json.decode(res.body);
    return data['success'] ? data['data'] : null;
  }

  // 📥 Get clients by town
  static Future<List<ClientModel>> getClientsByTown(String town) async {
    final uri = Uri.parse('$_baseUrl?action=getClients&town=$town');
    final res = await http.get(uri);
    final data = json.decode(res.body);

    if (data['success'] == true) {
      List<ClientModel> clients = [];
      for (var item in data['data']) {
        clients.add(ClientModel.fromJson(item));
      }
      return clients;
    } else {
      throw Exception(data['message']);
    }
  }

  // 🔍 Get client by WiFi ID
  static Future<ClientModel?> getClientInfo(String wifiId) async {
    final uri = Uri.parse('$_baseUrl?action=getClientInfo&wifi_id=$wifiId');
    final res = await http.get(uri);
    final data = json.decode(res.body);

    if (data['success']) {
      return ClientModel.fromJson(data['data']);
    } else {
      return null;
    }
  }

  /*
  // 💸 Pay for a client using WiFi_ID
  static Future<bool> payClient({
    required String wifiId,
    required String year,
    required String month,
    required String collectorName,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?action=payClient'
      '&wifi_id=$wifiId'
      '&year=$year'
      '&month=$month'
      '&collector=${Uri.encodeComponent(collectorName)}',
    );

    final res = await http.get(uri);
    final data = json.decode(res.body);
    return data['success'];
  }
*/

  static Future<bool> payClient({
    required String wifiId,
    required String year,
    required String month,
    required String collectorName,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?action=payClient'
      '&wifi_id=$wifiId'
      '&year=$year'
      '&month=$month'
      '&collector=${Uri.encodeComponent(collectorName)}',
    );

    //print("🌐 Sending payment request: $uri");

    final res = await http.get(uri);
    final data = json.decode(res.body);

    //print("📥 Response: $data");

    return data['success'];
  }

  // ✏️ Update client details (name/note/location)
  static Future<bool> updateClient({
    required String wifiId,
    String? name,
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    final params = {
      'action': 'updateClient',
      'wifi_id': wifiId,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    final res = await http.get(uri);
    final data = json.decode(res.body);
    return data['success'];
  }

  /// 📝 Updates client note and GPS coordinates.
  /// Only `note`, `latitude`, and `longitude` are editable.
  /// Required: [wifiId], [note]
  static Future<Map<String, dynamic>> updateClientNote({
    required String wifiId,
    required String note,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);

      final Map<String, String> body = {
        'action': 'updateClient',
        'wifi_id': wifiId.trim(),
        'note': note.trim(),
        'latitude': latitude?.toStringAsFixed(6) ?? '',
        'longitude': longitude?.toStringAsFixed(6) ?? '',
        'role': 'client',
      };

      print('updateClient request body: $body'); // Debug print

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('updateClient response status: ${response.statusCode}');
      print('updateClient response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception occurred: $e'};
    }
  }
}
