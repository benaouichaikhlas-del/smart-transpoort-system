import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

/// ═════════════════════════════════════════════════════════════════════════════
/// APP BLUE THEME (Thème Bleu Sombre avec Effet Rayon/Glow)
/// ═════════════════════════════════════════════════════════════════════════════
class AppBlueTheme {
  static const Color background = Color(0xFF070C1B); // Fond principal
  static const Color surface = Color(0xFF0F172A); // Cartes & AppBars
  static const Color cardBorder = Color(0xFF1E293B); // Bordure subtile
  static const Color primaryBlue = Color(0xFF0284C7); // Bleu Royal
  static const Color accentBlue = Color(0xFF3B82F6); // Bleu vif متوهج
  static const Color cyan = Color(0xFF06B6D4); // Cyan
  static const Color green = Color(0xFF22C55E); // Vert Conducteur/Véhicule
  static const Color gold = Color(0xFFF59E0B); // Doré Ligne
  static const Color danger = Color(0xFFEF4444); // Rouge suppression
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;
}

/// ═════════════════════════════════════════════════════════════════════════════
/// AFFECTATION SCREEN — Gérer l'affectation conducteurs-véhicules-lignes
/// ═════════════════════════════════════════════════════════════════════════════
class AffectationScreen extends StatefulWidget {
  const AffectationScreen({super.key});

  @override
  State<AffectationScreen> createState() => _AffectationScreenState();
}

class _AffectationScreenState extends State<AffectationScreen> {
  List<dynamic> _affectations = [];
  List<dynamic> _conducteurs = [];
  List<dynamic> _vehicules = [];
  List<dynamic> _lignes = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _token => context.read<AuthProvider>().user!.token;

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final headers = {'Authorization': 'Bearer $_token'};
      final results = await Future.wait([
        http.get(Uri.parse(ApiConstants.affectations), headers: headers),
        http.get(Uri.parse(ApiConstants.conducteurs), headers: headers),
        http.get(Uri.parse(ApiConstants.vehicules), headers: headers),
        http.get(Uri.parse(ApiConstants.lignes), headers: headers),
      ]).timeout(const Duration(seconds: 15));

