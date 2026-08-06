import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _premierConnexion = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get premierConnexion => _premierConnexion;

  final AuthService _authService = AuthService();

  // ═══════════════════════════════════════════
  // ✅ INIT
  // ═══════════════════════════════════════════
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
          while (payload.length % 4 != 0) {
            payload += '=';
          }

          final decoded = jsonDecode(
            utf8.decode(base64Url.decode(payload)),
          );

          final id = decoded['id'] is int
              ? decoded['id']
              : int.tryParse(decoded['id'].toString()) ?? 0;

          _user = UserModel(
            id: id,
            email: decoded['email']?.toString() ?? '',
            role: decoded['role']?.toString() ?? 'visiteur',
            token: token,
            nom: decoded['nom']?.toString(),
            prenom: decoded['prenom']?.toString(),
            tel: decoded['tel']?.toString(),
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ Erreur init: $e');
        await prefs.remove('token');
      }
    }
  }

  // ═══════════════════════════════════════════
  // ✅ UPDATE USER
  // ═══════════════════════════════════════════
  Future<void> updateUser({
    String? email,
    String? tel,
    String? token,
  }) async {
    if (_user == null) return;

    _user = _user!.copyWith(
      email: email ?? _user!.email,
      tel: tel ?? _user!.tel,
      token: token ?? _user!.token,
    );

    // ✅ حدّث التخزين المحلي
    if (token != null) {
      await _saveToken(token);
    }

    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ═══════════════════════════════════════════
  // ✅ LOGIN
  // ═══════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _isLoading = false;

      if (result['success']) {
        _user = result['user'];
        _premierConnexion = _user!.premierConnexion;
        await _saveToken(_user!.token);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearPremierConnexion() {
    _premierConnexion = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // ✅ LOGOUT
  // ═══════════════════════════════════════════
  Future<void> logout() async {
    _user = null;
    _premierConnexion = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
