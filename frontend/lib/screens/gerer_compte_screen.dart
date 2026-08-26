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
  String get _token => context.read<AuthProvider>().user!.token;
  String get _email => context.read<AuthProvider>().user!.email;

  // ══════ MODIFIER ══════
  Future<void> _showModifierDialog() async {
    final emailCtrl = TextEditingController(text: _email);
    final passCtrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Modifier compte',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                emailCtrl,
                'Email',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nouveau mot de passe (optionnel)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white38,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38,
                    ),
                    onPressed: () => setS(() => obscure = !obscure),
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pass2Ctrl,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Confirmer mot de passe',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white38,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
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

                // 2️⃣ نحضرو الـ body
                final body = <String, dynamic>{};
                final newEmail = emailCtrl.text.trim();
                if (newEmail != _email) {
                  body['email'] = newEmail;
                }
                if (passCtrl.text.isNotEmpty) {
                  body['mot_de_passe'] = passCtrl.text.trim();
                }

                // 3️⃣ نسدو الـ Dialog
                Navigator.pop(ctx);

                // إذا مافي والو تبدل، مانديرو والو
                if (body.isEmpty) return;

                // 4️⃣ نبعثو الطلب
                try {
                  debugPrint('📤 Sending PUT to: ${ApiConstants.compte}');
                  debugPrint('📤 Body: $body');

                  final r = await http.put(
                    Uri.parse(ApiConstants.compte),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $_token',
                    },
                    body: jsonEncode(body),
                  );

                  debugPrint('📡 Status: ${r.statusCode}');
                  debugPrint('📡 Body: ${r.body}');

                  if (!mounted) return;

                  // ⭐ نجبدو الرسالة بأمان (try/catch حول jsonDecode)
                  String message;
                  bool success = false;
                  try {
                    final data = jsonDecode(r.body);
                    message =
                        data['message']?.toString() ?? 'Opération effectuée';
                    success = r.statusCode == 200;
                  } catch (e) {
                    message = 'Erreur serveur (${r.statusCode})';
                    debugPrint('❌ jsonDecode error: $e');
                  }

                  // ⭐ نحدّثو AuthProvider إذا نجح التعديل وكان الإيميل تبدل
                  if (success && body['email'] != null) {
                    await context
                        .read<AuthProvider>()
                        .updateUser(email: newEmail);
                  }

                  // ⭐ نوريو SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: success ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ HTTP error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur de connexion: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Modifier',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════ SUPPRIMER ══════
  Future<void> _supprimerCompte() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Supprimer le compte',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Cette action est irréversible.\nToutes vos données seront supprimées.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Gérer mon compte',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.business, size: 55, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PROPRIÉTAIRE',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _actionCard(
              icon: Icons.edit_outlined,
              label: 'Modifier compte',
              subtitle: 'Changer email ou mot de passe',
              color: Colors.blue,
              onTap: _showModifierDialog,
            ),
            const SizedBox(height: 14),
            _actionCard(
              icon: Icons.delete_outline,
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}