      setState(() {
        if (results[0].statusCode == 200) {
          final b = jsonDecode(results[0].body);
          _affectations = b is List ? b : [];
        }
        if (results[1].statusCode == 200) {
          final b = jsonDecode(results[1].body);
          _conducteurs = b is List ? b : [];
        }
        if (results[2].statusCode == 200) {
          final b = jsonDecode(results[2].body);
          _vehicules = b is List ? b : [];
        }
        if (results[3].statusCode == 200) {
          final b = jsonDecode(results[3].body);
          _lignes = b is List ? b : [];
        }
      });
    } catch (e) {
      setState(() => _errorMsg = 'Erreur de connexion au serveur');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showAjouterDialog() async {
    if (_conducteurs.isEmpty) {
      _showSnack('Aucun conducteur disponible. Ajoutez-en d\'abord.', false);
      return;
    }
    if (_vehicules.isEmpty) {
      _showSnack('Aucun véhicule disponible. Ajoutez-en d\'abord.', false);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _AffectationFormDialog(
        token: _token,
        conducteurs: _conducteurs,
        vehicules: _vehicules,
        lignes: _lignes,
        onSaved: _load,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _showModifierDialog(Map a) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _AffectationFormDialog(
        token: _token,
        affectation: a,
        conducteurs: _conducteurs,
        vehicules: _vehicules,
        lignes: _lignes,
        onSaved: _load,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _supprimer(dynamic id, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppBlueTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppBlueTheme.danger),
            SizedBox(width: 8),
            Text('Supprimer l\'affectation ?',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'Voulez-vous supprimer l\'affectation de $label ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppBlueTheme.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      final r = await http.delete(
        Uri.parse('${ApiConstants.affectations}/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnack(
        jsonDecode(r.body)['message'] ?? 'Supprimé avec succès',
        r.statusCode == 200,
      );
      if (r.statusCode == 200) _load();
    } catch (_) {
      _showSnack('Erreur de connexion', false);
    }
  }

  PreferredSizeWidget _modernHeader({
    required String title,
    required String subtitle,
    VoidCallback? onRefresh,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        color: AppBlueTheme.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 16, 10),
            child: Row(
              children: [
                _headerIconBtn(Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppBlueTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppBlueTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRefresh != null)
                  _headerIconBtn(Icons.refresh_rounded, onTap: onRefresh),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, {required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  void _showSnack(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? Colors.green.shade700 : AppBlueTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBlueTheme.background,
      appBar: _modernHeader(
        title: 'Affectation Conducteurs',
        subtitle: '${_affectations.length} affectation(s)',
        onRefresh: _load,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppBlueTheme.accentBlue.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'add_affectation',
          onPressed: _showAjouterDialog,
          backgroundColor: AppBlueTheme.primaryBlue,
          icon: const Icon(Icons.link_rounded, color: Colors.white),
          label: const Text(
            'Affecter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppBlueTheme.cyan));
    }
    if (_errorMsg != null) return _buildError(_errorMsg!);

    if (_affectations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded,
                size: 70, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('Aucune affectation',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Appuyez sur Affecter pour lier un conducteur',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _affectations.length,
      itemBuilder: (_, i) {
        final a = _affectations[i];
        final nomCond =
            '${a['conducteur_nom'] ?? ''} ${a['conducteur_prenom'] ?? ''}'
                .trim();
        final vehicule = '${a['marque'] ?? ''} ${a['modele'] ?? ''}'.trim();
        final immat = a['immatriculation'] ?? '';
        final ligneNum = a['ligne_numero'];
        final ligneNom = a['ligne_nom'];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppBlueTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppBlueTheme.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppBlueTheme.accentBlue.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Card avec icône متوهجة
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppBlueTheme.primaryBlue.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppBlueTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppBlueTheme.accentBlue.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.link_rounded,
                          color: AppBlueTheme.cyan, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nomCond.isEmpty ? 'Conducteur non spécifié' : nomCond,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppBlueTheme.accentBlue, size: 20),
                      onPressed: () => _showModifierDialog(a),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppBlueTheme.danger, size: 20),
                      onPressed: () => _supprimer(a['id'], nomCond),
                    ),
                  ],
                ),
              ),

              // Détails véhicule + ligne
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.directions_bus_rounded,
                      AppBlueTheme.green,
                      vehicule.isEmpty ? 'Véhicule' : vehicule,
                      immat,
                    ),
                    const SizedBox(height: 10),
                    if (ligneNum != null)
                      _infoRow(
                        Icons.route_rounded,
                        AppBlueTheme.gold,
                        'Ligne $ligneNum',
                        ligneNom ?? '',
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.route_outlined,
                              color: Colors.white24, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            'Aucune ligne assignée',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, Color color, String main, String sub) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                main,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: const TextStyle(
                    color: AppBlueTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppBlueTheme.danger, size: 60),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppBlueTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════════
/// DIALOG FORME — Nouvelle / Modifier Affectation (مع الشعاع الأزرق)
/// ═════════════════════════════════════════════════════════════════════════════
class _AffectationFormDialog extends StatefulWidget {
  final String token;
  final Map? affectation;
  final List<dynamic> conducteurs;
  final List<dynamic> vehicules;
  final List<dynamic> lignes;
  final VoidCallback onSaved;

  const _AffectationFormDialog({
    required this.token,
    this.affectation,
    required this.conducteurs,
    required this.vehicules,
    required this.lignes,
    required this.onSaved,
  });

  @override
  State<_AffectationFormDialog> createState() => _AffectationFormDialogState();
}

class _AffectationFormDialogState extends State<_AffectationFormDialog> {
  int? selConducteur;
  int? selVehicule;
  int? selLigne;
  bool loading = false;
  String? errMsg;

  bool get _isEdit => widget.affectation != null;
  int _toInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    final a = widget.affectation;
    if (a != null) {
      selConducteur = _toInt(a['conducteur_id']);
      selVehicule = _toInt(a['vehicule_id']);
      selLigne = a['ligne_id'] != null ? _toInt(a['ligne_id']) : null;
    }
  }

  Future<void> _submit() async {
    if (selConducteur == null) {
      setState(() => errMsg = 'Veuillez sélectionner un conducteur');
      return;
    }
    if (selVehicule == null) {
      setState(() => errMsg = 'Veuillez sélectionner un véhicule');
      return;
    }

    setState(() {
      loading = true;
      errMsg = null;
    });

    try {
      final url = _isEdit
          ? '${ApiConstants.affectations}/${widget.affectation!['id']}'
          : ApiConstants.affectations;

      final r = await (_isEdit ? http.put : http.post)(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'conducteur_id': selConducteur,
          'vehicule_id': selVehicule,
          'ligne_id': selLigne,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => loading = false);

      final msg = jsonDecode(r.body)['message'] ?? 'Opération réussie';
      final ok = _isEdit ? r.statusCode == 200 : r.statusCode == 201;

      if (ok) {
        Navigator.pop(context, true);
        widget.onSaved();
      } else {
        setState(() => errMsg = msg);
      }
    } catch (_) {
      setState(() {
        loading = false;
        errMsg = 'Erreur de connexion';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppBlueTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppBlueTheme.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppBlueTheme.accentBlue.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header النافذة مع شعاع ضوئي زاهي
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppBlueTheme.primaryBlue,
                          AppBlueTheme.accentBlue
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppBlueTheme.accentBlue.withOpacity(0.5),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_rounded : Icons.link_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit
                              ? 'Modifier affectation'
                              : 'Nouvelle affectation',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEdit
                              ? 'Modifier les informations'
                              : 'Assigner un conducteur à un véhicule',
                          style: const TextStyle(
                            color: AppBlueTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppBlueTheme.cardBorder),
              const SizedBox(height: 16),

              // ── اختيار السائق ──
              _selectorBlock(
                color: AppBlueTheme.cyan,
                label: 'Conducteur *',
                icon: Icons.person_outline_rounded,
                value: selConducteur,
                hint: 'Sélectionner un conducteur',
                items: widget.conducteurs
                    .map((c) => DropdownMenuItem<int>(
                          value: _toInt(c['id']),
                          child: Text(
                            '${c['nom'] ?? ''} ${c['prenom'] ?? ''}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  selConducteur = v;
                  errMsg = null;
                }),
              ),
              const SizedBox(height: 16),

              // ── اختيار المركبة ──
              _selectorBlock(
                color: AppBlueTheme.green,
                label: 'Véhicule *',
                icon: Icons.directions_bus_outlined,
                value: selVehicule,
                hint: 'Sélectionner un véhicule',
                items: widget.vehicules
                    .map((v) => DropdownMenuItem<int>(
                          value: _toInt(v['id']),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                v['immatriculation'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  selVehicule = v;
                  errMsg = null;
                }),
              ),
              const SizedBox(height: 16),

              // ── اختيار الخط (اختياري) ──
              _selectorBlock(
                color: AppBlueTheme.gold,
                label: 'Ligne',
                optional: true,
                icon: Icons.route_rounded,
                value: selLigne,
                hint: '— Aucune ligne —',
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('— Aucune ligne —',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ),
                  ...widget.lignes.map((l) => DropdownMenuItem<int>(
                        value: _toInt(l['id']),
                        child: Text(
                          '${l['numero'] ?? ''}${l['nom'] != null ? ' — ${l['nom']}' : ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => selLigne = v),
              ),

              if (errMsg != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppBlueTheme.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppBlueTheme.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppBlueTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errMsg!,
                            style: const TextStyle(
                                color: AppBlueTheme.danger, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // الأزرار الحركية (Cancel / Submit avec Glow)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppBlueTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppBlueTheme.primaryBlue,
                            AppBlueTheme.accentBlue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppBlueTheme.accentBlue.withOpacity(0.5),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: loading ? null : _submit,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isEdit
                                              ? Icons.check_rounded
                                              : Icons.link_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isEdit ? 'Enregistrer' : 'Affecter',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _selectorBlock<T>({
    required Color color,
    required String label,
    required IconData icon,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool optional = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  if (optional) ...[
                    const SizedBox(width: 6),
                    const Text('(optionnel)',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppBlueTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppBlueTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: AppBlueTheme.surface,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38, size: 20),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(hint,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 13)),
                    ),
                    items: items,
                    onChanged: onChanged,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
