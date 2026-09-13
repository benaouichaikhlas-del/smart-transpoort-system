import 'dart:convert';
import 'dart:math' as math;
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
  // ===== Palette =====
  static const Color bgDark = Color(0xFF0B0B16);
  static const Color cardDark = Color(0xFF141422);
  static const Color cardBorder = Color(0xFF232336);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentPink = Color(0xFFb06af0);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  // Couleur identique à ConducteurFormPage
  static const Color colorConducteur = Color.fromRGBO(16, 185, 129, 1);

  int _navIndex = 0;
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.token != null) {
      _statsFuture = _fetchStats(user!.token!);
    }
  }

  Future<Map<String, dynamic>> _fetchStats(String token) async {
    try {
      final url = '${ApiConstants.proprietaire}/dashboard-stats';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

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
    final user = context.watch<AuthProvider>().user;
    final email = user?.email ?? 'Propriétaire';
    final nom = user?.nom;
    final displayName =
        (nom != null && nom.isNotEmpty) ? nom : email.split('@').first;

    return Scaffold(
      backgroundColor: bgDark,
      bottomNavigationBar: _buildBottomNav(context, user),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ===== En-tête : titre + sous-titre =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Ligne : titre + bouton déconnexion =====
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                              children: [
                                TextSpan(text: 'Espace '),
                                TextSpan(
                                  text: 'Propriétaire',
                                  style: TextStyle(color: accentPurple),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bouton déconnexion (rouge)
                        _logoutButton(context),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Bienvenue, '),
                          TextSpan(
                            text: displayName,
                            style: const TextStyle(
                              color: accentPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Carte profil (comme l'image) =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildProfileCard(displayName, email),
              ),
            ),

            // ===== Aperçu rapide =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu rapide',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        final stats = snapshot.data ??
                            {
                              'vehicules': 0,
                              'conducteurs': 0,
                              'lignes': 0,
                              'annonces': 0,
                            };
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            _statCard(
                              value: '${stats['vehicules'] ?? 0}',
                              label: 'Véhicules',
                              color: accentPurple,
                              icon: Icons.directions_bus_filled_rounded,
                            ),
                            _statCard(
                              value: '${stats['conducteurs'] ?? 0}',
                              label: 'Conducteurs',
                              color: colorConducteur,
                              icon: Icons.people_alt_rounded,
                            ),
                            _statCard(
                              value: '${stats['lignes'] ?? 0}',
                              label: 'Lignes Actives',
                              color: accentOrange,
                              icon: Icons.alt_route_rounded,
                            ),
                            _statCard(
                              value: '${stats['annonces'] ?? 0}',
                              label: 'Annonces',
                              color: accentBlue,
                              icon: Icons.campaign_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ===== Accès rapide =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  'Accès rapide',
                  style: TextStyle(
                    color: textPrimary.withOpacity(0.95),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200, // ← زدنا الهامش باش ما يخرجش BOTTOM OVERFLOW
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _quickAccessCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Mes\nVéhicules',
                      subtitle: 'Gérer votre flotte',
                      color: accentPurple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VehiculesScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.people_outline_rounded,
                      title: 'Mes\nConducteurs',
                      subtitle: 'Gérer votre équipe',
                      color: colorConducteur,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConducteursScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.alt_route_rounded,
                      title: 'Lignes &\nHoraires',
                      subtitle: 'Planifier les trajets',
                      color: const Color(0xFF5B5BF5),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LignesHorairesScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.link_rounded,
                      title: 'Affectations',
                      subtitle: 'Assigner conducteurs',
                      color: accentBlue,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AffectationScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.campaign_rounded,
                      title: 'Annonces',
                      subtitle: 'Publier des annonces',
                      color: const Color(0xFFFBBF24),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AnnoncesScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Gérer\nCompte',
                      subtitle: 'Modifier ou supprimer',
                      color: accentBlue,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GererCompteScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.directions_bus_outlined,
                      title: 'État des\nVéhicules',
                      subtitle: 'Actif, panne, maintenance',
                      color: accentCyan,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EtatBusScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.map_outlined,
                      title: 'Position\nGPS',
                      subtitle: 'Carte en temps réel',
                      color: accentCyan,
                      onTap: () => _ouvrirSuiviBus(context, user),
                    ),
                    const SizedBox(width: 12),
                    _quickAccessCard(
                      icon: Icons.reviews_outlined,
                      title: 'Avis &\nRapports',
                      subtitle: 'Feedbacks et signalements',
                      color: accentTeal,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AvisRapportsScreen())),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ===== Bouton déconnexion =====
  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmLogout(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accentRed.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: accentRed.withOpacity(0.35), width: 1.2),
        ),
        child: const Icon(Icons.logout_rounded, color: accentRed, size: 21),
      ),
    );
  }

  // ===== Dialog de confirmation (français) =====
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF131324),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2E2E52), width: 1.2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Icône
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentRed.withOpacity(0.3),
                    blurRadius: 18,
                    spreadRadius: 1,
                  )
                ],
              ),
              child:
                  const Icon(Icons.logout_rounded, color: accentRed, size: 27),
            ),
            const SizedBox(height: 18),
            const Text('Déconnexion',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'Voulez-vous vraiment vous\ndéconnecter ?',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 26),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF2E2E52), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
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
                    color: accentRed,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentRed.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleLogout(context);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: Text('Se déconnecter',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
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
  }

  // ===== Carte profil =====

  Widget _buildProfileCard(String displayName, String email) {
    return Container(
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B1040),
            Color(0xFF241245),
            Color(0xFF2A1550),
          ],
        ),
        border: Border.all(color: accentPurple.withOpacity(0.25), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentPurple.withOpacity(0.55),
                    accentPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentPurple.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentPurple.withOpacity(0.7),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.apartment_rounded,
                      color: accentPurple.withOpacity(0.9),
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: accentPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PROPRIÉTAIRE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Carte statistique avec sparkline =====

  Widget _statCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ← Expanded + ellipsis : باش "Lignes Actives" ما تخرجش للبرا
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 52, // ← صغّرنا الـ sparkline باش يكفي المكان
                height: 22,
                child: CustomPaint(
                  painter: _SparklinePainter(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== Carte accès rapide (horizontale comme l'image) =====

  Widget _quickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 11,
                height: 1.2,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Bottom navigation =====

  Widget _buildBottomNav(BuildContext context, dynamic user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: BottomNavigationBar(
            currentIndex: _navIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: accentPurple,
            unselectedItemColor: textSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            iconSize: 24,
            onTap: (i) {
              setState(() => _navIndex = i);
              switch (i) {
                case 1:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VehiculesScreen()));
                  break;
                case 2:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConducteursScreen()));
                  break;
                case 3:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LignesHorairesScreen()));
                  break;
                case 4:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GererCompteScreen()));
                  break;
              }
              if (i != 0) setState(() => _navIndex = 0);
            },
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded), label: 'Accueil'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping_outlined),
                  label: 'Véhicules'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline_rounded),
                  label: 'Conducteurs'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.route_outlined), label: 'Lignes'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Logique métier (inchangée) =====

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

// ===== Sparkline décorative (courbe comme dans l'image) =====

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.35),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];
    const n = 7;
    final rnd = math.Random(7);

    for (var i = 0; i < n; i++) {
      final x = (size.width / (n - 1)) * i;
      final wave = math.sin(i * 1.4) * size.height * 0.28;
      final y = size.height * 0.55 + wave + rnd.nextDouble() * 4 - 2;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final control = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2 - 4);
      path.quadraticBezierTo(p0.dx, p0.dy, control.dx, control.dy);
      if (i == points.length - 2) path.lineTo(p1.dx, p1.dy);
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color;
}
