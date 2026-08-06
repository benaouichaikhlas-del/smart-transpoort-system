import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import 'welcome_screen.dart';

// ══════════════════════════════════════════
// THEME COLORS (Modern Dark)
// ══════════════════════════════════════════
class _ModernColors {
  static const bg = Color(0xFF0B0E14);
  static const surface = Color(0xFF151922);
  static const surfaceLight = Color(0xFF1E2230);
  static const primary = Color(0xFF6366F1); // Indigo
  static const secondary = Color(0xFF10B981); // Emerald
  static const accent = Color(0xFF8B5CF6); // Violet
  static const warning = Color(0xFFF59E0B); // Amber
  static const danger = Color(0xFFEF4444); // Red
  static const text = Colors.white;
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF2A2F3D);
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _service = AdminService();
  int _currentIndex = 0;

  List<dynamic> _demandes = [];
  List<dynamic> _evaluations = [];
  List<dynamic> _feedbacks = [];
  List<dynamic> _signalements = [];
  List<dynamic> _permanences = [];
  List<dynamic> _lignes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  String get _token => context.read<AuthProvider>().user!.token;

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final token = _token;

    final results = await Future.wait([
      _service.getDemandes(token),
      _service.getEvaluations(token),
      _service.getFeedbacks(token),
      _service.getSignalements(token),
      _fetchPermanences(),
      _fetchLignes(),
    ]);

    if (!mounted) return;
    setState(() {
      _demandes = results[0];
      _evaluations = results[1];
      _feedbacks = results[2];
      _signalements = results[3];
      _permanences = results[4];
      _lignes = results[5];
      _isLoading = false;
    });
  }

  // ══════════════════════════════════════
  // API CALLS
  // ══════════════════════════════════════
  Future<List<dynamic>> _fetchPermanences() async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/permanences'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> _fetchLignes() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/ligne'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> _fetchConducteursLigne(int ligneId) async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/permanences/conducteurs/$ligneId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return [];
  }

  Future<void> _supprimerPermanence(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ModernAlertDialog(
        title: 'Supprimer cette permanence ?',
        confirmColor: _ModernColors.danger,
        confirmText: 'Supprimer',
      ),
    );
    if (confirmed != true) return;

    final r = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/permanences/$id'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (!mounted) return;
    _showSnackBar(
        jsonDecode(r.body)['message'] ?? 'Erreur', r.statusCode == 200);
    if (r.statusCode == 200) {
      final list = await _fetchPermanences();
      if (mounted) setState(() => _permanences = list);
    }
  }

  Future<bool> _updateNbBus(int ligneId, int newValue) async {
    try {
      final r = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/ligne/$ligneId/nb-bus'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({'nb_bus': newValue}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return false;
      if (r.statusCode == 200) {
        final list = await _fetchLignes();
        if (!mounted) return false;
        setState(() => _lignes = list);
        _showSnackBar('Mis à jour avec succès', true);
        return true;
      } else {
        _showSnackBar(
            'Erreur: ${jsonDecode(r.body)['message'] ?? r.statusCode}', false);
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      _showSnackBar('Erreur: $e', false);
      return false;
    }
  }

  void _showGererLignesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LignesBottomSheet(
        lignes: _lignes,
        onUpdate: _updateNbBus,
      ),
    );
  }

  void _showGenererRotationDialog() {
    final semCtrl = TextEditingController(text: '8');
    final debutCtrl = TextEditingController(text: '08:00');
    final finCtrl = TextEditingController(text: '16:00');
    int? ligneIdSelectionnee;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _ModernColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Générer Rotation Vendredi',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modernLabel('Ligne'),
                const SizedBox(height: 6),
                _modernDropdown(
                  value: ligneIdSelectionnee,
                  items: _lignes.map((l) {
                    final nbBus = (l['nb_bus'] ?? 1) as int;
                    return DropdownMenuItem<int>(
                      value: l['id'] as int,
                      child: Text(
                        '${l['numero']} — ${l['nom']} ($nbBus bus)',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setS(() => ligneIdSelectionnee = v),
                  hint: 'Sélectionner une ligne',
                ),
                const SizedBox(height: 14),
                _modernField(
                    semCtrl, 'Nombre de vendredis', TextInputType.number),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _modernField(
                          debutCtrl, 'Heure début', TextInputType.text)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _modernField(
                          finCtrl, 'Heure fin', TextInputType.text)),
                ]),
                if (ligneIdSelectionnee != null) ...[
                  const SizedBox(height: 14),
                  const Divider(color: _ModernColors.border),
                  const SizedBox(height: 8),
                  FutureBuilder<List<dynamic>>(
                    future: _fetchConducteursLigne(ligneIdSelectionnee!),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: _ModernColors.primary));
                      }
                      final nb = snap.data!.length;
                      final ligne = _lignes.firstWhere(
                          (l) => l['id'] == ligneIdSelectionnee,
                          orElse: () => {'nb_bus': 1});
                      final busParVendredi = (ligne['nb_bus'] ?? 1) as int;

                      if (nb == 0) {
                        return const Text(
                          '⚠️ Aucun conducteur affecté',
                          style: TextStyle(
                              color: _ModernColors.warning, fontSize: 12),
                        );
                      }
                      if (nb < busParVendredi) {
                        return Text(
                          '⚠️ Nécessite $busParVendredi bus mais $nb conducteur(s)',
                          style: const TextStyle(
                              color: _ModernColors.warning, fontSize: 12),
                        );
                      }

                      final nbVendredis = int.tryParse(semCtrl.text) ?? 8;
                      final totalPostes = nbVendredis * busParVendredi;
                      final toursComplets = totalPostes ~/ nb;
                      final reste = totalPostes % nb;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _ModernColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _ModernColors.primary.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(Icons.directions_bus,
                                '$busParVendredi bus/vendredi',
                                color: _ModernColors.secondary),
                            const SizedBox(height: 8),
                            _infoRow(Icons.group, '$nb conducteur(s)',
                                color: _ModernColors.primary),
                            const SizedBox(height: 8),
                            Text(
                              '$nbVendredis vendredis × $busParVendredi = $totalPostes postes ÷ $nb = $toursComplets tour(s)'
                              '${reste > 0 ? ' + $reste' : ''}',
                              style: const TextStyle(
                                  color: _ModernColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            const Text('Ordre:',
                                style: TextStyle(
                                    color: _ModernColors.textMuted,
                                    fontSize: 11)),
                            const SizedBox(height: 6),
                            ...snap.data!.asMap().entries.map((e) {
                              final c = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(children: [
                                  _numberBadge(e.key + 1),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${c['prenom'] ?? ''} ${c['nom'] ?? ''}',
                                    style: const TextStyle(
                                        color: _ModernColors.textMuted,
                                        fontSize: 12),
                                  ),
                                ]),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: _ModernColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: ligneIdSelectionnee == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _genererRotation(
                        ligneIdSelectionnee!,
                        int.tryParse(semCtrl.text) ?? 8,
                        debutCtrl.text,
                        finCtrl.text,
                      );
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _ModernColors.primary),
              child:
                  const Text('Générer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _genererRotation(
      int ligneId, int nbSemaines, String heureDebut, String heureFin) async {
    _showLoading();
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/permanences/rotation'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'ligne_id': ligneId,
        'nb_semaines': nbSemaines,
        'heure_debut': heureDebut,
        'heure_fin': heureFin,
      }),
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final msg = jsonDecode(r.body)['message'] ?? 'Erreur';
    _showSnackBar(msg, r.statusCode == 201);

    if (r.statusCode == 201) {
      final list = await _fetchPermanences();
      if (mounted) setState(() => _permanences = list);
    }
  }

  Future<void> _action(int id, bool accepter) async {
    final nom = _demandes.firstWhere((d) => d['id'] == id)['nom'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ModernAlertDialog(
        title: accepter ? 'Accepter $nom ?' : 'Refuser $nom ?',
        confirmColor: accepter ? _ModernColors.secondary : _ModernColors.danger,
        confirmText: accepter ? 'Accepter' : 'Refuser',
      ),
    );
    if (confirmed != true) return;

    _showLoading();
    final token = _token;
    final result = accepter
        ? await _service.accepter(token, id)
        : await _service.refuser(token, id);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _ModernColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              result['success'] ? Icons.check_circle : Icons.error,
              color: result['success']
                  ? _ModernColors.secondary
                  : _ModernColors.danger,
              size: 60,
            ),
            const SizedBox(height: 12),
            Text(result['message'],
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: result['success']
                    ? _ModernColors.secondary
                    : _ModernColors.danger,
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
    _loadAll();
  }

  Future<void> _changerStatut(int id, String statut) async {
    final nom = _demandes.firstWhere((d) => d['id'] == id)['nom'];
    final isReactivation = statut == 'accepte';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ModernAlertDialog(
        title: isReactivation ? 'Réactiver $nom ?' : 'Désactiver $nom ?',
        content: isReactivation
            ? 'Le compte sera réactivé.'
            : 'Le compte sera désactivé.',
        confirmColor:
            isReactivation ? _ModernColors.secondary : _ModernColors.danger,
        confirmText: isReactivation ? 'Réactiver' : 'Désactiver',
      ),
    );
    if (confirmed != true) return;

    _showLoading();
    final result = await _service.changerStatut(_token, id, statut);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    _showSnackBar(result['message'], result['success']);
    _loadAll();
  }

  Future<void> _supprimerDemande(int id) async {
    final nom = _demandes.firstWhere((d) => d['id'] == id)['nom'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ModernAlertDialog(
        title: 'Supprimer $nom ?',
        content: 'Cette action est irréversible.',
        confirmColor: _ModernColors.danger,
        confirmText: 'Supprimer',
      ),
    );
    if (confirmed != true) return;

    _showLoading();
    final result = await _service.supprimer(_token, id);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    _showSnackBar(result['message'], result['success']);
    _loadAll();
  }

  Future<void> _updateSignalementStatut(int id, String statut) async {
    _showLoading();
    await _service.updateStatutSignalement(_token, id, statut);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _showSnackBar('Statut mis à jour', true);
    _loadAll();
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: _ModernColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        content: Row(children: [
          CircularProgressIndicator(color: _ModernColors.primary),
          SizedBox(width: 20),
          Text('Traitement...', style: TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }

  void _showSnackBar(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? _ModernColors.secondary : _ModernColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final enAttente =
        _demandes.where((d) => d['statut'] == 'en_attente').length;
    final accepte = _demandes.where((d) => d['statut'] == 'accepte').length;
    final refuse = _demandes.where((d) => d['statut'] == 'refuse').length;

    final screens = [
      _DemandesTab(
        demandes: _demandes,
        enAttente: enAttente,
        accepte: accepte,
        refuse: refuse,
        onAction: _action,
        onChangeStatut: _changerStatut,
        onSupprimer: _supprimerDemande,
      ),
      _EvaluationsTab(evaluations: _evaluations),
      _RapportsTab(
        feedbacks: _feedbacks,
        signalements: _signalements,
        onUpdateStatut: _updateSignalementStatut,
      ),
      _PermanencesTab(
        permanences: _permanences,
        onSupprimer: _supprimerPermanence,
        onGenererRotation: _showGenererRotationDialog,
        onGererLignes: _showGererLignesBottomSheet,
      ),
    ];

    return Scaffold(
      backgroundColor: _ModernColors.bg,
      appBar: AppBar(
        backgroundColor: _ModernColors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Espace Admin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 22),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _ModernColors.primary))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: screens[_currentIndex],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _ModernColors.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.person_add, 'Demandes', 0,
                    badge: enAttente > 0 ? enAttente : null),
                _buildNavItem(Icons.star, 'Évals', 1),
                _buildNavItem(Icons.report_problem, 'Rapports', 2),
                _buildNavItem(Icons.calendar_month, 'Permanences', 3,
                    badge:
                        _permanences.isNotEmpty ? _permanences.length : null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {int? badge}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _ModernColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? _ModernColors.primary : Colors.white54,
                  size: 22,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _ModernColors.danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _ModernColors.primary : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: _ModernColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// MODERN UI HELPERS
// ══════════════════════════════════════════
Widget _modernLabel(String text) {
  return Text(text,
      style: const TextStyle(color: _ModernColors.textMuted, fontSize: 12));
}

Widget _modernField(
    TextEditingController ctrl, String label, TextInputType type) {
  return TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    keyboardType: type,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _ModernColors.textMuted),
      filled: true,
      fillColor: _ModernColors.bg,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _ModernColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _ModernColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

Widget _modernDropdown<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  required String hint,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: _ModernColors.bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _ModernColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        dropdownColor: _ModernColors.surface,
        hint: Text(hint,
            style:
                const TextStyle(color: _ModernColors.textMuted, fontSize: 13)),
        value: value,
        items: items,
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: _ModernColors.textMuted),
      ),
    ),
  );
}

