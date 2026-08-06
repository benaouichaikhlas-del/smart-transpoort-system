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

class _AvisRapportsScreenState extends State<AvisRapportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _evaluations = [];
  List<dynamic> _feedbacks = [];
  List<dynamic> _signalements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // ✅ دالة واحدة فقط
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Avis & Rapports',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 11),
          tabs: [
            Tab(
                icon: const Icon(Icons.star, size: 14),
                text: 'Évals (${_evaluations.length})'),
            Tab(
                icon: const Icon(Icons.feedback_outlined, size: 14),
                text: 'Feedbacks (${_feedbacks.length})'),
            Tab(
                icon: const Icon(Icons.report_problem_outlined, size: 14),
                text: 'Signals (${_signalements.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEvaluations(),
                _buildFeedbacks(),
                _buildSignalements(),
              ],
            ),
    );
  }

  // ═══ ÉVALUATIONS ═══
  Widget _buildEvaluations() {
    if (_evaluations.isEmpty) {
      return const Center(
        child:
            Text('Aucune évaluation', style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _evaluations.length,
      itemBuilder: (_, i) {
        final e = _evaluations[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                    (j) => Icon(
                      j < (e['note'] as int? ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: AppTheme.warning,
                      size: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Moy: ${e['moyenne_ligne']}⭐',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 11)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(e['passager_email'] ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              if (e['commentaire'] != null &&
                  e['commentaire'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(e['commentaire'],
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12)),
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
      return const Center(
        child: Text('Aucun feedback', style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _feedbacks.length,
      itemBuilder: (_, i) {
        final f = _feedbacks[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (f['ligne_numero'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(f['ligne_numero'],
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                const Spacer(),
                Text(f['passager_email'] ?? '',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              Text(f['contenu'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  // ═══ SIGNALEMENTS ═══
  Widget _buildSignalements() {
    if (_signalements.isEmpty) {
      return const Center(
        child:
            Text('Aucun signalement', style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _signalements.length,
      itemBuilder: (_, i) {
        final s = _signalements[i];
        final statut = s['statut'] ?? 'nouveau';
        final color = statut == 'resolu'
            ? Colors.green
            : statut == 'en_cours'
                ? Colors.blue
                : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (s['ligne_numero'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(s['ligne_numero'],
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statut.toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(s['passager_email'] ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 4),
              Text(s['description'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
