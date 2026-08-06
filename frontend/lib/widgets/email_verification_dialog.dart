import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;

  const EmailVerificationDialog({super.key, required this.email});

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _codeEnvoye = false;
  String? _erreur;

  Future<void> _envoyerCode() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/envoyer-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (r.statusCode == 200) {
        setState(() => _codeEnvoye = true);
      } else {
        final body = jsonDecode(r.body);
        setState(() => _erreur = body['message'] ?? "Erreur lors de l'envoi");
      }
    } catch (e) {
      setState(() => _erreur = 'Erreur réseau');
    }

    setState(() => _loading = false);
  }

  Future<void> _verifierCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _erreur = 'Le code doit contenir 6 chiffres');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verifier-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': code}),
      );

      if (r.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final body = jsonDecode(r.body);
        setState(() => _erreur = body['message'] ?? 'Code incorrect');
      }
    } catch (e) {
      setState(() => _erreur = 'Erreur réseau');
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            _codeEnvoye ? 'Code de vérification' : 'Vérifier votre email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _codeEnvoye
                ? 'Entrez le code envoyé à\n${widget.email}'
                : 'Un code sera envoyé à\n${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_codeEnvoye) ...[
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(color: Colors.white38),
                counterText: '',
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(
              _erreur!,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : (_codeEnvoye ? _verifierCode : _envoyerCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  : Text(
                      _codeEnvoye ? 'Vérifier' : 'Envoyer le code',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
            ),
          ),
        ),
        if (_codeEnvoye)
          TextButton(
            onPressed: _loading ? null : _envoyerCode,
            child: const Text(
              'Renvoyer le code',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
