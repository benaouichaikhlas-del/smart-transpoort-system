import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _premierConnexion = false;

  final _secureStorage = const FlutterSecureStorage();

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
    final token = await _secureStorage.read(key: 'token');

    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
          while (payload.length % 4 != 0) payload += '=';

          final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));

          final id = decoded['id'] is int
              ? decoded['id']
              : int.tryParse(decoded['id'].toString()) ?? 0;

          // 1️⃣ بنّد User من الـ JWT
          _user = UserModel(
            id: id,
            email: decoded['email']?.toString() ?? '',
            role: decoded['role']?.toString() ?? 'visiteur',
            token: token,
            nom: decoded['nom']?.toString(),
            prenom: decoded['prenom']?.toString(),
            tel: decoded['tel']?.toString(),
          );

          // ⭐ حدّث من المخزن إذا كان نفس المستخدم
          final storedUserId = await _secureStorage.read(key: 'user_id');
          final storedEmail = await _secureStorage.read(key: 'user_email');
          final storedTel = await _secureStorage.read(key: 'user_tel');

          if (storedUserId == _user!.id.toString()) {
            if (storedEmail != null) {
              _user = _user!.copyWith(email: storedEmail);
            }
            if (storedTel != null) {
              _user = _user!.copyWith(tel: storedTel);
            }
          }

          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ Erreur init: $e');
        await _secureStorage.delete(key: 'token');
        await _secureStorage.delete(key: 'user_id');
        await _secureStorage.delete(key: 'user_email');
        await _secureStorage.delete(key: 'user_tel');
      }
    }
  }

  // ═══════════════════════════════════════════
  // ✅ UPDATE USER (من Dialog Gérer Compte)
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

    if (token != null) await _saveToken(token);

    // ⭐ خزّن مع user_id باش نعرفو المالك
    await _secureStorage.write(key: 'user_id', value: _user!.id.toString());
    if (email != null)
      await _secureStorage.write(key: 'user_email', value: email);
    if (tel != null) await _secureStorage.write(key: 'user_tel', value: tel);

    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    await _secureStorage.write(key: 'token', value: token);
  }

  // ═══════════════════════════════════════════
  // ✅ LOGIN — حدّث من المخزن إذا نفس المستخدم
  // ═══════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _isLoading = false;

      if (result['success']) {
        // ⭐ جبد المخزن **قبل** ما تكتب الجديد
        final storedUserId = await _secureStorage.read(key: 'user_id');
        final storedEmail = await _secureStorage.read(key: 'user_email');
        final storedTel = await _secureStorage.read(key: 'user_tel');

        _user = result['user'];
        _premierConnexion = _user!.premierConnexion;
        await _saveToken(_user!.token);

        // ⭐ إذا نفس المستخدم → استخدم الأرقام/الإيميل المخزنة (أحدث)
        if (storedUserId == _user!.id.toString()) {
          if (storedEmail != null) {
            _user = _user!.copyWith(email: storedEmail);
          }
          if (storedTel != null) {
            _user = _user!.copyWith(tel: storedTel);
          }
        }

        // ⭐ اكتب/حدّث المخزن بالقيم النهائية
        await _secureStorage.write(key: 'user_id', value: _user!.id.toString());
        await _secureStorage.write(key: 'user_email', value: _user!.email);
        if (_user!.tel != null) {
          await _secureStorage.write(key: 'user_tel', value: _user!.tel);
        }

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
  // ✅ LOGOUT — امحي token فقط، خلي user_id/email/tel
  // ═══════════════════════════════════════════
  Future<void> logout() async {
    _user = null;
    _premierConnexion = false;

    // ⭐ امحي token فقط (الأمان)
    await _secureStorage.delete(key: 'token');

    // ⭐ ما تمحيش user_id / user_email / user_tel
    // باش كي يعاود يدخل بنفس الحساب يجبد التحديث الأخير
    // await _secureStorage.delete(key: 'user_id');
    // await _secureStorage.delete(key: 'user_email');
    // await _secureStorage.delete(key: 'user_tel');

    notifyListeners();
  }
}
