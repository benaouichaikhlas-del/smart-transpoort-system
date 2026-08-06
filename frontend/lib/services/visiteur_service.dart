import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class VisiteurService {
  Future<Map<String, dynamic>> sInscrire({
    required String nom,
    required String email,
    required String tel,
    required String motDePasse,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.inscrireVisiteur),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nom': nom,
              'email': email,
              'tel': tel,
              'adresse': '',
              'mot_de_passe': motDePasse,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }
}