Widget _infoRow(IconData icon, String text, {required Color color}) {
  return Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 8),
    Text(text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
  ]);
}

Widget _numberBadge(int number) {
  return Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: _ModernColors.primary.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        '$number',
        style: const TextStyle(
            color: _ModernColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    ),
  );
}

// ══════════════════════════════════════════
// FIXED: _ModernAlertDialog as Widget with proper context
// ══════════════════════════════════════════
class _ModernAlertDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Color confirmColor;
  final String confirmText;

  const _ModernAlertDialog({
    required this.title,
    this.content,
    required this.confirmColor,
    required this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _ModernColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: content != null
          ? Text(content!,
              style: const TextStyle(color: _ModernColors.textMuted))
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler',
              style: TextStyle(color: _ModernColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════
// TAB 1 — DEMANDES
// ══════════════════════════════════════════
class _DemandesTab extends StatelessWidget {
  final List<dynamic> demandes;
  final int enAttente;
  final int accepte;
  final int refuse;
  final Future<void> Function(int id, bool accepter) onAction;
  final Future<void> Function(int id, String statut) onChangeStatut;
  final Future<void> Function(int id) onSupprimer;

  const _DemandesTab({
    required this.demandes,
    required this.enAttente,
    required this.accepte,
    required this.refuse,
    required this.onAction,
    required this.onChangeStatut,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    if (demandes.isEmpty) {
      return const _EmptyState(
          icon: Icons.person_off, message: 'Aucune demande');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: demandes.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return _StatsRow(
              enAttente: enAttente, accepte: accepte, refuse: refuse);
        }
        final d = demandes[i - 1];
        return _DemandeCard(
          d: d,
          onAction: onAction,
          onChangeStatut: onChangeStatut,
          onSupprimer: onSupprimer,
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int enAttente;
  final int accepte;
  final int refuse;
  const _StatsRow(
      {required this.enAttente, required this.accepte, required this.refuse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.hourglass_empty,
            label: 'En attente',
            value: enAttente,
            color: _ModernColors.warning,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.check_circle,
            label: 'Acceptés',
            value: accepte,
            color: _ModernColors.secondary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.block,
            label: 'Refusés',
            value: refuse,
            color: _ModernColors.danger,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _ModernColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label,
                style: const TextStyle(
                    color: _ModernColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _DemandeCard extends StatelessWidget {
  final dynamic d;
  final Future<void> Function(int id, bool accepter) onAction;
  final Future<void> Function(int id, String statut) onChangeStatut;
  final Future<void> Function(int id) onSupprimer;

  const _DemandeCard({
    required this.d,
    required this.onAction,
    required this.onChangeStatut,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final statut = d['statut'] ?? 'en_attente';
    final color = statut == 'accepte'
        ? _ModernColors.secondary
        : statut == 'refuse'
            ? _ModernColors.danger
            : _ModernColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                _Avatar(
                  prenom: d['prenom'] ?? '',
                  nom: d['nom'] ?? '',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${d['id']} · ${d['created_at']?.toString().split('T').first ?? ''}',
                        style: const TextStyle(
                            color: _ModernColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statut.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: _ModernColors.textMuted, size: 20),
                  onPressed: () => onSupprimer(d['id']),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: _buildActions(statut, d['id']),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(String statut, int id) {
    if (statut == 'en_attente') {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Accepter',
              icon: Icons.check,
              color: _ModernColors.secondary,
              onTap: () => onAction(id, true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Refuser',
              icon: Icons.close,
              color: _ModernColors.danger,
              onTap: () => onAction(id, false),
            ),
          ),
        ],
      );
    }
    if (statut == 'accepte') {
      return _ActionButton(
        label: 'Désactiver le compte',
        icon: Icons.block,
        color: _ModernColors.danger,
        onTap: () => onChangeStatut(id, 'refuse'),
      );
    }
    return _ActionButton(
      label: 'Réactiver le compte',
      icon: Icons.check_circle,
      color: _ModernColors.secondary,
      onTap: () => onChangeStatut(id, 'accepte'),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String prenom;
  final String nom;
  const _Avatar({required this.prenom, required this.nom});

  @override
  Widget build(BuildContext context) {
    final initialP = prenom.isNotEmpty ? prenom[0] : '';
    final initialN = nom.isNotEmpty ? nom[0] : '';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ModernColors.primary, _ModernColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$initialP$initialN',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// TAB 2 — ÉVALUATIONS
// ══════════════════════════════════════════
class _EvaluationsTab extends StatelessWidget {
  final List<dynamic> evaluations;
  const _EvaluationsTab({required this.evaluations});

  @override
  Widget build(BuildContext context) {
    if (evaluations.isEmpty) {
      return const _EmptyState(
          icon: Icons.star_border, message: 'Aucune évaluation');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: evaluations.length,
      itemBuilder: (_, i) {
        final e = evaluations[i];
        final note = (e['note'] ?? 0) as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _ModernColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _ModernColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e['ligne_numero'] ?? '',
                      style: const TextStyle(
                        color: _ModernColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(
                      5,
                      (j) => Icon(
                        j < note
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _ModernColors.warning,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _ModernColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Moy: ${e['moyenne_ligne']} ⭐',
                      style: const TextStyle(
                        color: _ModernColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                e['passager_email'] ?? '',
                style: const TextStyle(
                    color: _ModernColors.textMuted, fontSize: 12),
              ),
              if (e['commentaire'] != null &&
                  e['commentaire'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _ModernColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    e['commentaire'],
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════
// TAB 3 — RAPPORTS
// ══════════════════════════════════════════
class _RapportsTab extends StatelessWidget {
  final List<dynamic> feedbacks;
  final List<dynamic> signalements;
  final Future<void> Function(int id, String statut) onUpdateStatut;

  const _RapportsTab({
    required this.feedbacks,
    required this.signalements,
    required this.onUpdateStatut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.feedback_outlined,
            title: 'Feedbacks',
            count: feedbacks.length,
            color: _ModernColors.secondary,
          ),
          const SizedBox(height: 12),
          if (feedbacks.isEmpty)
            const _EmptyMessage('Aucun feedback')
          else
            ...feedbacks.map((f) => _FeedbackCard(feedback: f)),
          const Divider(color: _ModernColors.border, height: 40),
          _SectionHeader(
            icon: Icons.report_problem_outlined,
            title: 'Signalements',
            count: signalements.length,
            color: _ModernColors.warning,
          ),
          const SizedBox(height: 12),
          if (signalements.isEmpty)
            const _EmptyMessage('Aucun signalement')
          else
            ...signalements.map((s) => _SignalementCard(
                  signalement: s,
                  onUpdateStatut: onUpdateStatut,
                )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          '$title ($count)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final dynamic feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (feedback['ligne_numero'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ModernColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feedback['ligne_numero'],
                    style: const TextStyle(
                      color: _ModernColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                feedback['passager_email'] ?? '',
                style: const TextStyle(
                    color: _ModernColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback['contenu'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SignalementCard extends StatelessWidget {
  final dynamic signalement;
  final Future<void> Function(int id, String statut) onUpdateStatut;

  const _SignalementCard({
    required this.signalement,
    required this.onUpdateStatut,
  });

  @override
  Widget build(BuildContext context) {
    final statut = signalement['statut'] ?? 'nouveau';
    final statutColor = _getStatutColor(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (signalement['ligne_numero'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ModernColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    signalement['ligne_numero'],
                    style: const TextStyle(
                      color: _ModernColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statut.toUpperCase(),
                  style: TextStyle(
                    color: statutColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            signalement['passager_email'] ?? '',
            style:
                const TextStyle(color: _ModernColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            signalement['description'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (statut != 'resolu') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (statut == 'nouveau')
                  Expanded(
                    child: _ActionButton(
                      label: 'En cours',
                      icon: Icons.timelapse,
                      color: Colors.blue.shade700,
                      onTap: () =>
                          onUpdateStatut(signalement['id'], 'en_cours'),
                    ),
                  ),
                if (statut == 'nouveau') const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Résolu',
                    icon: Icons.check_circle,
                    color: _ModernColors.secondary,
                    onTap: () => onUpdateStatut(signalement['id'], 'resolu'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'resolu':
        return _ModernColors.secondary;
      case 'en_cours':
        return Colors.blue;
      default:
        return _ModernColors.warning;
    }
  }
}

// ══════════════════════════════════════════
// TAB 4 — PERMANENCES
// ══════════════════════════════════════════
class _PermanencesTab extends StatelessWidget {
  final List<dynamic> permanences;
  final Future<void> Function(int id) onSupprimer;
  final VoidCallback onGenererRotation;
  final VoidCallback onGererLignes;

  const _PermanencesTab({
    required this.permanences,
    required this.onSupprimer,
    required this.onGenererRotation,
    required this.onGererLignes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _ModernColors.surface,
          child: Row(
            children: [
              const Icon(Icons.calendar_month,
                  color: _ModernColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Permanences Vendredi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onGererLignes,
                icon: const Icon(Icons.directions_bus,
                    color: _ModernColors.primary, size: 14),
                label: const Text('Lignes',
                    style:
                        TextStyle(color: _ModernColors.primary, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _ModernColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onGenererRotation,
                icon:
                    const Icon(Icons.autorenew, color: Colors.white, size: 14),
                label: const Text('Rotation',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ModernColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: permanences.isEmpty
              ? const _EmptyState(
                  icon: Icons.calendar_today,
                  message: 'Aucune permanence planifiée',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: permanences.length,
                  itemBuilder: (_, i) {
                    final p = permanences[i];
                    final date = p['date']?.toString().substring(0, 10) ?? '';
                    final heureDebut =
                        p['heure_debut']?.toString().substring(0, 5) ?? '';
                    final heureFin =
                        p['heure_fin']?.toString().substring(0, 5) ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _ModernColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _ModernColors.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _ModernColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_outline,
                                color: _ModernColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p['conducteur_prenom'] ?? ''} ${p['conducteur_nom'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.route,
                                      color: _ModernColors.textMuted, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p['ligne_numero'] ?? ''} — ${p['ligne_nom'] ?? ''}',
                                    style: const TextStyle(
                                        color: _ModernColors.textMuted,
                                        fontSize: 12),
                                  ),
                                ]),
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.access_time,
                                      color: _ModernColors.textMuted, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$heureDebut → $heureFin',
                                    style: const TextStyle(
                                        color: _ModernColors.textMuted,
                                        fontSize: 12),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _ModernColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  date,
                                  style: const TextStyle(
                                    color: _ModernColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => onSupprimer(p['id']),
                                child: const Icon(Icons.delete_outline,
                                    color: _ModernColors.danger, size: 20),
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
}

// ══════════════════════════════════════════
// LIGNES BOTTOM SHEET
// ══════════════════════════════════════════
class _LignesBottomSheet extends StatefulWidget {
  final List<dynamic> lignes;
  final Future<bool> Function(int ligneId, int newValue) onUpdate;

  const _LignesBottomSheet({
    required this.lignes,
    required this.onUpdate,
  });

  @override
  State<_LignesBottomSheet> createState() => _LignesBottomSheetState();
}

class _LignesBottomSheetState extends State<_LignesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ModernColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus,
                    color: _ModernColors.primary, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gérer les lignes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: _ModernColors.textMuted, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: _ModernColors.border, height: 24),
            Flexible(
              child: widget.lignes.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune ligne disponible',
                        style: TextStyle(color: _ModernColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.lignes.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: _ModernColors.border),
                      itemBuilder: (_, i) {
                        final l = widget.lignes[i];
                        final nbBus = (l['nb_bus'] ?? 1) as int;
                        return _LigneNbBusTile(
                          ligne: l,
                          nbBus: nbBus,
                          onUpdate: (newValue) async {
                            final success = await widget.onUpdate(
                              l['id'] as int,
                              newValue,
                            );
                            if (success && mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneNbBusTile extends StatefulWidget {
  final dynamic ligne;
  final int nbBus;
  final Future<void> Function(int newValue) onUpdate;

  const _LigneNbBusTile({
    required this.ligne,
    required this.nbBus,
    required this.onUpdate,
  });

  @override
  State<_LigneNbBusTile> createState() => _LigneNbBusTileState();
}

// ══════════════════════════════════════════
// LIGNE TILE
// ══════════════════════════════════════════
class _LigneNbBusTileState extends State<_LigneNbBusTile> {
  late final TextEditingController _ctrl;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.nbBus}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.ligne;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${l['numero']} — ${l['nom']}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: _isEditing
          ? Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _ModernColors.border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _ModernColors.primary),
                      ),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _ModernColors.primary,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check,
                            color: _ModernColors.secondary, size: 20),
                        onPressed: _save,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: _ModernColors.textMuted, size: 20),
                        onPressed: () => setState(() => _isEditing = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            )
          : Text(
              '${widget.nbBus} bus / vendredi',
              style:
                  const TextStyle(color: _ModernColors.secondary, fontSize: 12),
            ),
      trailing: _isEditing
          ? null
          : IconButton(
              icon: const Icon(Icons.edit,
                  color: _ModernColors.primary, size: 20),
              onPressed: () => setState(() => _isEditing = true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
    );
  }

  Future<void> _save() async {
    final val = int.tryParse(_ctrl.text);
    if (val == null || val < 1) {
      setState(() => _isEditing = false);
      return;
    }
    setState(() => _isLoading = true);
    await widget.onUpdate(val);
    if (mounted) setState(() => _isLoading = false);
  }
}

// ══════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.white30, fontSize: 16)),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text,
          style: const TextStyle(color: Colors.white30, fontSize: 14)),
    );
  }
}
