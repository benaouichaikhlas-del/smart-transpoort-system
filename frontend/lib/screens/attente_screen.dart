import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'login_screen.dart';

class AttenteScreen extends StatelessWidget {
  const AttenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 90,
                  color: AppTheme.warning,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Demande envoyée !',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre demande est en attente de validation.\nL\'administrateur vous contactera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, height: 1.6),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    ),
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      'Se connecter',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: AppTheme.primaryButton(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
