import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'register_visiteur_screen.dart';
import 'register_proprietaire_screen.dart';
import 'login_screen.dart';

// ══════════════════════════════════════════════════
// COULEURS — Palette nuit algérienne (match image)
// ══════════════════════════════════════════════════
const _bg = Color(0xFF0A0612);
const _surface = Color(0xFF13091F);
const _purple = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFAB73FA);
const _blue = Color(0xFF2563EB);
const _cyan = Color(0xFF06B6D4);
const _white = Colors.white;
const _white60 = Color(0x99FFFFFF);
const _white30 = Color(0x4DFFFFFF);

class RegisterChoiceScreen extends StatefulWidget {
  const RegisterChoiceScreen({super.key});

  @override
  State<RegisterChoiceScreen> createState() => _RegisterChoiceScreenState();
}

class _RegisterChoiceScreenState extends State<RegisterChoiceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _fade;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic),
    );

    _fade.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final l = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ═══════════════════════════════════════════════
              // 1) صورة الخلفية: الحافلة الجزائرية + الشهداء
              // ═══════════════════════════════════════════════
              Image.asset(
                'assets/images/transport_algerien_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A0F2E),
                          Color(0xFF2D1B4E),
                          Color(0xFF4A1C40),
                          Color(0xFF0D0D0D),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ═══════════════════════════════════════════════
              // 2) تدرج داكن قوي من الأسفل
              // ═══════════════════════════════════════════════
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.75),
                      _bg.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.35, 0.65, 0.92],
                  ),
                ),
              ),

              // ── particules lumineuses ──
              const Positioned.fill(child: _StarField()),

              // ── halo violet en haut ──
              Positioned(
                top: -100,
                left: -80,
                child: _Halo(
                  color: _purple.withOpacity(0.35),
                  size: 320,
                ),
              ),

              // ── halo bleu en bas à droite ──
              Positioned(
                bottom: -60,
                right: -60,
                child: _Halo(
                  color: _blue.withOpacity(0.25),
                  size: 260,
                ),
              ),

              // ═══════════════════════════════════════════════
              // 3) المحتوى
              // ═══════════════════════════════════════════════
              SafeArea(
                child: AnimatedBuilder(
                  animation: _fadeAnim,
                  builder: (_, child) => Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── AppBar ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            _GlassButton(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: _white, size: 18),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),

                              // ── Icône bus animée ──
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, child) => Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // anneau extérieur pulse
                                    Container(
                                      width: 120 + _pulse.value * 12,
                                      height: 120 + _pulse.value * 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _purple.withOpacity(
                                              0.3 - _pulse.value * 0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    // anneau dégradé violet → cyan
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const SweepGradient(
                                          colors: [
                                            _purple,
                                            _cyan,
                                            _purple,
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(2.5),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _bg,
                                        ),
                                        child: const Icon(
                                          Icons.directions_bus_rounded,
                                          color: _white,
                                          size: 42,
                                        ),
                                      ),
                                    ),
                                    // petits traits décoratifs
                                    Positioned(
                                      left: -18,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 2,
                                            color:
                                                _purpleLight.withOpacity(0.7),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            width: 3,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _cyan.withOpacity(0.9),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            width: 12,
                                            height: 2,
                                            color: _cyan.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ── Titre ──
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${l.bienvenue} ',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        foreground: Paint()
                                          ..shader = const LinearGradient(
                                            colors: [_purpleLight, _cyan],
                                          ).createShader(const Rect.fromLTWH(
                                              0, 0, 200, 40)),
                                      ),
                                    ),
                                    TextSpan(
                                      text: l.parmiNous,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: _white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                l.selectionnezProfil,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _white60,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // ── trait dégradé ──
                              Container(
                                width: 44,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [_purple, _blue],
                                  ),
                                ),
                              ),

                              // ── espace pour le visuel ──
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.16),

                              // ── Card Voyageur ──
                              _ProfileCard(
                                icon: Icons.person_outline,
                                label: l.visiteurPassager,
                                subtitle: l.reservezPlaces,
                                gradientColors: const [
                                  Color(0xFF7C3AED),
                                  Color(0xFF4F46E5),
                                ],
                                delay: 0,
                                onTap: () => Navigator.push(
                                  context,
                                  _fadeRoute(const RegisterVisiteurScreen()),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── séparateur "ou" ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            _white30,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(l.ou,
                                        style: const TextStyle(
                                            color: _white60, fontSize: 13)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _white30,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // ── Card Propriétaire ──
                              _ProfileCard(
                                icon: Icons.apartment_outlined,
                                label: l.proprietaire,
                                subtitle: l.gerezVehicules,
                                gradientColors: const [
                                  Color(0xFF0EA5E9),
                                  Color(0xFF2563EB),
                                ],
                                delay: 120,
                                onTap: () => Navigator.push(
                                  context,
                                  _fadeRoute(
                                      const RegisterProprietaireScreen()),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Déjà un compte ──
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  _fadeRoute(const LoginScreen()),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${l.dejaCompte} ',
                                          style: const TextStyle(
                                            color: _white60,
                                          ),
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                              colors: [_purpleLight, _cyan],
                                            ).createShader(bounds),
                                            child: Text(
                                              '${l.seConnecter} →',
                                              style: const TextStyle(
                                                color: _white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PageRoute _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }
}

// ══════════════════════════════════════════════════
// PROFILE CARD — Glassmorphism + Néon
// ══════════════════════════════════════════════════
class _ProfileCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final int delay;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _press.reverse();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _press.forward();
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () {
        _press.forward();
        setState(() => _isHovered = false);
      },
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: _press.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.60),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.gradientColors[0].withOpacity(0.9)
                  : widget.gradientColors[0].withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.gradientColors[0].withOpacity(0.35),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: widget.gradientColors[0].withOpacity(0.15),
                      blurRadius: 14,
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // motif décoratif
              Positioned(
                left: -4,
                bottom: -4,
                child: _DotGrid(color: widget.gradientColors[0]),
              ),
              Row(
                children: [
                  // icône dans cercle néon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.gradientColors[0].withOpacity(0.1),
                      border: Border.all(
                        color: widget.gradientColors[0].withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(widget.icon,
                        color: widget.gradientColors[0], size: 26),
                  ),

                  const SizedBox(width: 16),

                  // texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: _white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: _white60,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // flèche
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.gradientColors[0].withOpacity(0.6),
                        width: 1.4,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: _white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  final Color color;
  const _DotGrid({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 20,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(
          9,
          (_) => Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// GLASS BUTTON
// ══════════════════════════════════════════════════
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _white.withOpacity(0.08),
          border: Border.all(color: _purple.withOpacity(0.4)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// HALO
// ══════════════════════════════════════════════════
class _Halo extends StatelessWidget {
  final Color color;
  final double size;

  const _Halo({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color, blurRadius: size * 0.8, spreadRadius: size * 0.1)
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// STAR FIELD
// ══════════════════════════════════════════════════
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  static final List<Offset> _positions = List.generate(
    60,
    (i) {
      final r = math.Random(i * 137);
      return Offset(r.nextDouble(), r.nextDouble());
    },
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < _positions.length; i++) {
      final r = math.Random(i * 137);
      final radius = 0.5 + r.nextDouble() * 1.5;
      final opacity = 0.2 + r.nextDouble() * 0.5;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(
          _positions[i].dx * size.width,
          _positions[i].dy * size.height,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
