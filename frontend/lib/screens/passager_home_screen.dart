import 'package:TransportDZ/screens/chatbot_screen.dart';
import 'package:TransportDZ/screens/position_vehicules_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';

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
          backgroundColor: AppTheme.background,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildAccueil(),
              _buildReservation(),
              _buildMesReservations(),
              _AlertesPage(token: _token),
              _buildEvaluation(),
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
            const SizedBox(height: 26),
            _LigneSearchBar(
              controller: _ligneSearchCtrl,
              onSubmitted: _lancerRechercheLigne,
            ),
            const SizedBox(height: 18),
            _MapPreviewCard(
              onOpenFullMap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SuivreBusPage(token: _token)),
              ),
            ),
            const SizedBox(height: 30),
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

  Widget _buildReservation() =>
      _TrajetsPage(token: _token, initialSearch: _pendingLigneSearch);
  Widget _buildMesReservations() => _MesReservationsPage(token: _token);
  Widget _buildEvaluation() => _EvaluationPage(token: _token);

  Widget _buildProfil() {
    final user = context.watch<AuthProvider>().user;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.person, size: 50, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? user?.tel ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PASSAGER',
                style: TextStyle(
                    color: AppTheme.secondary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => _showModifierCompteDialog(),
              child: _profilItem(
                  Icons.edit_outlined, 'Modifier compte', Colors.blue),
            ),
            const SizedBox(height: 10),
            _profilItem(Icons.notifications_outlined, 'Notifications',
                AppTheme.warning),
            const SizedBox(height: 10),
            _profilItem(Icons.delete_outline, 'Supprimer compte', Colors.red),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilItem(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  Future<void> _showModifierCompteDialog() async {
    final screenContext = context;
    final user = context.read<AuthProvider>().user;

    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final telCtrl = TextEditingController(text: user?.tel ?? '');
    final mdpActuelCtrl = TextEditingController();
    final nouveauMdpCtrl = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 22),
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
                _field(telCtrl, 'Téléphone', Icons.phone, TextInputType.phone),
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

                      final body = {
                        'email': emailCtrl.text.trim(),
                        'tel': telCtrl.text.trim(),
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
                        setS(() => isLoading = false);

                        final responseData = jsonDecode(r.body);
                        final msg = responseData['message'] ?? 'Erreur';

                        if (r.statusCode == 200) {
                          final newToken = responseData['token'] as String?;

                          if (newToken != null) {
                            await context.read<AuthProvider>().updateUser(
                                  email: emailCtrl.text.trim(),
                                  tel: telCtrl.text.trim(),
                                  token: newToken,
                                );
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          _PassagerHomeScreenState
                              .scaffoldMessengerKey.currentState
                              ?.showSnackBar(
                            const SnackBar(
                              content: Text('Compte modifié avec succès'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setS(() => isLoading = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: \$e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
        ),
      ),
    );

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
        prefixIcon: Icon(icon, color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}

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
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(30),
              border:
                  Border.all(color: const Color(0xFF7b61ff).withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_alt,
                  color: const Color(0xFF7B61FF),
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
      height: 58,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Rechercher une ligne ou station...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: AppTheme.primary),
            onPressed: () => onSubmitted(controller.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
        height: 232, // زِدنا شوية باش ما يبقاش overflow
        decoration: BoxDecoration(
          color: const Color(0xFF0f1729),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Stack(
          children: [
            // === الخريطة ===
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
                    // ⬇️ بدّلنا لمزود CartoDB (مجاني + تصميم داكن يناسب التطبيق)
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    // ⬇️ ضروري باش ما يحظركش الخادم
                    userAgentPackageName: 'com.transportdz.app',
                  ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(36.7538, 3.0588),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.directions_bus_rounded,
                            color: Color(0xFF4facfe), size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // === التدرّج اللوني من اليسار ===
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0f1729),
                      const Color(0xFF0f1729).withOpacity(0.9),
                      const Color(0xFF0f1729).withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // === المحتوى النصي ===
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
                      color: const Color(0xFF00c853).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00c853).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00c853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'EN DIRECT',
                          style: TextStyle(
                            color: Color(0xFF00c853),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Localisez les bus en temps réel et restez informé.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
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
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4facfe).withOpacity(0.3),
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

            // === أيقونة التكبير ===
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fullscreen,
                    color: Colors.white54, size: 20),
              ),
            ),

            // === InkWell للنقر ===
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onOpenFullMap,
                ),
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
            color: AppTheme.primary.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.08)),
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
          color: const Color(0xFF7b61ff),
          height: 90,
          isWide: true,
          onTap: onReserver,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.directions_bus_filled_rounded,
                label: 'Suivre les bus',
                subtitle: 'Localisation en temps réel',
                color: const Color(0xFF4facfe),
                height: 140,
                onTap: onSuivreBus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoTile(
                icon: Icons.confirmation_num_outlined,
                label: 'Mes billets',
                subtitle: 'Voir et valider les billets',
                color: const Color(0xFF00c2a8),
                height: 140,
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
                color: const Color(0xFFf59e0b),
                height: 140,
                onTap: onRetards,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoTile(
                icon: Icons.star_rounded,
                label: 'Évaluer une ligne',
                subtitle: 'Donnez votre avis',
                color: const Color(0xFFb06af0),
                height: 140,
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
          color: const Color(0xFF7b61ff),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151b2b),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: isWide
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
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
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white24, size: 16),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white24, size: 16),
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
    );
  }
}

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
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      onTap: widget.onTap,
      backgroundColor: AppTheme.surface,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Accueil'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'Réserver'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number), label: 'Mes billets'),
        BottomNavigationBarItem(
          label: 'Alertes',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.warning_amber),
              if (_nonLues > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$_nonLues',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.star_outline), label: 'Évaluer'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}

class _TrajetsPage extends StatefulWidget {
  final String token;
  final String? initialSearch;
  const _TrajetsPage({required this.token, this.initialSearch});
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
  int _etape = 0;
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
                          style: const TextStyle(fontSize: 14))),
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
          });
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
    return h.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.confirmation_number, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Réserver un trajet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stepCircle(1, 'Ligne', _etape >= 0),
                    _stepLine(_etape >= 1),
                    _stepCircle(2, 'Horaire', _etape >= 1),
                    _stepLine(_etape >= 2),
                    _stepCircle(3, 'Confirmer', _etape >= 2),
                  ],
                ),
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
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Sélectionner une ligne',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher (ex: Mila, Constantine...)',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.primary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white38, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingLignes
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : _lignesFiltrees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route_outlined,
                              size: 60, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            _searchCtrl.text.isEmpty
                                ? 'Aucune ligne disponible'
                                : 'Aucun résultat pour "${_searchCtrl.text}"',
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _lignesFiltrees.length,
                      itemBuilder: (_, i) {
                        final l = _lignesFiltrees[i];
                        final moy =
                            double.tryParse(l['moyenne'].toString()) ?? 0;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _ligneSelectionnee = l;
                              _etape = 1;
                            });
                            _chargerHoraires();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(l['numero'] ?? '',
                                        style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l['nom'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (moy > 0) ...[
                                            Icon(Icons.star,
                                                color: AppTheme.warning,
                                                size: 13),
                                            const SizedBox(width: 3),
                                            Text('$moy',
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11)),
                                            const SizedBox(width: 8),
                                          ],
                                          if (l['heure_debut'] != null) ...[
                                            const Icon(Icons.access_time,
                                                color: Colors.white38,
                                                size: 12),
                                            const SizedBox(width: 3),
                                            Text(
                                                '${_formatHeure(l['heure_debut'])} → ${_formatHeure(l['heure_fin'])}',
                                                style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white24, size: 16),
                              ],
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
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1a3a5c), Color(0xFF1a4a3a)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _etape = 0;
                  _ligneSelectionnee = null;
                }),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white70, size: 18),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.directions_bus_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${_ligneSelectionnee!['numero']} — ${_ligneSelectionnee!['nom']}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
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
                  width: 56,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(joursAbrev[date.weekday - 1],
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${date.day}',
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Text(_formatDate(_dateSelectionnee),
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: _loadingHoraires
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : _horaires.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 60, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('Aucun horaire disponible ce jour',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _horaires.length,
                      itemBuilder: (_, i) {
                        final h = _horaires[i];
                        final dispo = h['places_restantes'] as int? ?? 0;
                        final plein = dispo <= 0;
                        final couleur = dispo > 10
                            ? AppTheme.secondary
                            : dispo > 0
                                ? AppTheme.warning
                                : AppTheme.error;
                        return GestureDetector(
                          onTap: plein
                              ? null
                              : () {
                                  setState(() {
                                    _horaireSelectionne = h;
                                    _etape = 2;
                                  });
                                },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: couleur.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              _formatHeure(h['heure_depart']
                                                  ?.toString()),
                                              style: TextStyle(
                                                  color: plein
                                                      ? Colors.white38
                                                      : Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold)),
                                          const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              child: Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white38,
                                                  size: 16)),
                                          Text(
                                              _formatHeure(h['heure_arrivee']
                                                  ?.toString()),
                                              style: TextStyle(
                                                  color: plein
                                                      ? Colors.white38
                                                      : Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: Text(
                                                _ligneSelectionnee!['numero'] ??
                                                    '',
                                                style: const TextStyle(
                                                    color: AppTheme.primary,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          if (h['heure_depart'] != null &&
                                              h['heure_arrivee'] != null)
                                            Text(
                                                _duree(
                                                    h['heure_depart']
                                                        .toString(),
                                                    h['heure_arrivee']
                                                        .toString()),
                                                style: const TextStyle(
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
                                    plein
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: AppTheme.error
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: const Text('Complet',
                                                style: TextStyle(
                                                    color: AppTheme.error,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color:
                                                    couleur.withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Row(
                                              children: [
                                                Icon(Icons.event_seat,
                                                    color: couleur, size: 14),
                                                const SizedBox(width: 4),
                                                Text('dispo $dispo',
                                                    style: TextStyle(
                                                        color: couleur,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                    const SizedBox(height: 6),
                                    if (!plein)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: const Text('Choisir',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _duree(String debut, String fin) {
    try {
      final d = debut.split(':');
      final f = fin.split(':');
      final minDebut = int.parse(d[0]) * 60 + int.parse(d[1]);
      var minFin = int.parse(f[0]) * 60 + int.parse(f[1]);
      if (minFin < minDebut) minFin += 24 * 60;
      final diff = minFin - minDebut;
      final h = diff ~/ 60;
      final m = diff % 60;
      return h > 0 ? '~${h}h${m > 0 ? '${m}min' : ''}' : '~${m}min';
    } catch (_) {
      return '';
    }
  }

  Widget _buildEtape3() {
    return StatefulBuilder(
      builder: (ctx, setS) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _etape = 1),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  const Text('Modifier le trajet',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1a3a5c), Color(0xFF0d2a1a)]),
                borderRadius: BorderRadius.circular(16),
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
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_ligneSelectionnee!['numero'] ?? '',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text(_formatDate(_dateSelectionnee),
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                              _formatHeure(_horaireSelectionne!['heure_depart']
                                  ?.toString()),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold)),
                          Text(_horaireSelectionne!['point_depart'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white38, size: 24),
                            Text(
                                _duree(
                                    _horaireSelectionne!['heure_depart']
                                        .toString(),
                                    _horaireSelectionne!['heure_arrivee']
                                        .toString()),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                              _formatHeure(_horaireSelectionne!['heure_arrivee']
                                  ?.toString()),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold)),
                          Text(_horaireSelectionne!['point_arrivee'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Nombre de places',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_nbPlaces > 1) setS(() => _nbPlaces--);
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.error, size: 36),
                  ),
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$_nbPlaces',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () {
                      final max =
                          _horaireSelectionne!['places_restantes'] as int? ?? 1;
                      if (_nbPlaces < max) setS(() => _nbPlaces++);
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppTheme.secondary, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                  'Max: ${_horaireSelectionne!['places_restantes'] ?? '?'} places disponibles',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _reserver(_horaireSelectionne!, _nbPlaces),
                icon:
                    const Icon(Icons.confirmation_number, color: Colors.white),
                label: const Text('Confirmer la réservation',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCircle(int num, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.background,
            shape: BoxShape.circle,
            border:
                Border.all(color: active ? AppTheme.primary : Colors.white24),
          ),
          child: Center(
            child: Text('$num',
                style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: active ? AppTheme.primary : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: active ? AppTheme.primary : Colors.white12,
      ),
    );
  }
}

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
          ? _all.where((r) => r['statut'] == 'active').toList()
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
    int nbPlaces = resa['nb_places'] as int;
    final placesDispoActuelle = (resa['places_dispo'] as int? ?? 0) + nbPlaces;

    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(resa['ligne_numero'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Modifier réservation',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
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
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.error, size: 32),
                  ),
                  Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$nbPlaces',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () {
                      if (nbPlaces < placesDispoActuelle)
                        setS(() => nbPlaces++);
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppTheme.secondary, size: 32),
                  ),
                ],
              ),
              Text('Max disponible: $placesDispoActuelle',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
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
        content: Text(jsonDecode(r.body)['message']),
        backgroundColor: r.statusCode == 200 ? Colors.green : Colors.red,
      ),
    );
    if (r.statusCode == 200) _load();
  }

  Future<void> _annuler(int id, String ligne) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la réservation ?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Vous allez annuler votre réservation pour la ligne $ligne.Cette action est irréversible.',
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
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
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
        content: Text(jsonDecode(r.body)['message']),
        backgroundColor: r.statusCode == 200 ? Colors.green : Colors.red,
      ),
    );
    if (r.statusCode == 200) _load();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _all.where((r) => r['statut'] == 'active').length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number,
                    color: AppTheme.secondary),
                const SizedBox(width: 8),
                const Text('Mes réservations',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$activeCount actives',
                        style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _load),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.secondary.withOpacity(0.25)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une ligne...',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.secondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _showActiveOnly
                          ? AppTheme.secondary.withOpacity(0.15)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _showActiveOnly
                              ? AppTheme.secondary.withOpacity(0.5)
                              : Colors.white12),
                    ),
                    child: Text(
                      _showActiveOnly ? 'Actives' : 'Toutes',
                      style: TextStyle(
                          color: _showActiveOnly
                              ? AppTheme.secondary
                              : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.secondary))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                size: 70, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'Aucun résultat pour "${_searchCtrl.text}"'
                                  : _showActiveOnly
                                      ? 'Aucune réservation active'
                                      : 'Aucune réservation',
                              style: const TextStyle(color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final r = _filtered[i];
                          final isActive = r['statut'] == 'active';
                          final color =
                              isActive ? AppTheme.secondary : Colors.red;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color.withOpacity(0.3)),
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
                                          color: AppTheme.primary
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(r['ligne_numero'] ?? '',
                                          style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(r['ligne_nom'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(
                                          (r['statut'] ?? '')
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.event_seat,
                                        size: 14, color: Colors.white38),
                                    const SizedBox(width: 6),
                                    Text('${r['nb_places']} place(s)',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                    if (r['heure_depart'] != null) ...[
                                      const SizedBox(width: 14),
                                      const Icon(Icons.access_time,
                                          size: 14, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                          (r['heure_depart'] as String)
                                              .substring(0, 5),
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                      const Text(' → ',
                                          style: TextStyle(
                                              color: Colors.white24,
                                              fontSize: 12)),
                                      Text(
                                          (r['heure_arrivee'] as String)
                                              .substring(0, 5),
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                    ],
                                  ],
                                ),
                                if (isActive) ...[
                                  const SizedBox(height: 12),
                                  const Divider(
                                      color: Colors.white10, height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _modifier(r),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 16,
                                              color: AppTheme.primary),
                                          label: const Text('Modifier',
                                              style: TextStyle(
                                                  color: AppTheme.primary,
                                                  fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: AppTheme.primary
                                                    .withOpacity(0.4)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _annuler(
                                              r['id'], r['ligne_numero'] ?? ''),
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 16,
                                              color: Colors.red),
                                          label: const Text('Annuler',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.red, width: 0.4),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
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
    );
  }
}

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
          _notifications = data['notifications'];
          _nonLues = data['nonLues'];
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _marquerLu(int id) async {
    await http.put(
      Uri.parse('${ApiConstants.notifications}/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    _load();
  }

  Future<void> _marquerTousLus() async {
    await http.put(
      Uri.parse('${ApiConstants.notifications}/all/lu'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final retards = (_retardsPannes['retards'] as List?) ?? [];
    final pannes = (_retardsPannes['pannes'] as List?) ?? [];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: AppTheme.warning, size: 22),
                const SizedBox(width: 8),
                const Text('Alertes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (_nonLues > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('$_nonLues',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                const Spacer(),
                if (_nonLues > 0)
                  GestureDetector(
                    onTap: _marquerTousLus,
                    child: const Text('Tout lire',
                        style:
                            TextStyle(color: AppTheme.primary, fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _load),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10)),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications, size: 16),
                      const SizedBox(width: 6),
                      const Text('Notifications'),
                      if (_nonLues > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber, size: 16),
                      const SizedBox(width: 6),
                      Text('Incidents (${retards.length + pannes.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      widget.token.isEmpty
                          ? const Center(
                              child: Text(
                                  'Connectez-vous pour voir vos notifications',
                                  style: TextStyle(color: Colors.white38),
                                  textAlign: TextAlign.center),
                            )
                          : _notifications.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_none,
                                          size: 70, color: Colors.white24),
                                      SizedBox(height: 16),
                                      Text('Aucune notification',
                                          style:
                                              TextStyle(color: Colors.white38)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _notifications.length,
                                  itemBuilder: (_, i) {
                                    final n = _notifications[i];
                                    final isLu = n['lu'] == true;
                                    final type = n['type'] ?? 'info';
                                    final color = type == 'retard'
                                        ? AppTheme.warning
                                        : type == 'panne'
                                            ? AppTheme.error
                                            : type == 'signalement'
                                                ? Colors.green
                                                : AppTheme.primary;
                                    return GestureDetector(
                                      onTap: () =>
                                          isLu ? null : _marquerLu(n['id']),
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: isLu
                                                  ? Colors.white12
                                                  : color.withOpacity(0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Stack(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(
                                                        isLu ? 0.08 : 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Icon(
                                                    type == 'retard'
                                                        ? Icons.access_time
                                                        : type == 'panne'
                                                            ? Icons.build
                                                            : type ==
                                                                    'signalement'
                                                                ? Icons
                                                                    .report_problem_outlined
                                                                : Icons
                                                                    .info_outline,
                                                    color: isLu
                                                        ? color.withOpacity(0.5)
                                                        : color,
                                                    size: 20,
                                                  ),
                                                ),
                                                if (!isLu)
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration:
                                                          const BoxDecoration(
                                                              color: Colors.red,
                                                              shape: BoxShape
                                                                  .circle),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    n['titre'] ?? '',
                                                    style: TextStyle(
                                                      color: isLu
                                                          ? Colors.white54
                                                          : Colors.white,
                                                      fontWeight: isLu
                                                          ? FontWeight.normal
                                                          : FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    n['message'] ?? '',
                                                    style: TextStyle(
                                                      color: isLu
                                                          ? Colors.white24
                                                          : Colors.white60,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    n['created_at']
                                                            ?.toString()
                                                            .substring(0, 16) ??
                                                        '',
                                                    style: const TextStyle(
                                                        color: Colors.white24,
                                                        fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Retards', Icons.access_time,
                                AppTheme.warning, retards.length),
                            ...retards.map(
                              (r) => _incidentCard(
                                r['ligne_numero'] != null
                                    ? 'Ligne ${r['ligne_numero']}'
                                    : 'Sans ligne',
                                '${r['conducteur_nom']} ${r['conducteur_prenom']}',
                                'Retard de ${r['duree_minutes']} min${r['motif'] != null && r['motif'].toString().isNotEmpty ? ' — ${r['motif']}' : ''}',
                                AppTheme.warning,
                                Icons.access_time,
                              ),
                            ),
                            if (retards.isEmpty)
                              _emptyChip(
                                  'Aucun retard en cours', AppTheme.warning),
                            const SizedBox(height: 16),
                            _sectionHeader('Pannes', Icons.build,
                                AppTheme.error, pannes.length),
                            ...pannes.map(
                              (p) => _incidentCard(
                                p['ligne_numero'] != null
                                    ? 'Ligne ${p['ligne_numero']}'
                                    : 'Sans ligne',
                                '${p['conducteur_nom']} ${p['conducteur_prenom']}',
                                p['description'] ?? '',
                                AppTheme.error,
                                Icons.build,
                              ),
                            ),
                            if (pannes.isEmpty)
                              _emptyChip(
                                  'Aucune panne en cours', AppTheme.error),
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

  Widget _sectionHeader(String label, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(String ligne, String conducteur, String detail,
      Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ligne,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(conducteur,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(detail,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChip(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 14),
          const SizedBox(width: 8),
          Text(msg,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

class _EvaluationPage extends StatefulWidget {
  final String token;
  const _EvaluationPage({required this.token});
  @override
  State<_EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<_EvaluationPage> {
  List<dynamic> _lignes = [];
  List<dynamic> _lignesFiltrees = [];
  List<dynamic> _evaluations = [];
  int? _selectedLigne;
  int _note = 0;
  final _commentCtrl = TextEditingController();
  final _searchLigneCtrl = TextEditingController();
  bool _isLoading = false;
  String _dernierQuery = '';
  bool _selectionEnCours = false;

  Widget _buildLoginRequired() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_outlined, color: AppTheme.warning, size: 16),
          SizedBox(width: 8),
          Text("S'inscrire pour accéder",
              style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchLigneCtrl.addListener(_filtrerLignes);
    _loadData();
  }

  void _filtrerLignes() {
    final q = _searchLigneCtrl.text.trim().toLowerCase();
    if (_selectionEnCours) return;
    if (_dernierQuery == q) return;
    _dernierQuery = q;
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

  @override
  void dispose() {
    _searchLigneCtrl.removeListener(_filtrerLignes);
    _searchLigneCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final r1 = await http.get(Uri.parse(ApiConstants.lignes));
      final r2 =
          await http.get(Uri.parse('${ApiConstants.passager}/evaluations'));
      setState(() {
        if (r1.statusCode == 200) {
          _lignes = jsonDecode(r1.body);
          _lignesFiltrees = List.from(_lignes);
        }
        if (r2.statusCode == 200) _evaluations = jsonDecode(r2.body);
      });
    } catch (e) {
      print('Erreur _loadData: $e');
    }
  }

  Future<void> _envoyer() async {
    if (_selectedLigne == null || _note == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choisissez une ligne et donnez une note'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connectez-vous pour évaluer'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    final r = await http.post(
      Uri.parse('${ApiConstants.passager}/evaluer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
      },
      body: jsonEncode({'ligne_id': _selectedLigne, 'note': _note}),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(jsonDecode(r.body)['message']),
        backgroundColor: r.statusCode == 201 ? Colors.green : Colors.red,
      ),
    );
    if (r.statusCode == 201) {
      setState(() {
        _selectedLigne = null;
        _note = 0;
        _searchLigneCtrl.clear();
        _dernierQuery = '';
      });
      _commentCtrl.clear();
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: AppTheme.warning),
                SizedBox(width: 8),
                Text('Évaluer une ligne',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchLigneCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une ligne...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_searchLigneCtrl.text.isNotEmpty && _selectedLigne == null)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: _lignesFiltrees.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
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
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(l['numero'] ?? '',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                            title: Text(l['nom'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            onTap: () {
                              _selectionEnCours = true;
                              final ligneNom =
                                  '${l['numero']} — ${l['nom'] ?? ''}';
                              setState(() {
                                _selectedLigne = l['id'];
                                _searchLigneCtrl.text = ligneNom;
                                _lignesFiltrees = [];
                                _dernierQuery = ligneNom.toLowerCase();
                              });
                              Future.microtask(() {
                                _selectionEnCours = false;
                              });
                            },
                          );
                        },
                      ),
              ),
            if (_selectedLigne != null)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    const Text('Ligne sélectionnée',
                        style:
                            TextStyle(color: AppTheme.primary, fontSize: 12)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedLigne = null;
                        _searchLigneCtrl.clear();
                        _dernierQuery = '';
                        _lignesFiltrees = List.from(_lignes);
                      }),
                      child: const Icon(Icons.close,
                          color: Colors.white38, size: 16),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('Note :', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () async {
                    setState(() => _note = i + 1);
                    if (_selectedLigne == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Choisissez d\'abord une ligne'),
                            backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    await _envoyer();
                  },
                  child: Icon(i < _note ? Icons.star : Icons.star_border,
                      color: AppTheme.warning, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.feedback_outlined,
                        color: AppTheme.secondary, size: 18),
                    SizedBox(width: 8),
                    Text('Feedback / Suggestion',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Suggestions pour améliorer le service',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 14),
                  widget.token.isNotEmpty
                      ? _FeedbackForm(token: widget.token)
                      : _buildLoginRequired(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.report_problem_outlined,
                        color: AppTheme.warning, size: 18),
                    SizedBox(width: 8),
                    Text('Signaler un problème',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Retard, panne, comportement, propreté...',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 14),
                  widget.token.isNotEmpty
                      ? _SignalerProblemeForm(token: widget.token)
                      : _buildLoginRequired(),
                ],
              ),
            ),
            if (_evaluations.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Dernières évaluations',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._evaluations.take(5).map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.warning.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(e['ligne_numero'] ?? '',
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                      i < (e['note'] as int)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: AppTheme.warning,
                                      size: 14),
                                ),
                              ),
                            ],
                          ),
                          if (e['commentaire'] != null &&
                              e['commentaire'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(e['commentaire'],
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  final String token;
  const _FeedbackForm({required this.token});
  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Écrivez votre feedback'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final r = await http
          .post(
            Uri.parse('${ApiConstants.passager}/feedback'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({'contenu': _ctrl.text.trim()}),
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = r.statusCode == 201
          ? 'Feedback envoyé, merci !'
          : 'Erreur lors de l\'envoi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: r.statusCode == 201 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3)),
      );
      if (r.statusCode == 201) _ctrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connexion échouée'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Votre suggestion ou remarque...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _envoyer,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text('Envoyer feedback',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalerProblemeForm extends StatefulWidget {
  final String token;
  const _SignalerProblemeForm({required this.token});
  @override
  State<_SignalerProblemeForm> createState() => _SignalerProblemeFormState();
}

class _SignalerProblemeFormState extends State<_SignalerProblemeForm> {
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Décrivez le problème'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    final r = await http.post(
      Uri.parse('${ApiConstants.passager}/signaler-probleme'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
      },
      body: jsonEncode({'type': 'autre', 'description': _descCtrl.text.trim()}),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(jsonDecode(r.body)['message']),
        backgroundColor: r.statusCode == 201 ? Colors.green : Colors.red,
      ),
    );
    if (r.statusCode == 201) _descCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Décrivez le problème...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _envoyer,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text('Envoyer le signalement',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
