import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'position_vehicules_screen.dart';
import 'welcome_screen.dart';
import 'conducteurs_screen.dart';
import 'vehicules_screen.dart';
import 'lignes_horaires_screen.dart';
import 'affectation_screen.dart';
import 'annonces_screen.dart';
import 'gerer_compte_screen.dart';
import 'etat_bus_screen.dart';
import 'avis_rapports_screen.dart';

class ProprietaireHomeScreen extends StatefulWidget {
  const ProprietaireHomeScreen({super.key});

  @override
  State<ProprietaireHomeScreen> createState() => _ProprietaireHomeScreenState();
}

class _ProprietaireHomeScreenState extends State<ProprietaireHomeScreen> {
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color cardDark = Color(0xFF1E1E2D);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.token != null) {
      _statsFuture = _fetchStats(user!.token!);
    }
  }

  /// ⭐ جلب الإحصائيات — URL مصحح
  Future<Map<String, dynamic>> _fetchStats(String token) async {
    try {
      // ✅ صحيح: baseUrl فيه /api من قبل
      final url = '${ApiConstants.proprietaire}/dashboard-stats';
      debugPrint('🌐 Stats URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 Stats Status: ${response.statusCode}');
      debugPrint('📡 Stats Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Erreur stats: $e');
      return {
        'vehicules': 0,
        'conducteurs': 0,
        'lignes': 0,
        'annonces': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ context.watch باش يعيد البناء ملي يتبدّل user
    final user = context.watch<AuthProvider>().user;
    final email = user?.email ?? 'Propriétaire';
    final nom = user?.nom;
    final displayName =
        (nom != null && nom.isNotEmpty) ? nom : email.split('@').first;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, $displayName',
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: accentPurple),
                        onPressed: () => _handleLogout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Badge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accentPurple.withOpacity(0.3), width: 1),
                  ),
                  child: const Text(
                    'PROPRIÉTAIRE',
                    style: TextStyle(
                      color: accentPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // Aperçu rapide
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu rapide',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        final stats = snapshot.data ??
                            {
                              'vehicules': 0,
                              'conducteurs': 0,
                              'lignes': 0,
                              'annonces': 0
                            };

                        return Row(
                          children: [
                            _statCard(
                              '${stats['vehicules'] ?? 0}',
                              'Véhicules',
                              accentPurple,
                              Icons.local_shipping,
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              '${stats['conducteurs'] ?? 0}',
                              'Conducteurs',
                              accentGreen,
                              Icons.people_outline,
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              '${stats['lignes'] ?? 0}',
                              'Lignes',
                              accentOrange,
                              Icons.route,
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              '${stats['annonces'] ?? 0}',
                              'Annonces',
                              accentBlue,
                              Icons.campaign,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Accès rapide
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Text(
                  'Accès rapide',
                  style: TextStyle(
                    color: textPrimary.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _menuCard(
                    context,
                    icon: Icons.local_shipping,
                    title: 'Mes Véhicules',
                    subtitle: 'Gérer votre flotte',
                    color: accentPurple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VehiculesScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.people_outline,
                    title: 'Mes Conducteurs',
                    subtitle: 'Gérer votre équipe',
                    color: accentGreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConducteursScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.route,
                    title: 'Lignes & Horaires',
                    subtitle: 'Planifier les trajets',
                    color: accentOrange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LignesHorairesScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.link,
                    title: 'Affectations',
                    subtitle: 'Assigner conducteurs aux lignes',
                    color: const Color(0xFFb06af0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AffectationScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.campaign,
                    title: 'Annonces',
                    subtitle: 'Publier des annonces',
                    color: accentRed,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnnoncesScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.manage_accounts,
                    title: 'Gérer Compte',
                    subtitle: 'Modifier ou supprimer',
                    color: accentBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GererCompteScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.directions_bus_outlined,
                    title: 'État des Véhicules',
                    subtitle: 'Actif, panne, maintenance',
                    color: accentCyan,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EtatBusScreen()),
                    ),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.map_outlined,
                    title: 'Position GPS',
                    subtitle: 'Carte en temps réel',
                    color: Colors.green,
                    onTap: () => _ouvrirSuiviBus(context, user),
                  ),
                  _menuCard(
                    context,
                    icon: Icons.reviews_outlined,
                    title: 'Avis & Rapports',
                    subtitle: 'Feedbacks et signalements',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AvisRapportsScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: textSecondary,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ouvrirSuiviBus(BuildContext context, dynamic user) async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.proprietaire}/mon-id'),
        headers: {'Authorization': 'Bearer ${user?.token}'},
      ).timeout(const Duration(seconds: 10));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final realProprietaireId = data['id'];
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuivreBusPage(
              token: user?.token ?? '',
              proprietaireId: realProprietaireId,
            ),
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de récupérer votre profil')),
        );
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion')),
      );
    }
  }

  void _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }
}
