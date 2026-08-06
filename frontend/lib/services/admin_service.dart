import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class AdminService {
  // ═══ DEMANDES ═══
  Future<List<dynamic>> getDemandes(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminDemandes),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> accepter(String token, int id) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.adminDemandes}/$id/accepter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message']
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> refuser(String token, int id) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.adminDemandes}/$id/refuser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message']
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> changerStatut(
      String token, int id, String statut) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.adminDemandes}/$id/statut'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'statut': statut}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message']
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ✅ هادي اللي ناقصة!
  Future<Map<String, dynamic>> supprimer(String token, int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/admin/demandes/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau'};
    }
  }

  // ═══ FEEDBACKS ═══
  Future<List<dynamic>> getFeedbacks(String token) async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.admin}/feedbacks'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) {
      return [];
    }
  }

  // ═══ SIGNALEMENTS ═══
  Future<List<dynamic>> getSignalements(String token) async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.admin}/signalements'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) {
      return [];
    }
  }

  // ═══ EVALUATIONS ═══
  Future<List<dynamic>> getEvaluations(String token) async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.admin}/evaluations'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) {
      return [];
    }
  }

  // ═══ UPDATE STATUT SIGNALEMENT ═══
  Future<void> updateStatutSignalement(
      String token, int id, String statut) async {
    try {
      await http
          .put(
            Uri.parse('${ApiConstants.admin}/signalements/$id/statut'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'statut': statut}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
