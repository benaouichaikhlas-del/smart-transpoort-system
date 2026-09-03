import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final bool isRegister; // true = création compte, false = login/reset

  const EmailVerificationDialog({
    super.key,
    required this.email,
    this.isRegister = true,
  });

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  bool _codeEnvoye = false;
  String? _erreur;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // ⭐ أرسل الكود تلقائياً كي يفتح الـ Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _envoyerCode());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
      }
      if (mounted) setState(() => _countdown--);
    });
  }

  Future<void> _envoyerCode() async {
    if (_countdown > 0) return;

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final r = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/envoyer-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(r.body);

      if (r.statusCode == 200) {
        setState(() {
          _codeEnvoye = true;
          _erreur = null;
        });
        _startCountdown();
        // ⭐ Auto-focus على حقل الكود
        Future.delayed(const Duration(milliseconds: 300), () {
          _focusNode.requestFocus();
        });
      } else {
        final msg = body['message'] ?? 'Erreur serveur';
        // ⭐ إذا السيرفر يرجع code (mode dev)
        if (body['code'] != null) {
          setState(() => _erreur = 'DEV — Code: ${body['code']}');
        } else {
          setState(() => _erreur = msg);
        }
      }
    } catch (e) {
      setState(() => _erreur =
          'Service email temporairement indisponible.\nVérifiez votre connexion ou réessayez.');
    }

    setState(() => _loading = false);
  }

  Future<void> _verifierCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _erreur = 'Le code doit contenir 6 chiffres');
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final r = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/verifier-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email, 'code': code}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(r.body);

      if (r.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() => _erreur = body['message'] ?? 'Code incorrect');
        HapticFeedback.vibrate();
      }
    } catch (e) {
      setState(() => _erreur = 'Erreur réseau');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF13091F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _codeEnvoye ? 'Vérification' : 'Vérifier votre email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _codeEnvoye
                ? 'Code envoyé à\n${widget.email}'
                : 'Envoi du code en cours...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_codeEnvoye) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0F2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _erreur == null
                      ? AppTheme.primary.withOpacity(0.4)
                      : Colors.red.withOpacity(0.4),
                ),
              ),
              child: TextField(
                controller: _codeCtrl,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.white24,
                    fontSize: 28,
                    letterSpacing: 12,
                  ),
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) => _verifierCode(),
              ),
            ),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _erreur!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_codeEnvoye) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _verifierCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Vérifier',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: (_loading || _countdown > 0) ? null : _envoyerCode,
              child: Text(
                _countdown > 0
                    ? 'Renvoyer dans ${_countdown}s'
                    : 'Renvoyer le code',
                style: TextStyle(
                  color: _countdown > 0 ? Colors.white24 : AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else ...[
          const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ],
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
