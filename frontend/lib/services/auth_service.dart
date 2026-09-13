import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse(ApiConstants.login);

      print('🔵 LOGIN URL: $url');
      print('🔵 EMAIL: $email');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'mot_de_passe': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('🟢 STATUS CODE: ${response.statusCode}');
      print('🟢 RESPONSE BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': UserModel.fromJson(
              data), // ✅ بعث الـ response كاملة، ماشي data['user'] فقط
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur de connexion',
      };
    } catch (e) {
      print('🔴 LOGIN ERROR: $e');

      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }
}
