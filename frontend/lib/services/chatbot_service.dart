import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class ChatbotService {
  final String token;

  ChatbotService({required this.token});

  /// Envoie un message au chatbot et retourne la réponse
  Future<String> envoyerMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.passager}/chatbot'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ⬇️ الـ Backend يرجّع { "reponse": "..." }
        final reponse = data['reponse'] as String?;
        if (reponse != null && reponse.isNotEmpty) {
          return reponse;
        }
        return 'Réponse vide du serveur.';
      } else if (response.statusCode == 404) {
        return 'Service chatbot indisponible (404).';
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      return 'Erreur de connexion : $e';
    }
  }
}
