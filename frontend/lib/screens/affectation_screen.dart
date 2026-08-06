import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

// ══════════════════════════════════════════════════════════
// AFFECTATION SCREEN — Gérer l'affectation conducteurs-Véhicules
// Scénario :
//   1. Propriétaire voit la liste des affectations (conducteur ↔ véhicule ↔ ligne)
//   2. Il peut créer une nouvelle affectation
//   3. Il peut modifier une affectation existante
//   4. Il peut supprimer une affectation existante
//   Règles métier :
//   - Un conducteur ne peut avoir qu'une affectation active à la fois
//   - Le véhicule et le conducteur doivent appartenir au même propriétaire
// ══════════════════════════════════════════════════════════
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

  // ── Charger tout en parallèle ──
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
    setState(() => _isLoading = false);
  }

  // ══════════════════════════════════════
  // Dialog — Nouvelle affectation
  // ══════════════════════════════════════
  Future<void> _showAjouterDialog() async {
    if (_conducteurs.isEmpty) {
      _showSnack('Aucun conducteur disponible. Ajoutez-en d\'abord.', false);
      return;
    }
    if (_vehicules.isEmpty) {
      _showSnack('Aucun véhicule disponible. Ajoutez-en d\'abord.', false);
      return;
    }

    int? selConducteur;
    int? selVehicule;
    int? selLigne;
    bool loading = false;
    String? errMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.link, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Nouvelle affectation',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 4),
              _buildLabel(
                  'Conducteur *', Icons.person_outline, AppTheme.primary),
              const SizedBox(height: 6),
              _buildDropdown<int>(
                hint: 'Sélectionner un conducteur',
                value: selConducteur,
                items: _conducteurs
                    .map((c) => DropdownMenuItem<int>(
                          value: _toInt(c['id']),
                          child: Text(
                            '${c['nom'] ?? ''} ${c['prenom'] ?? ''}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setS(() {
                  selConducteur = v;
                  errMsg = null;
                }),
              ),
              const SizedBox(height: 14),
              _buildLabel('Véhicule *', Icons.directions_bus_outlined,
                  AppTheme.secondary),
              const SizedBox(height: 6),
              _buildDropdown<int>(
                hint: 'Sélectionner un véhicule',
                value: selVehicule,
                items: _vehicules
                    .map((v) => DropdownMenuItem<int>(
                          value: _toInt(v['id']),
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                '${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              v['immatriculation'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setS(() {
                  selVehicule = v;
                  errMsg = null;
                }),
              ),
              const SizedBox(height: 14),
              _buildLabel('Ligne', Icons.route_outlined, AppTheme.warning,
                  optional: true),
              const SizedBox(height: 6),
              _buildDropdown<int>(
                hint: '— Aucune ligne —',
                value: selLigne,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('— Aucune ligne —',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                  ..._lignes.map((l) => DropdownMenuItem<int>(
                        value: _toInt(l['id']),
                        child: Text(
                          '${l['numero'] ?? ''}${l['nom'] != null ? '  —  ${l['nom']}' : ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) => setS(() => selLigne = v),
              ),
              if (errMsg != null) ...[
                const SizedBox(height: 12),
                _buildErrBox(errMsg!),
              ],
              const SizedBox(height: 8),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (selConducteur == null) {
                        setS(() =>
                            errMsg = 'Veuillez sélectionner un conducteur');
                        return;
                      }
                      if (selVehicule == null) {
                        setS(
                            () => errMsg = 'Veuillez sélectionner un véhicule');
                        return;
                      }
                      setS(() {
                        loading = true;
                        errMsg = null;
                      });
                      try {
                        final r = await http
                            .post(
                              Uri.parse(ApiConstants.affectations),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $_token',
                              },
                              body: jsonEncode({
                                'conducteur_id': selConducteur,
                                'vehicule_id': selVehicule,
                                'ligne_id': selLigne,
                              }),
                            )
                            .timeout(const Duration(seconds: 10));
                        setS(() => loading = false);
                        final msg = jsonDecode(r.body)['message'] ?? '';
                        if (r.statusCode == 201) {
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _showSnack(msg, true);
                          _load();
                        } else {
                          setS(() => errMsg = msg);
                        }
                      } catch (_) {
                        setS(() {
                          loading = false;
                          errMsg = 'Erreur de connexion';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Affecter',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // Dialog — Modifier affectation
  // ══════════════════════════════════════
  Future<void> _showModifierDialog(Map a) async {
    int? selConducteur = _toInt(a['conducteur_id']);
    int? selVehicule = _toInt(a['vehicule_id']);
    int? selLigne = a['ligne_id'] != null ? _toInt(a['ligne_id']) : null;
    bool loading = false;
    String? errMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Modifier affectation',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 4),
              _buildLabel(
                  'Conducteur *', Icons.person_outline, AppTheme.primary),
              const SizedBox(height: 6),
              _buildDropdown<int>(
                hint: 'Sélectionner un conducteur',
                value: selConducteur,
                items: _conducteurs
                    .map((c) => DropdownMenuItem<int>(
                          value: _toInt(c['id']),
                          child: Text(
                            '${c['nom'] ?? ''} ${c['prenom'] ?? ''}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setS(() {
                  selConducteur = v;
                  errMsg = null;
                }),
              ),
              const SizedBox(height: 14),
              _buildLabel('Véhicule *', Icons.directions_bus_outlined,
                  AppTheme.secondary),
              const SizedBox(height: 6),
              _buildDropdown<int>(
                hint: 'Sélectionner un véhicule',
                value: selVehicule,
                items: _vehicules
                    .map((v) => DropdownMenuItem<int>(
                          value: _toInt(v['id']),
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                '${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              v['immatriculation'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setS(() {
                  selVehicule = v;
                  errMsg = null;
                }),
              ),
              const SizedBox(height: 14),
              _buildLabel('Ligne', Icons.route_outlined, AppTheme.warning,
                  optional: true),
              const SizedBox(height: 6),
              _buildDropdown<int>(
                hint: '— Aucune ligne —',
                value: selLigne,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('— Aucune ligne —',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                  ..._lignes.map((l) => DropdownMenuItem<int>(
                        value: _toInt(l['id']),
                        child: Text(
                          '${l['numero'] ?? ''}${l['nom'] != null ? '  —  ${l['nom']}' : ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) => setS(() => selLigne = v),
              ),
              if (errMsg != null) ...[
                const SizedBox(height: 12),
                _buildErrBox(errMsg!),
              ],
              const SizedBox(height: 8),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (selConducteur == null) {
                        setS(() =>
                            errMsg = 'Veuillez sélectionner un conducteur');
                        return;
                      }
                      if (selVehicule == null) {
                        setS(
                            () => errMsg = 'Veuillez sélectionner un véhicule');
                        return;
                      }
                      setS(() {
                        loading = true;
                        errMsg = null;
                      });
                      try {
                        final r = await http
                            .put(
                              Uri.parse(
                                  '${ApiConstants.affectations}/${a['id']}'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $_token',
                              },
                              body: jsonEncode({
                                'conducteur_id': selConducteur,
                                'vehicule_id': selVehicule,
                                'ligne_id': selLigne,
                              }),
                            )
                            .timeout(const Duration(seconds: 10));
                        setS(() => loading = false);
                        final msg = jsonDecode(r.body)['message'] ?? '';
                        if (r.statusCode == 200) {
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _showSnack(msg, true);
                          _load();
                        } else {
                          setS(() => errMsg = msg);
                        }
                      } catch (_) {
                        setS(() {
                          loading = false;
                          errMsg = 'Erreur de connexion';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // Supprimer
  // ══════════════════════════════════════
  Future<void> _supprimer(dynamic id, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Supprimer l\'affectation ?',
              style: TextStyle(color: Colors.white, fontSize: 15)),
        ]),
        content: Text('Supprimer l\'affectation de $label ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.white))),
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
      _showSnack(jsonDecode(r.body)['message'] ?? '', r.statusCode == 200);
      if (r.statusCode == 200) _load();
    } catch (_) {
      _showSnack('Erreur de connexion', false);
    }
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Affectation Conducteurs',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text('${_affectations.length} affectation(s)',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_affectation',
        onPressed: _showAjouterDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.link, color: Colors.white),
        label: const Text('Affecter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_errorMsg != null) return _buildError(_errorMsg!);
    if (_affectations.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.link_off, size: 70, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 16),
          const Text('Aucune affectation',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Appuyez sur + pour créer une affectation',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _affectations.length,
      itemBuilder: (_, i) {
        final a = _affectations[i];
        final nomCond =
            '${a['conducteur_nom'] ?? ''} ${a['conducteur_prenom'] ?? ''}';
        final vehicule = '${a['marque'] ?? ''} ${a['modele'] ?? ''}'.trim();
        final immat = a['immatriculation'] ?? '';
        final ligneNum = a['ligne_numero'];
        final ligneNom = a['ligne_nom'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Column(children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.link, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(nomCond,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                // ── زر تعديل ──
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  tooltip: 'Modifier',
                  onPressed: () => _showModifierDialog(a),
                ),
                // ── زر حذف ──
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  tooltip: 'Supprimer',
                  onPressed: () => _supprimer(a['id'], nomCond),
                ),
              ]),
            ),

            // ── Détails ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(children: [
                _infoRow(Icons.directions_bus_rounded, AppTheme.secondary,
                    vehicule, immat),
                if (ligneNum != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.route_rounded, AppTheme.warning,
                      'Ligne $ligneNum', ligneNom ?? ''),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.route_outlined,
                        color: Colors.white24, size: 16),
                    const SizedBox(width: 8),
                    Text('Aucune ligne assignée',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ]),
                ],
              ]),
            ),
          ]),
        );
      },
    );
  }

  // ══════════════════════════════════════
  // Helpers UI
  // ══════════════════════════════════════
  Widget _buildLabel(String label, IconData icon, Color color,
      {bool optional = false}) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      if (optional) ...[
        const SizedBox(width: 4),
        Text('(optionnel)',
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
      ],
    ]);
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white38, size: 20),
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(hint,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          items: items,
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildErrBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: const TextStyle(color: AppTheme.error, fontSize: 12))),
      ]),
    );
  }

  Widget _infoRow(IconData icon, Color color, String main, String sub) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(main,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          if (sub.isNotEmpty)
            Text(sub,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    ]);
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 60),
          const SizedBox(height: 16),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Réessayer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showSnack(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  int _toInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
}
