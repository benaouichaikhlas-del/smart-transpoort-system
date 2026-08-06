import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class ConducteurService {
  // ===================== GET =====================
  Future<List<dynamic>> getConducteurs(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.conducteurs),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===================== ADD =====================
  Future<Map<String, dynamic>> ajouterConducteur({
    required String token,
    required String nom,
    required String prenom,
    required int age, // ← زدنا
    required String tel,
    required String numPermis,
    required String adresse,
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.conducteurs),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'nom': nom,
              'prenom': prenom,
              'age': age, // ← زدنا
              'telephone': tel,
              'num_permis': numPermis,
              'adresse': adresse,
              'email': email,
              'mot_de_passe': motDePasse,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'OK',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ===================== UPDATE =====================
  Future<Map<String, dynamic>> modifierConducteur({
    required String token,
    required int id,
    required String nom,
    required String prenom,
    int? age, // ← زدنا (اختياري في التعديل)
    required String tel,
    required String numPermis,
    required String adresse,
    required String email,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.conducteurs}/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'nom': nom,
              'prenom': prenom,
              if (age != null) 'age': age, // ← نرسلو بس إذا موجود
              'telephone': tel,
              'num_permis': numPermis,
              'adresse': adresse,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'OK',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ===================== DELETE =====================
  Future<Map<String, dynamic>> supprimerConducteur(String token, int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.conducteurs}/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'OK',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }
}
