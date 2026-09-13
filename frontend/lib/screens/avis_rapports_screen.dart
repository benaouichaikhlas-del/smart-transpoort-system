import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class AvisRapportsScreen extends StatefulWidget {
  const AvisRapportsScreen({super.key});
  @override
  State<AvisRapportsScreen> createState() => _AvisRapportsScreenState();
}

class _AvisRapportsScreenState extends State<AvisRapportsScreen> {
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _card = Color(0xFF131324);
  static const Color _cardBorder = Color(0xFF2E2E52);

  int _tabIndex = 0;
  List<dynamic> _evaluations = [];
  List<dynamic> _feedbacks = [];
  List<dynamic> _signalements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().user!.token;
    final base = ApiConstants.proprietaire;

    final results = await Future.wait([
      _get('$base/evaluations', token),
      _get('$base/feedbacks', token),
      _get('$base/signalements', token),
    ]);

    if (!mounted) return;
    setState(() {
      _evaluations = results[0];
      _feedbacks = results[1];
      _signalements = results[2];
      _isLoading = false;
    });
  }

  Future<List<dynamic>> _get(String url, String token) async {
    try {
      final r = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B16),
      body: SafeArea(
        child: Column(
          children: [
            // ═══ Header ═══
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const BackButton(color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Avis & Rapports',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _loadAll,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // ═══ Onglets style maquette ═══
            _buildTabs(),
            const SizedBox(height: 4),
            // ═══ Contenu ═══
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _cyan))
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _tabIndex == 0
                          ? _buildEvaluations()
                          : _tabIndex == 1
                              ? _buildFeedbacks()
                              : _buildSignalements(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ Onglets (icône au-dessus, label en dessous, indicateur cyan) ═══
  Widget _buildTabs() {
    final tabs = [
      (icon: Icons.star_rounded, label: 'Évals', count: _evaluations.length),
      (
        icon: Icons.feedback_outlined,
        label: 'Feedbacks',
        count: _feedbacks.length
      ),
      (
        icon: Icons.warning_amber_rounded,
        label: 'Signals',
        count: _signalements.length
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder, width: 1)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tabIndex == i;
          final t = tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Column(children: [
                const SizedBox(height: 8),
                Icon(t.icon, size: 20, color: active ? _cyan : Colors.white38),
                const SizedBox(height: 5),
                Text('${t.label} (${t.count})',
                    style: TextStyle(
                        color: active ? _cyan : Colors.white38,
                        fontSize: 11.5,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500)),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 2.5,
                  width: active ? 46 : 0,
                  decoration: BoxDecoration(
                    color: _cyan,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: _cyan.withOpacity(0.6), blurRadius: 6)
                          ]
                        : null,
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ═══ ÉVALUATIONS ═══
  Widget _buildEvaluations() {
    if (_evaluations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fact_check_rounded,
        title: 'Aucune évaluation',
        subtitle: "Vous n'avez encore aucune\névaluation pour le moment.",
        color: _cyan,
      );
    }

    return ListView.builder(
      key: const ValueKey('evals'),
      padding: const EdgeInsets.all(16),
      itemCount: _evaluations.length,
      itemBuilder: (_, i) {
        final e = _evaluations[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.warning.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e['ligne_numero'] ?? '',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(
                    5,
                    (j) => Icon(
                      j < (e['note'] as int? ?? 0)
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Moy: ${e['moyenne_ligne']}⭐',
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(e['passager_email'] ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              if (e['commentaire'] != null &&
                  e['commentaire'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(e['commentaire'],
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══ FEEDBACKS ═══
  Widget _buildFeedbacks() {
    if (_feedbacks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.feedback_outlined,
        title: 'Aucun feedback',
        subtitle: 'Vous n\'avez encore aucun\nfeedback pour le moment.',
        color: AppTheme.secondary,
      );
    }

    return ListView.builder(
      key: const ValueKey('feedbacks'),
      padding: const EdgeInsets.all(16),
      itemCount: _feedbacks.length,
      itemBuilder: (_, i) {
        final f = _feedbacks[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Avatar personne
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFFA78BFA), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['passager_email'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Aujourd\'hui à ${_fmtHeure(f['created_at'])}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ]),
                ),
              ]),
              const SizedBox(height: 10),
              Text(f['contenu'] ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.45)),
            ],
          ),
        );
      },
    );
  }

  // ═══ SIGNALEMENTS ═══
  Widget _buildSignalements() {
    if (_signalements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.report_problem_outlined,
        title: 'Aucun signalement',
        subtitle: 'Vous n\'avez encore aucun\nsignalement pour le moment.',
        color: AppTheme.warning,
      );
    }

    return ListView.builder(
      key: const ValueKey('signals'),
      padding: const EdgeInsets.all(16),
      itemCount: _signalements.length,
      itemBuilder: (_, i) {
        final s = _signalements[i];
        final statut = s['statut'] ?? 'nouveau';
        final (Color, String, Color) badge = switch (statut) {
          'resolu' => (Colors.green, 'RÉSOLU', const Color(0xFFEF4444)),
          'en_cours' => (Colors.blue, 'EN COURS', const Color(0xFF8B5CF6)),
          _ => (const Color(0xFFF59E0B), 'NOUVEAU', const Color(0xFFF97316)),
        };
        final badgeColor = badge.$1;
        final badgeLabel = badge.$2;
        final avatarColor = badge.$3;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: avatarColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Avatar enveloppe colorée
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor.withOpacity(0.2),
                  child: Icon(Icons.mail_rounded, color: avatarColor, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['passager_email'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Aujourd\'hui à ${_fmtHeure(s['created_at'])}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badgeLabel,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(s['description'] ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.45)),
            ],
          ),
        );
      },
    );
  }

  // ═══ État vide ═══
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.02),
            ]),
          ),
          child: Icon(icon, size: 80, color: color.withOpacity(0.8)),
        ),
        const SizedBox(height: 26),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white54, fontSize: 14, height: 1.5)),
      ]),
    );
  }

  // Heure au format HH:mm depuis created_at
  String _fmtHeure(dynamic createdAt) {
    if (createdAt == null) return '--:--';
    final s = createdAt.toString();
    // Format ISO : 2026-09-05T12:45:00
    final match = RegExp(r'T(\d{2}:\d{2})').firstMatch(s);
    return match?.group(1) ?? '--:--';
  }
}
