import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Use localhost if testing on PC — or 10.0.2.2 if on Android emulator
  static const String _ollamaUrl = "http://localhost:11434/api/generate";
  static const String _model = "tinyllama:latest";

  static Future<String> getResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": _model,
          "prompt":
              "You are Smart ISP’s friendly customer service assistant. Help subscribers with billing, payments, and internet connection issues. Respond clearly and politely.\n\nUser: $userMessage\nAssistant:",
          "stream": false
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"]?.trim() ??
            "I’m not sure I understood that. Could you repeat?";
      } else {
        return "Ollama returned error code ${response.statusCode}.";
      }
    } catch (e) {
      return "⚠️ Could not connect to local AI. Make sure Ollama is running.";
    }
  }
}
