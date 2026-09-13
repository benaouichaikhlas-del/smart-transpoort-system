import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';

class GererCompteScreen extends StatefulWidget {
  const GererCompteScreen({super.key});

  @override
  State<GererCompteScreen> createState() => _GererCompteScreenState();
}

class _GererCompteScreenState extends State<GererCompteScreen> {
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _blue2 = Color(0xFF60A5FA);
  static const Color _card = Color(0xFF131324);
  static const Color _fieldFill = Color(0xFF191931);
  static const Color _fieldBorder = Color(0xFF2E2E52);

  String get _token => context.read<AuthProvider>().user!.token;
  String get _email => context.read<AuthProvider>().user!.email;

  // ══════ MODIFIER (bottom sheet style maquette) ══════
  Future<void> _showModifierDialog() async {
    final emailCtrl = TextEditingController(text: _email);
    final passCtrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    bool obscure = true;
    bool obscure2 = true;
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _fieldBorder, width: 1.2),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Poignée
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 18),
              // Titre + fermeture
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_blue, _blue2],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 21),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Modifier compte',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _sheetField(
                controller: emailCtrl,
                hint: 'Email',
                icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _sheetField(
                controller: passCtrl,
                hint: 'Nouveau mot de passe',
                icon: Icons.lock_outline_rounded,
                obscure: obscure,
                suffix: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                  ),
                  onPressed: () => setS(() => obscure = !obscure),
                ),
              ),
              const SizedBox(height: 12),
              _sheetField(
                controller: pass2Ctrl,
                hint: 'Confirmer mot de passe',
                icon: Icons.lock_outline_rounded,
                obscure: obscure2,
                suffix: IconButton(
                  icon: Icon(
                    obscure2 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                  ),
                  onPressed: () => setS(() => obscure2 = !obscure2),
                ),
              ),
              const SizedBox(height: 26),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_blue, _blue2],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: loading
                            ? null
                            : () async {
                                // 1️⃣ تحقق من تطابق الباسورد
                                if (passCtrl.text.isNotEmpty &&
                                    passCtrl.text != pass2Ctrl.text) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mots de passe différents'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final body = <String, dynamic>{};
                                final newEmail = emailCtrl.text.trim();
                                if (newEmail != _email) {
                                  body['email'] = newEmail;
                                }
                                if (passCtrl.text.isNotEmpty) {
                                  body['mot_de_passe'] = passCtrl.text.trim();
                                }

                                Navigator.pop(ctx);
                                if (body.isEmpty) return;

                                try {
                                  final r = await http.put(
                                    Uri.parse(ApiConstants.compte),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $_token',
                                    },
                                    body: jsonEncode(body),
                                  );

                                  if (!mounted) return;

                                  String message;
                                  bool success = false;
                                  try {
                                    final data = jsonDecode(r.body);
                                    message = data['message']?.toString() ??
                                        'Opération effectuée';
                                    success = r.statusCode == 200;
                                  } catch (e) {
                                    message =
                                        'Erreur serveur (${r.statusCode})';
                                  }

                                  if (success && body['email'] != null) {
                                    await context
                                        .read<AuthProvider>()
                                        .updateUser(email: newEmail);
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(message),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('Erreur de connexion: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ));
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Center(
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Modifier',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ══════ SUPPRIMER (dialog style maquette) ══════
  Future<void> _supprimerCompte() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _fieldBorder, width: 1.2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Poignée
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 20),
            // Icône warning avec glow rouge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 30),
            ),
            const SizedBox(height: 18),
            const Text('Supprimer le compte',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            const Text(
              'Cette action est irréversible.\nToutes vos données seront supprimées.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: Text('Supprimer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      final r = await http.delete(
        Uri.parse(ApiConstants.compte),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (!mounted) return;

      if (r.statusCode == 200) {
        await context.read<AuthProvider>().logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      } else {
        String message;
        try {
          message = jsonDecode(r.body)['message'] ?? 'Erreur';
        } catch (_) {
          message = 'Erreur serveur';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _fieldBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(icon, color: _blue2, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const BackButton(color: Colors.white),
          ),
        ),
        title: const Text('Gérer mon compte',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Icône bâtiment avec glow bleu
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _blue.withOpacity(0.25),
                  _blue.withOpacity(0.05),
                ]),
                border: Border.all(color: _blue.withOpacity(0.2), width: 1.5),
              ),
              child:
                  const Icon(Icons.apartment_rounded, size: 52, color: _blue2),
            ),
            const SizedBox(height: 20),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blue.withOpacity(0.35)),
              ),
              child: const Text(
                'PROPRIÉTAIRE',
                style: TextStyle(
                  color: _blue2,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 36),
            _actionCard(
              icon: Icons.edit_outlined,
              label: 'Modifier compte',
              subtitle: 'Changer email ou mot de passe',
              color: _blue,
              onTap: _showModifierDialog,
            ),
            const SizedBox(height: 14),
            _actionCard(
              icon: Icons.delete_outline_rounded,
              label: 'Supprimer compte',
              subtitle: 'Supprimer définitivement votre compte',
              color: Colors.red,
              onTap: _supprimerCompte,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
