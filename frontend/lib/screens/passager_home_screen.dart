import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'chatbot_screen.dart';
import 'position_vehicules_screen.dart';
import 'welcome_screen.dart';

/// ============================================================================
/// NEON & DARK UI THEMING CONSTANTS (Matching Screenshots 1-5)
/// ============================================================================
class DarkNeonTheme {
  static const Color background = Color(0xFF060B19);
  static const Color cardBg = Color(0xFF0F172A);
  static const Color cardBgDark = Color(0xFF0B1120);
  static const Color primaryCyan = Color(0xFF00F0FF);
  static const Color primaryBlue = Color(0xFF1E8CFF);
  static const Color accentPurple = Color(0xFF7B61FF);
  static const Color accentPink = Color(0xFFFF2A6D);
  static const Color successGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFF8E9BAE);
  static const Color textSubtle = Color(0xFF4A5568);

  static BoxDecoration glowBoxDecoration({
    required Color borderColor,
    double opacity = 0.35,
    double borderRadius = 18.0,
    Color? fillColor,
  }) {
    return BoxDecoration(
      color: fillColor ?? cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor.withOpacity(0.45), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(opacity * 0.5),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// ============================================================================
/// MAIN PASSAGER HOME SCREEN (CONTAINER & STATE)
/// ============================================================================
class PassagerHomeScreen extends StatefulWidget {
  const PassagerHomeScreen({super.key});

  @override
  State<PassagerHomeScreen> createState() => _PassagerHomeScreenState();
}

class _PassagerHomeScreenState extends State<PassagerHomeScreen> {
  int _selectedIndex = 0;
  String get _token => context.read<AuthProvider>().user?.token ?? '';

  final _ligneSearchCtrl = TextEditingController();
  String? _pendingLigneSearch;

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _lancerRechercheLigne(String value) {
    final q = value.trim();
    setState(() {
      _pendingLigneSearch = q;
      _selectedIndex = 1;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _ligneSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: DarkNeonTheme.background,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildAccueil(),
              _TrajetsPage(
                token: _token,
                initialSearch: _pendingLigneSearch,
                onReservationComplete: () => _navigateToTab(2),
              ),
              _MesReservationsPage(token: _token),
              _AlertesPage(token: _token),
              _EvaluationPage(token: _token),
              _buildProfil(),
            ],
          ),
          bottomNavigationBar: _NotifBadgeNav(
            selectedIndex: _selectedIndex,
            token: _token,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// 1. ACCUEIL PAGE
  /// --------------------------------------------------------------------------
  Widget _buildAccueil() {
    final user = context.watch<AuthProvider>().user;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccueilHeader(
              user: user,
              onAssistantTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatbotScreen(token: _token)),
              ),
            ),
            const SizedBox(height: 24),
            _LigneSearchBar(
              controller: _ligneSearchCtrl,
              onSubmitted: _lancerRechercheLigne,
            ),
            const SizedBox(height: 20),
            _MapPreviewCard(
              onOpenFullMap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SuivreBusPage(token: _token)),
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(index: '01', title: 'Actions rapides'),
            const SizedBox(height: 14),
            _QuickActionsGrid(
              onSuivreBus: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SuivreBusPage(token: _token)),
              ),
              onReserver: () => setState(() => _selectedIndex = 1),
              onMesReservations: () => setState(() => _selectedIndex = 2),
              onRetards: () => setState(() => _selectedIndex = 3),
              onEvaluer: () => setState(() => _selectedIndex = 4),
              onAssistantIA: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatbotScreen(token: _token)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// 6. PROFIL PAGE (Matches Screenshot 1)
  /// --------------------------------------------------------------------------
  Widget _buildProfil() {
    final user = context.watch<AuthProvider>().user;
    final emailOrTel = user?.email ?? user?.tel ?? 'user1@gmail.com';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Top Avatar with Neon Glow Ring
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DarkNeonTheme.primaryBlue.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: DarkNeonTheme.primaryCyan.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DarkNeonTheme.cardBgDark,
                    border: Border.all(
                      color: DarkNeonTheme.primaryCyan,
                      width: 2.5,
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person_rounded,
                      size: 54,
                      color: DarkNeonTheme.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User email
            Text(
              emailOrTel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),

            // PASSAGER Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: DarkNeonTheme.cardBgDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DarkNeonTheme.primaryCyan,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DarkNeonTheme.primaryCyan.withOpacity(0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: DarkNeonTheme.primaryCyan,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PASSAGER',
                    style: TextStyle(
                      color: DarkNeonTheme.primaryCyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Option 1: Modifier compte Card
            _profilItemCard(
              icon: Icons.edit_rounded,
              label: 'Modifier compte',
              glowColor: DarkNeonTheme.primaryBlue,
              iconBgColor: DarkNeonTheme.primaryBlue.withOpacity(0.2),
              onTap: () => _showModifierCompteDialog(),
            ),
            const SizedBox(height: 16),

            // Option 2: Supprimer compte Card
            _profilItemCard(
              icon: Icons.delete_rounded,
              label: 'Supprimer compte',
              glowColor: DarkNeonTheme.accentPink,
              iconBgColor: DarkNeonTheme.accentPink.withOpacity(0.2),
              onTap: () => _showSupprimerCompteDialog(),
            ),

            const Spacer(),

            // Se Déconnecter Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2A6D),
                      Color(0xFFD81B60),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: DarkNeonTheme.accentPink.withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _showSupprimerCompteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DarkNeonTheme.cardBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: DarkNeonTheme.accentPink, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: DarkNeonTheme.accentPink, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Supprimer le compte ?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible et effacera toutes vos données.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.white, size: 18),
            label: const Text('Oui, supprimer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkNeonTheme.accentPink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await http.delete(
        Uri.parse('${ApiConstants.passager}/supprimer-compte'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (!mounted) return;

    await context.read<AuthProvider>().logout();

    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Votre compte a été supprimé avec succès.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Widget _profilItemCard({
    required IconData icon,
    required String label,
    required Color glowColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: DarkNeonTheme.glowBoxDecoration(
        borderColor: glowColor,
        opacity: 0.3,
        borderRadius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: glowColor.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(icon, color: glowColor, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showModifierCompteDialog() async {
    final user = context.read<AuthProvider>().user;
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final telCtrl = TextEditingController(text: user?.tel ?? '');
    final mdpActuelCtrl = TextEditingController();
    final nouveauMdpCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setS) {
          bool isLoading = false;
          return AlertDialog(
            backgroundColor: DarkNeonTheme.cardBgDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: DarkNeonTheme.primaryBlue),
            ),
            title: const Row(
              children: [
                Icon(Icons.edit_rounded,
                    color: DarkNeonTheme.primaryCyan, size: 22),
                SizedBox(width: 10),
                Text('Modifier mon compte',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(emailCtrl, 'Email', Icons.email,
                      TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(
                      telCtrl, 'Téléphone', Icons.phone, TextInputType.phone),
                  const Divider(color: Colors.white12, height: 24),
                  const Text('Changer le mot de passe (optionnel)',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  _field(mdpActuelCtrl, 'Mot de passe actuel', Icons.lock,
                      TextInputType.text,
                      obscure: true),
                  const SizedBox(height: 12),
                  _field(nouveauMdpCtrl, 'Nouveau mot de passe',
                      Icons.lock_outline, TextInputType.text,
                      obscure: true),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setS(() => isLoading = true);
                        final newEmail = emailCtrl.text.trim();
                        final newTel = telCtrl.text.trim();
                        final body = {
                          'email': newEmail,
                          'tel': newTel,
                        };
                        if (mdpActuelCtrl.text.isNotEmpty) {
                          body['mot_de_passe_actuel'] = mdpActuelCtrl.text;
                          body['nouveau_mot_de_passe'] = nouveauMdpCtrl.text;
                        }
                        try {
                          final r = await http
                              .put(
                                Uri.parse(
                                    '${ApiConstants.passager}/modifier-compte'),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer $_token',
                                },
                                body: jsonEncode(body),
                              )
                              .timeout(const Duration(seconds: 10));

                          if (!mounted) return;

                          final responseData = jsonDecode(r.body);
                          final msg = responseData['message'] ?? 'Erreur';

                          if (r.statusCode == 200) {
                            final newToken = responseData['token'] as String?;

                            // 1. Pop dialog first so dialog element deactivates cleanly
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            // 2. Schedule AuthProvider update and SnackBar after frame
                            Future.microtask(() async {
                              if (mounted) {
                                await context.read<AuthProvider>().updateUser(
                                      email: newEmail,
                                      tel: newTel,
                                      token: newToken,
                                    );
                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Compte modifié avec succès ✅'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            });
                          } else {
                            setS(() => isLoading = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                    content: Text(msg),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        } catch (e) {
                          setS(() => isLoading = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkNeonTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Enregistrer',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    // 3. Dispose controllers after dialog unmount animation completes (~500ms)
    await Future.delayed(const Duration(milliseconds: 500));
    emailCtrl.dispose();
    telCtrl.dispose();
    mdpActuelCtrl.dispose();
    nouveauMdpCtrl.dispose();
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      TextInputType type,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: DarkNeonTheme.primaryCyan),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: DarkNeonTheme.primaryCyan),
        ),
      ),
    );
  }
}

/// ============================================================================
/// REUSABLE HEADER BANNER WITH BUS IMAGE (Top of Reserver & Evaluer screens)
/// ============================================================================
class _HeaderBannerWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;

  const _HeaderBannerWidget({
    required this.title,
    required this.subtitle,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 125,
      padding: const EdgeInsets.all(16),
      decoration: DarkNeonTheme.glowBoxDecoration(
        borderColor: DarkNeonTheme.primaryBlue,
        opacity: 0.3,
        borderRadius: 20,
        fillColor: DarkNeonTheme.cardBgDark,
      ),
      child: Stack(
        children: [
          // Background Bus Banner Image
          Positioned(
            right: -10,
            bottom: -15,
            top: -15,
            width: 180,
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/bus_header_banner.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_bus_filled_rounded,
                  size: 80,
                  color: DarkNeonTheme.primaryBlue,
                ),
              ),
            ),
          ),
          // Text Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: DarkNeonTheme.primaryCyan, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DarkNeonTheme.warningAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: DarkNeonTheme.warningAmber.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: DarkNeonTheme.warningAmber, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            badgeText!,
                            style: const TextStyle(
                              color: DarkNeonTheme.warningAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 2. RÉSERVER UN TRAJET PAGE (_TrajetsPage - Matches Screenshot 2 - 3 Steps)
/// ============================================================================
class _TrajetsPage extends StatefulWidget {
  final String token;
  final String? initialSearch;
  final VoidCallback onReservationComplete;

  const _TrajetsPage({
    required this.token,
    this.initialSearch,
    required this.onReservationComplete,
  });

  @override
  State<_TrajetsPage> createState() => _TrajetsPageState();
}

class _TrajetsPageState extends State<_TrajetsPage> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _lignes = [];
  List<dynamic> _lignesFiltrees = [];
  bool _loadingLignes = false;

  Map<String, dynamic>? _ligneSelectionnee;
  DateTime _dateSelectionnee = DateTime.now();
  List<dynamic> _horaires = [];
  bool _loadingHoraires = false;
  Map<String, dynamic>? _horaireSelectionne;

  int _etape = 0; // 0: Ligne, 1: Horaire, 2: Confirmer
  int _nbPlaces = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchCtrl.text = widget.initialSearch!;
    }
    _chargerLignes(search: widget.initialSearch);
    _searchCtrl.addListener(_filtrer);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filtrer);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerLignes({String? search}) async {
    setState(() => _loadingLignes = true);
    try {
      final url = search != null && search.isNotEmpty
          ? '${ApiConstants.passager}/lignes-recherche?search=$search'
          : '${ApiConstants.passager}/lignes-recherche';
      final r =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _lignes = jsonDecode(r.body);
          _lignesFiltrees = List.from(_lignes);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLignes = false);
  }

  void _filtrer() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _lignesFiltrees = q.isEmpty
          ? List.from(_lignes)
          : _lignes.where((l) {
              final nom = (l['nom'] ?? '').toString().toLowerCase();
              final num = (l['numero'] ?? '').toString().toLowerCase();
              return nom.contains(q) || num.contains(q);
            }).toList();
    });
  }

  Future<void> _chargerHoraires() async {
    if (_ligneSelectionnee == null) return;
    setState(() {
      _loadingHoraires = true;
      _horaires = [];
    });
    try {
      final date =
          '${_dateSelectionnee.year}-${_dateSelectionnee.month.toString().padLeft(2, '0')}-${_dateSelectionnee.day.toString().padLeft(2, '0')}';
      final r = await http
          .get(
            Uri.parse(
                '${ApiConstants.passager}/ligne/${_ligneSelectionnee!['id']}/horaires?date=$date'),
          )
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && mounted) {
        setState(() => _horaires = jsonDecode(r.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingHoraires = false);
  }

  Future<void> _reserver(Map<String, dynamic> horaire, int nbPlaces) async {
    if (widget.token.isEmpty) {
      _showSnack('Connectez-vous pour réserver', false);
      return;
    }
    try {
      final date =
          '${_dateSelectionnee.year}-${_dateSelectionnee.month.toString().padLeft(2, '0')}-${_dateSelectionnee.day.toString().padLeft(2, '0')}';
      final r = await http.post(
        Uri.parse('${ApiConstants.passager}/reserver-avec-date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'ligne_id': _ligneSelectionnee!['id'],
          'horaire_id': horaire['id'],
          'date': date,
          'nb_places': nbPlaces,
        }),
      );
      if (mounted) {
        final msg = jsonDecode(r.body)['message'] ?? 'Erreur';
        if (r.statusCode == 201) {
          _PassagerHomeScreenState.scaffoldMessengerKey.currentState
              ?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Réservation confirmée ! $msg',
                        style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          setState(() {
            _etape = 0;
            _ligneSelectionnee = null;
            _searchCtrl.clear();
            _horaires = [];
            _horaireSelectionne = null;
            _nbPlaces = 1;
          });
          widget.onReservationComplete();
        } else {
          _showSnack(msg, false);
        }
      }
    } catch (_) {
      if (mounted) _showSnack('Connexion perdue', false);
    }
  }

  void _showSnack(String msg, bool ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  String _formatDate(DateTime d) {
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const mois = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month - 1]} ${d.year}';
  }

  String _formatHeure(String? h) {
    if (h == null) return '--:--';
    return h.length >= 5 ? h.substring(0, 5) : h;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Banner Header at Top
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _HeaderBannerWidget(
              title: 'Réserver un trajet',
              subtitle: 'Trouvez votre ligne et réservez facilement',
            ),
          ),

          // Stepper Indicator (1 Ligne -> 2 Horaire -> 3 Confirmer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _stepCircle(1, 'Ligne', _etape >= 0),
                _stepLine(_etape >= 1),
                _stepCircle(2, 'Horaire', _etape >= 1),
                _stepLine(_etape >= 2),
                _stepCircle(3, 'Confirmer', _etape >= 2),
              ],
            ),
          ),

          Expanded(
            child: _etape == 0
                ? _buildEtape1()
                : _etape == 1
                    ? _buildEtape2()
                    : _buildEtape3(),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape1() {
    return Column(
      children: [
        // Search Box Container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: DarkNeonTheme.glowBoxDecoration(
            borderColor: DarkNeonTheme.primaryBlue,
            opacity: 0.3,
            borderRadius: 16,
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher (ex: Mila, Constantine...)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  color: DarkNeonTheme.primaryCyan, size: 22),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.white38, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),

        // Lignes populaires Header Row
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Text('Lignes populaires',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Voir toutes >',
                  style: TextStyle(
                      color: DarkNeonTheme.primaryCyan, fontSize: 12)),
            ],
          ),
        ),

        Expanded(
          child: _loadingLignes
              ? const Center(
                  child: CircularProgressIndicator(
                      color: DarkNeonTheme.primaryCyan))
              : _lignesFiltrees.isEmpty
                  ? const Center(
                      child: Text('Aucune ligne disponible',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _lignesFiltrees.length,
                      itemBuilder: (_, i) {
                        final l = _lignesFiltrees[i];
                        final colorsList = [
                          DarkNeonTheme.primaryBlue,
                          DarkNeonTheme.successGreen,
                          DarkNeonTheme.accentPurple,
                          DarkNeonTheme.warningAmber,
                        ];
                        final badgeColor = colorsList[i % colorsList.length];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: DarkNeonTheme.glowBoxDecoration(
                            borderColor: badgeColor,
                            opacity: 0.25,
                            borderRadius: 16,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _ligneSelectionnee = l;
                                  _etape = 1;
                                });
                                _chargerHoraires();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: badgeColor.withOpacity(0.5)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          l['numero'] ?? 'L${i + 1}',
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l['nom'] ?? 'Mila -> Constantine',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  color: Colors.white38,
                                                  size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_formatHeure(l['heure_debut'])} -> ${_formatHeure(l['heure_fin'])}',
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: Colors.white38, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEtape2() {
    return Column(
      children: [
        // Back Pill to Step 1
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: DarkNeonTheme.glowBoxDecoration(
            borderColor: DarkNeonTheme.primaryBlue,
            opacity: 0.4,
            borderRadius: 14,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _etape = 0;
                  _ligneSelectionnee = null;
                }),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: DarkNeonTheme.primaryCyan, size: 18),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.directions_bus_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_ligneSelectionnee!['numero']} -> ${_ligneSelectionnee!['nom']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Date Selector Bar
        SizedBox(
          height: 75,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 14,
            itemBuilder: (_, i) {
              final date = DateTime.now().add(Duration(days: i));
              final isSelected = date.day == _dateSelectionnee.day &&
                  date.month == _dateSelectionnee.month;
              const joursAbrev = [
                'Lun',
                'Mar',
                'Mer',
                'Jeu',
                'Ven',
                'Sam',
                'Dim'
              ];
              return GestureDetector(
                onTap: () {
                  setState(() => _dateSelectionnee = date);
                  _chargerHoraires();
                },
                child: Container(
                  width: 58,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              DarkNeonTheme.primaryBlue,
                              DarkNeonTheme.primaryCyan
                            ],
                          )
                        : null,
                    color: isSelected ? null : DarkNeonTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? DarkNeonTheme.primaryCyan
                          : Colors.white12,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        joursAbrev[date.weekday - 1],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: DarkNeonTheme.primaryCyan, size: 14),
              const SizedBox(width: 6),
              Text(_formatDate(_dateSelectionnee),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),

        Expanded(
          child: _loadingHoraires
              ? const Center(
                  child: CircularProgressIndicator(
                      color: DarkNeonTheme.primaryCyan))
              : _horaires.isEmpty
                  ? const Center(
                      child: Text('Aucun horaire disponible ce jour',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _horaires.length,
                      itemBuilder: (_, i) {
                        final h = _horaires[i];
                        final dispo = h['places_restantes'] as int? ?? 30;
                        final plein = dispo <= 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: DarkNeonTheme.glowBoxDecoration(
                            borderColor: plein
                                ? DarkNeonTheme.accentPink
                                : DarkNeonTheme.primaryBlue,
                            opacity: 0.3,
                            borderRadius: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _formatHeure(
                                              h['heure_depart']?.toString()),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Icon(
                                              Icons.arrow_forward_rounded,
                                              color: DarkNeonTheme.primaryCyan,
                                              size: 18),
                                        ),
                                        Text(
                                          _formatHeure(
                                              h['heure_arrivee']?.toString()),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: DarkNeonTheme.primaryBlue
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _ligneSelectionnee!['numero'] ?? '',
                                            style: const TextStyle(
                                              color: DarkNeonTheme.primaryCyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('~1h30min',
                                            style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: DarkNeonTheme.successGreen
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: DarkNeonTheme.successGreen
                                              .withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_seat,
                                            color: DarkNeonTheme.successGreen,
                                            size: 12),
                                        const SizedBox(width: 4),
                                        Text('dispo $dispo',
                                            style: const TextStyle(
                                                color:
                                                    DarkNeonTheme.successGreen,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: plein
                                        ? null
                                        : () {
                                            setState(() {
                                              _horaireSelectionne = h;
                                              _etape = 2;
                                            });
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          DarkNeonTheme.primaryBlue,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                    ),
                                    child: const Text('Choisir',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEtape3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _etape = 1),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded,
                    color: DarkNeonTheme.primaryCyan, size: 16),
                SizedBox(width: 4),
                Text('Modifier le trajet',
                    style: TextStyle(
                        color: DarkNeonTheme.primaryCyan, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirmation Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.primaryCyan,
              opacity: 0.4,
              borderRadius: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DarkNeonTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_ligneSelectionnee!['numero'] ?? 'L22',
                          style: const TextStyle(
                              color: DarkNeonTheme.primaryCyan,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(_formatDate(_dateSelectionnee),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          _formatHeure(
                              _horaireSelectionne!['heure_depart']?.toString()),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text('Mila',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: DarkNeonTheme.primaryCyan, size: 24),
                    ),
                    Column(
                      children: [
                        Text(
                          _formatHeure(_horaireSelectionne!['heure_arrivee']
                              ?.toString()),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text('Costantin',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Nombre de places',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Places Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.primaryBlue,
              opacity: 0.3,
              borderRadius: 16,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_nbPlaces > 1) setState(() => _nbPlaces--);
                      },
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: DarkNeonTheme.accentPink, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: DarkNeonTheme.cardBgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DarkNeonTheme.primaryCyan.withOpacity(0.4)),
                      ),
                      child: Text('$_nbPlaces',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        setState(() => _nbPlaces++);
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: DarkNeonTheme.successGreen, size: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Max: 30 places disponibles',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    DarkNeonTheme.primaryBlue,
                    DarkNeonTheme.primaryCyan
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DarkNeonTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _reserver(_horaireSelectionne!, _nbPlaces),
                icon: const Icon(Icons.confirmation_number_rounded,
                    color: Colors.white),
                label: const Text('Confirmer la réservation',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(int num, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                active ? DarkNeonTheme.primaryCyan : DarkNeonTheme.cardBgDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? DarkNeonTheme.primaryCyan : Colors.white24,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: DarkNeonTheme.primaryCyan.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$num',
              style: TextStyle(
                color: active ? Colors.black : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? DarkNeonTheme.primaryCyan : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: active ? DarkNeonTheme.primaryCyan : Colors.white12,
      ),
    );
  }
}

/// ============================================================================
/// 3. MES RÉSERVATIONS PAGE (_MesReservationsPage - Matches Screenshot 3)
/// ============================================================================
class _MesReservationsPage extends StatefulWidget {
  final String token;
  const _MesReservationsPage({required this.token});

  @override
  State<_MesReservationsPage> createState() => _MesReservationsPageState();
}

class _MesReservationsPageState extends State<_MesReservationsPage> {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filter);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      var list = _showActiveOnly
          ? _all
              .where((r) =>
                  (r['statut'] ?? 'active').toString().toLowerCase() ==
                  'active')
              .toList()
          : List.from(_all);
      if (q.isNotEmpty) {
        list = list.where((r) {
          final num = (r['ligne_numero'] ?? '').toString().toLowerCase();
          final nom = (r['ligne_nom'] ?? '').toString().toLowerCase();
          return num.contains(q) || nom.contains(q);
        }).toList();
      }
      _filtered = list;
    });
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.passager}/mes-reservations'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && mounted) {
        setState(() => _all = jsonDecode(r.body));
        _filter();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _modifier(Map<String, dynamic> resa) async {
    int nbPlaces = (resa['nb_places'] as int? ?? 1);
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: DarkNeonTheme.cardBgDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: DarkNeonTheme.primaryBlue),
          ),
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DarkNeonTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(resa['ligne_numero'] ?? 'L22',
                    style: const TextStyle(
                        color: DarkNeonTheme.primaryCyan,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Modifier réservation',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nombre de places :',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (nbPlaces > 1) setS(() => nbPlaces--);
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        color: DarkNeonTheme.accentPink, size: 32),
                  ),
                  Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: DarkNeonTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$nbPlaces',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () {
                      setS(() => nbPlaces++);
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: DarkNeonTheme.successGreen, size: 32),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, nbPlaces),
              style: ElevatedButton.styleFrom(
                backgroundColor: DarkNeonTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || confirmed == resa['nb_places']) return;

    final r = await http.put(
      Uri.parse('${ApiConstants.passager}/reservation/${resa['id']}/modifier'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'nb_places': confirmed}),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(jsonDecode(r.body)['message'] ?? 'Modifié avec succès'),
        backgroundColor: r.statusCode == 200 ? Colors.green : Colors.red,
      ),
    );
    if (r.statusCode == 200) _load();
  }

  Future<void> _annuler(int id, String ligne) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkNeonTheme.cardBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: DarkNeonTheme.accentPink),
        ),
        title: const Text('Annuler la réservation ?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Vous allez annuler votre réservation pour $ligne. Cette action est irréversible.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non, garder',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkNeonTheme.accentPink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final r = await http.put(
      Uri.parse('${ApiConstants.passager}/reservation/$id/annuler'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(jsonDecode(r.body)['message'] ?? 'Réservation annulée'),
        backgroundColor: r.statusCode == 200 ? Colors.green : Colors.red,
      ),
    );
    if (r.statusCode == 200) _load();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _all
        .where((r) =>
            (r['statut'] ?? 'active').toString().toLowerCase() == 'active')
        .length;

    return SafeArea(
      child: Stack(
        children: [
          // Bus Illustration at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 250,
            child: Opacity(
              opacity: 0.75,
              child: Image.asset(
                'assets/images/bus_bottom_illustration.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // Content Layer
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_rounded,
                        color: DarkNeonTheme.primaryCyan, size: 24),
                    const SizedBox(width: 10),
                    const Text('Mes réservations',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DarkNeonTheme.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: DarkNeonTheme.successGreen.withOpacity(0.4)),
                      ),
                      child: Text('$activeCount actives',
                          style: const TextStyle(
                              color: DarkNeonTheme.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _load),
                  ],
                ),
              ),

              // Search Box + Filter Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: DarkNeonTheme.glowBoxDecoration(
                          borderColor: DarkNeonTheme.primaryBlue,
                          opacity: 0.3,
                          borderRadius: 14,
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher une ligne...',
                            hintStyle: TextStyle(color: Colors.white38),
                            prefixIcon: Icon(Icons.search,
                                color: DarkNeonTheme.primaryCyan),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showActiveOnly = !_showActiveOnly);
                        _filter();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: DarkNeonTheme.glowBoxDecoration(
                          borderColor: _showActiveOnly
                              ? DarkNeonTheme.primaryCyan
                              : Colors.white24,
                          opacity: 0.4,
                          borderRadius: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: _showActiveOnly
                                  ? DarkNeonTheme.primaryCyan
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showActiveOnly ? 'Actives' : 'Toutes',
                              style: TextStyle(
                                color: _showActiveOnly
                                    ? DarkNeonTheme.primaryCyan
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: DarkNeonTheme.primaryCyan))
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text('Aucune réservation',
                                style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final r = _filtered[i];
                              final statusStr = (r['statut'] ?? 'active')
                                  .toString()
                                  .toLowerCase();
                              final isActive = statusStr == 'active';
                              final statusColor = isActive
                                  ? DarkNeonTheme.successGreen
                                  : DarkNeonTheme.accentPink;
                              final placesCount = r['nb_places'] ?? 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(18),
                                decoration: DarkNeonTheme.glowBoxDecoration(
                                  borderColor: statusColor,
                                  opacity: 0.4,
                                  borderRadius: 18,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: DarkNeonTheme.primaryBlue
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                              r['ligne_numero'] ?? 'L22',
                                              style: const TextStyle(
                                                  color:
                                                      DarkNeonTheme.primaryCyan,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                              r['ligne_nom'] ??
                                                  'Mila -> costantin',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                statusColor.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: statusColor
                                                    .withOpacity(0.4)),
                                          ),
                                          child: Text(
                                              isActive
                                                  ? '• ACTIVE'
                                                  : '• ANNULÉE',
                                              style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.event_seat_rounded,
                                            size: 16, color: Colors.white54),
                                        const SizedBox(width: 6),
                                        Text('$placesCount place(s)',
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                        if (r['heure_depart'] != null) ...[
                                          const SizedBox(width: 16),
                                          const Icon(Icons.access_time_rounded,
                                              size: 16, color: Colors.white54),
                                          const SizedBox(width: 6),
                                          Text(
                                              '${r['heure_depart']} -> ${r['heure_arrivee'] ?? ''}',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _modifier(r),
                                              icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 16,
                                                  color: DarkNeonTheme
                                                      .primaryCyan),
                                              label: const Text('Modifier',
                                                  style: TextStyle(
                                                      color: DarkNeonTheme
                                                          .primaryCyan)),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                    color: DarkNeonTheme
                                                        .primaryCyan
                                                        .withOpacity(0.5)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _annuler(r['id'],
                                                  r['ligne_numero'] ?? 'Ligne'),
                                              icon: const Icon(
                                                  Icons.cancel_outlined,
                                                  size: 16,
                                                  color:
                                                      DarkNeonTheme.accentPink),
                                              label: const Text('Annuler',
                                                  style: TextStyle(
                                                      color: DarkNeonTheme
                                                          .accentPink)),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                    color: DarkNeonTheme
                                                        .accentPink
                                                        .withOpacity(0.5)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 4. ALERTES PAGE (Matches Screenshot 4 - Notifications & Incidents Tabs)
/// ============================================================================
class _AlertesPage extends StatefulWidget {
  final String token;
  const _AlertesPage({required this.token});

  @override
  State<_AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<_AlertesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _notifications = [];
  int _nonLues = 0;
  Map<String, dynamic> _retardsPannes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final futures = <Future>[
        http.get(Uri.parse('${ApiConstants.passager}/retards-pannes')),
      ];
      if (widget.token.isNotEmpty) {
        futures.add(
          http.get(
            Uri.parse(ApiConstants.notifications),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          ),
        );
      }
      final results = await Future.wait(futures);
      if (results[0].statusCode == 200) {
        setState(() => _retardsPannes = jsonDecode(results[0].body));
      }
      if (futures.length > 1 && results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body);
        setState(() {
          _notifications = data['notifications'] ?? [];
          _nonLues = data['nonLues'] ?? 0;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final retards = (_retardsPannes['retards'] as List?) ?? [];
    final pannes = (_retardsPannes['pannes'] as List?) ?? [];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded,
                    color: DarkNeonTheme.primaryCyan, size: 24),
                const SizedBox(width: 10),
                const Text('Alertes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _load),
              ],
            ),
          ),

          // Segmented Tab Bar (Notifications vs Incidents)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.primaryBlue,
              opacity: 0.3,
              borderRadius: 16,
              fillColor: DarkNeonTheme.cardBgDark,
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: DarkNeonTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: DarkNeonTheme.primaryBlue.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications, size: 16),
                      SizedBox(width: 6),
                      Text('Notifications', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Incidents (${retards.length + pannes.length})',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: DarkNeonTheme.primaryCyan))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      // Notifications Tab View
                      _buildNotificationsView(),

                      // Incidents Tab View
                      _buildIncidentsView(retards, pannes),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsView() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DarkNeonTheme.primaryCyan.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DarkNeonTheme.primaryBlue.withOpacity(0.2),
                    border: Border.all(
                      color: DarkNeonTheme.primaryCyan.withOpacity(0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 42,
                    color: DarkNeonTheme.primaryCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune notification',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas encore de notifications\npour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (_, i) {
        final n = _notifications[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: DarkNeonTheme.glowBoxDecoration(
            borderColor: DarkNeonTheme.primaryCyan,
            opacity: 0.3,
            borderRadius: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n['titre'] ?? 'Notification',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                n['message'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncidentsView(List retards, List pannes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Retards
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded,
                  color: DarkNeonTheme.warningAmber, size: 18),
              const SizedBox(width: 8),
              const Text('Retards',
                  style: TextStyle(
                      color: DarkNeonTheme.warningAmber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DarkNeonTheme.warningAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${retards.length}',
                    style: const TextStyle(
                        color: DarkNeonTheme.warningAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.warningAmber,
              opacity: 0.3,
              borderRadius: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DarkNeonTheme.warningAmber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: DarkNeonTheme.warningAmber, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aucun retard en cours',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Tout fonctionne normalement.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white38, size: 14),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Pannes
          Row(
            children: [
              const Icon(Icons.build_circle_rounded,
                  color: DarkNeonTheme.accentPink, size: 18),
              const SizedBox(width: 8),
              const Text('Pannes',
                  style: TextStyle(
                      color: DarkNeonTheme.accentPink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DarkNeonTheme.accentPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${pannes.length}',
                    style: const TextStyle(
                        color: DarkNeonTheme.accentPink,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.accentPink,
              opacity: 0.3,
              borderRadius: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DarkNeonTheme.accentPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build_rounded,
                      color: DarkNeonTheme.accentPink, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aucune panne en cours',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Tous les bus sont opérationnels.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white38, size: 14),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Informations générales
          Row(
            children: [
              const Icon(Icons.campaign_rounded,
                  color: DarkNeonTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              const Text('Informations générales',
                  style: TextStyle(
                      color: DarkNeonTheme.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.primaryBlue,
              opacity: 0.3,
              borderRadius: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DarkNeonTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_rounded,
                      color: DarkNeonTheme.primaryCyan, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aucune information',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Pas de message en ce moment.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white38, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 5. ÉVALUER UNE LIGNE PAGE (_EvaluationPage - Matches Screenshot 5)
/// ============================================================================
class _EvaluationPage extends StatefulWidget {
  final String token;
  const _EvaluationPage({required this.token});

  @override
  State<_EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<_EvaluationPage> {
  List<dynamic> _lignes = [];
  List<dynamic> _lignesFiltrees = [];
  Map<String, dynamic>? _selectedLigneMap;
  int _note = 0;

  final _searchLigneCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  final _signalerCtrl = TextEditingController();

  bool _isSendingFeedback = false;
  bool _isSendingSignalement = false;

  @override
  void initState() {
    super.initState();
    _loadLignes();
    _searchLigneCtrl.addListener(_filtrerLignes);
  }

  @override
  void dispose() {
    _searchLigneCtrl.removeListener(_filtrerLignes);
    _searchLigneCtrl.dispose();
    _feedbackCtrl.dispose();
    _signalerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLignes() async {
    try {
      final r = await http.get(Uri.parse(ApiConstants.lignes));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _lignes = jsonDecode(r.body);
          _lignesFiltrees = List.from(_lignes);
        });
      }
    } catch (_) {}
  }

  void _filtrerLignes() {
    final q = _searchLigneCtrl.text.trim().toLowerCase();
    setState(() {
      _lignesFiltrees = q.isEmpty
          ? List.from(_lignes)
          : _lignes.where((l) {
              final num = (l['numero'] ?? '').toString().toLowerCase();
              final nom = (l['nom'] ?? '').toString().toLowerCase();
              return num.contains(q) || nom.contains(q);
            }).toList();
    });
  }

  Future<void> _sendFeedback() async {
    if (_feedbackCtrl.text.trim().isEmpty) {
      _showSnack('Écrivez votre suggestion', false);
      return;
    }
    setState(() => _isSendingFeedback = true);
    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.passager}/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'contenu': _feedbackCtrl.text.trim()}),
      );
      if (mounted) {
        _showSnack(
          r.statusCode == 201 ? 'Feedback envoyé, merci !' : 'Erreur d\'envoi',
          r.statusCode == 201,
        );
        if (r.statusCode == 201) _feedbackCtrl.clear();
      }
    } catch (_) {
      if (mounted) _showSnack('Erreur de connexion', false);
    }
    if (mounted) setState(() => _isSendingFeedback = false);
  }

  Future<void> _sendSignalement() async {
    if (_signalerCtrl.text.trim().isEmpty) {
      _showSnack('Décrivez le problème', false);
      return;
    }
    setState(() => _isSendingSignalement = true);
    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.passager}/signaler-probleme'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'type': 'autre',
          'description': _signalerCtrl.text.trim(),
        }),
      );
      if (mounted) {
        final msg = jsonDecode(r.body)['message'] ?? 'Signalement envoyé';
        _showSnack(msg, r.statusCode == 201);
        if (r.statusCode == 201) _signalerCtrl.clear();
      }
    } catch (_) {
      if (mounted) _showSnack('Erreur de connexion', false);
    }
    if (mounted) setState(() => _isSendingSignalement = false);
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Bus Illustration at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 250,
            child: Opacity(
              opacity: 0.75,
              child: Image.asset(
                'assets/images/bus_bottom_illustration.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // Content Layer
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Header Card
                const _HeaderBannerWidget(
                  title: 'Évaluer une ligne',
                  subtitle:
                      'Votre avis nous aide à améliorer le service de transport',
                  badgeText: '4.8',
                ),
                const SizedBox(height: 14),

                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: DarkNeonTheme.glowBoxDecoration(
                    borderColor: DarkNeonTheme.primaryBlue,
                    opacity: 0.3,
                    borderRadius: 14,
                  ),
                  child: TextField(
                    controller: _searchLigneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ligne...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search,
                          color: DarkNeonTheme.primaryCyan),
                      suffixIcon: _searchLigneCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white38, size: 18),
                              onPressed: () {
                                _searchLigneCtrl.clear();
                                setState(() => _selectedLigneMap = null);
                              },
                            )
                          : const Icon(Icons.tune_rounded,
                              color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Dropdown Suggestions when searching
                if (_searchLigneCtrl.text.isNotEmpty &&
                    _selectedLigneMap == null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: DarkNeonTheme.glowBoxDecoration(
                      borderColor: DarkNeonTheme.primaryCyan,
                      opacity: 0.4,
                      borderRadius: 14,
                    ),
                    child: _lignesFiltrees.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Aucune ligne disponible',
                                style: TextStyle(color: Colors.white38)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _lignesFiltrees.length,
                            itemBuilder: (_, i) {
                              final l = _lignesFiltrees[i];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DarkNeonTheme.primaryBlue
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l['numero'] ?? 'L${i + 1}',
                                    style: const TextStyle(
                                      color: DarkNeonTheme.primaryCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(l['nom'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                                onTap: () {
                                  setState(() {
                                    _selectedLigneMap = l;
                                    _searchLigneCtrl.text =
                                        '${l['numero']} — ${l['nom']}';
                                  });
                                },
                              );
                            },
                          ),
                  ),

                if (_selectedLigneMap != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DarkNeonTheme.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: DarkNeonTheme.primaryCyan.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: DarkNeonTheme.primaryCyan, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Ligne sélectionnée: ${_selectedLigneMap!['numero']}',
                          style: const TextStyle(
                              color: DarkNeonTheme.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedLigneMap = null;
                            _searchLigneCtrl.clear();
                          }),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white54, size: 18),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Note Stars
                const Text('Note :',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _note = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          i < _note
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: DarkNeonTheme.warningAmber,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Feedback Card (Cyan Glow)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: DarkNeonTheme.glowBoxDecoration(
                    borderColor: DarkNeonTheme.primaryCyan,
                    opacity: 0.4,
                    borderRadius: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: DarkNeonTheme.primaryCyan, size: 20),
                          SizedBox(width: 10),
                          Text('Feedback / Suggestion',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Suggestions pour améliorer le service',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DarkNeonTheme.cardBgDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _feedbackCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Votre suggestion ou remarque...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                DarkNeonTheme.primaryBlue,
                                DarkNeonTheme.accentPurple
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSendingFeedback ? null : _sendFeedback,
                            icon: _isSendingFeedback
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 16),
                            label: const Text('Envoyer feedback',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Signaler un problème Card (Amber Glow)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: DarkNeonTheme.glowBoxDecoration(
                    borderColor: DarkNeonTheme.warningAmber,
                    opacity: 0.4,
                    borderRadius: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_problem_outlined,
                              color: DarkNeonTheme.warningAmber, size: 20),
                          SizedBox(width: 10),
                          Text('Signaler un problème',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Retard, panne, comportement, propreté...',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DarkNeonTheme.cardBgDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _signalerCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Décrivez le problème...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                DarkNeonTheme.warningAmber,
                                Color(0xFFFF8F00),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSendingSignalement ? null : _sendSignalement,
                            icon: _isSendingSignalement
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 16),
                            label: const Text('Envoyer le signalement',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ACCUEIL HELPER WIDGETS
/// ============================================================================
class _AccueilHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAssistantTap;
  const _AccueilHeader({required this.user, required this.onAssistantTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bonjour 👋',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (user?.email ?? user?.tel ?? 'Passager').split('@').first,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'Prêt à prendre la route ?',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAssistantTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: DarkNeonTheme.glowBoxDecoration(
              borderColor: DarkNeonTheme.accentPurple,
              opacity: 0.4,
              borderRadius: 30,
              fillColor: const Color(0xFF1A1A2E),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_alt,
                  color: DarkNeonTheme.accentPurple,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Assistant IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LigneSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  const _LigneSearchBar({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DarkNeonTheme.glowBoxDecoration(
        borderColor: DarkNeonTheme.primaryBlue,
        opacity: 0.3,
        borderRadius: 16,
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Rechercher une ligne...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon:
              const Icon(Icons.search, color: DarkNeonTheme.primaryCyan),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  final VoidCallback onOpenFullMap;
  const _MapPreviewCard({required this.onOpenFullMap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 232,
        decoration: DarkNeonTheme.glowBoxDecoration(
          borderColor: DarkNeonTheme.primaryBlue,
          opacity: 0.35,
          borderRadius: 24,
        ),
        child: Stack(
          children: [
            // Map Layer
            Positioned(
              right: -40,
              top: -20,
              bottom: -20,
              width: 280,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(36.7538, 3.0588),
                  initialZoom: 13,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.transportdz.app',
                  ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(36.7538, 3.0588),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.directions_bus_rounded,
                            color: DarkNeonTheme.primaryCyan, size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      DarkNeonTheme.cardBg,
                      DarkNeonTheme.cardBg.withOpacity(0.9),
                      DarkNeonTheme.cardBg.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // Text Content
            Positioned(
              left: 20,
              top: 20,
              right: 100,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DarkNeonTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: DarkNeonTheme.successGreen.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: DarkNeonTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'EN DIRECT',
                          style: TextStyle(
                            color: DarkNeonTheme.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Suivre les bus en direct',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Localisez les bus en temps réel et restez informé.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onOpenFullMap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DarkNeonTheme.primaryBlue,
                            DarkNeonTheme.primaryCyan
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: DarkNeonTheme.primaryBlue.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Voir sur la carte',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String index;
  final String title;
  const _SectionLabel({required this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          index,
          style: TextStyle(
            color: DarkNeonTheme.primaryCyan.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onSuivreBus;
  final VoidCallback onReserver;
  final VoidCallback onMesReservations;
  final VoidCallback onRetards;
  final VoidCallback onEvaluer;
  final VoidCallback onAssistantIA;

  const _QuickActionsGrid({
    required this.onSuivreBus,
    required this.onReserver,
    required this.onMesReservations,
    required this.onRetards,
    required this.onEvaluer,
    required this.onAssistantIA,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BentoTile(
          icon: Icons.confirmation_number_rounded,
          label: 'Réserver une place',
          subtitle: 'Gérez les réservations des passagers',
          color: DarkNeonTheme.accentPurple,
          height: 90,
          isWide: true,
          onTap: onReserver,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.directions_bus_filled_rounded,
                label: 'Suivre les bus',
                subtitle: 'Localisation en temps réel',
                color: DarkNeonTheme.primaryBlue,
                height: 135,
                onTap: onSuivreBus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoTile(
                icon: Icons.confirmation_num_outlined,
                label: 'Mes billets',
                subtitle: 'Voir et valider les billets',
                color: DarkNeonTheme.successGreen,
                height: 135,
                onTap: onMesReservations,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.warning_amber_rounded,
                label: 'Retards & Pannes',
                subtitle: 'Déclarez et consultez',
                color: DarkNeonTheme.warningAmber,
                height: 135,
                onTap: onRetards,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoTile(
                icon: Icons.star_rounded,
                label: 'Évaluer une ligne',
                subtitle: 'Donnez votre avis',
                color: DarkNeonTheme.accentPink,
                height: 135,
                onTap: onEvaluer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BentoTile(
          icon: Icons.smart_toy_outlined,
          label: 'Assistant IA',
          subtitle: 'Votre assistant intelligent',
          color: DarkNeonTheme.accentPurple,
          height: 90,
          isWide: true,
          onTap: onAssistantIA,
        ),
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final double height;
  final bool isWide;
  final VoidCallback onTap;

  const _BentoTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.height,
    this.isWide = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DarkNeonTheme.glowBoxDecoration(
        borderColor: color,
        opacity: 0.3,
        borderRadius: 20,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: color.withOpacity(0.7), size: 16),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.5)),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: color.withOpacity(0.6), size: 14),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// BOTTOM NAVIGATION BAR WITH GLOWING INDICATOR
/// ============================================================================
class _NotifBadgeNav extends StatefulWidget {
  final int selectedIndex;
  final String token;
  final void Function(int) onTap;

  const _NotifBadgeNav({
    required this.selectedIndex,
    required this.token,
    required this.onTap,
  });

  @override
  State<_NotifBadgeNav> createState() => _NotifBadgeNavState();
}

class _NotifBadgeNavState extends State<_NotifBadgeNav> {
  int _nonLues = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_NotifBadgeNav old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) _load();
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) return;
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.notifications),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _nonLues = data['nonLues'] ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Accueil'},
      {'icon': Icons.search_rounded, 'label': 'Réserver'},
      {'icon': Icons.confirmation_number_rounded, 'label': 'Mes billets'},
      {'icon': Icons.notifications_rounded, 'label': 'Alertes'},
      {'icon': Icons.star_rounded, 'label': 'Évaluer'},
      {'icon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: DarkNeonTheme.cardBgDark,
        border: Border(
          top: BorderSide(
            color: DarkNeonTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isSelected = widget.selectedIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => widget.onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    width: isSelected ? 24 : 0,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: DarkNeonTheme.primaryCyan,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    DarkNeonTheme.primaryCyan.withOpacity(0.8),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isSelected
                            ? DarkNeonTheme.primaryCyan
                            : DarkNeonTheme.textMuted,
                        size: 22,
                      ),
                      if (i == 3 && _nonLues > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: DarkNeonTheme.accentPink,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_nonLues',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? DarkNeonTheme.primaryCyan
                          : DarkNeonTheme.textMuted,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
