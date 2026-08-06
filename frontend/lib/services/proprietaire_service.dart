import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/demande_model.dart';

class ProprietaireService {
  Future<Map<String, dynamic>> demanderInscription(DemandeModel d) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.demandeProprietaire),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(d.toJson()),
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
