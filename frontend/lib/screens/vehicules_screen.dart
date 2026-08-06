import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class VehiculesScreen extends StatefulWidget {
  const VehiculesScreen({super.key});
  @override
  State<VehiculesScreen> createState() => _VehiculesScreenState();
}

class _VehiculesScreenState extends State<VehiculesScreen> {
  List<dynamic> _vehicules = [];
  bool _isLoading = true;
  String? _errorMsg;

  // ── Couleurs disponibles ──
  static const List<Color> _couleurs = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF6B7280),
    Color(0xFF1F2937),
    Color(0xFFFFFFFF),
    Color(0xFFDC2626),
  ];

  static const List<String> _typesVehicule = [
    'Bus',
    'Minibus',
    'Microbus',
    'Taxi',
    'Tramway',
    'Autre'
  ];

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
      final r = await http.get(Uri.parse(ApiConstants.vehicules), headers: {
        'Authorization': 'Bearer $_token'
      }).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        setState(() => _vehicules = jsonDecode(r.body));
      } else {
        final body = jsonDecode(r.body);
        final code = body['code'] ?? '';
        setState(() => _errorMsg = code == 'PROPRIETAIRE_NOT_FOUND'
            ? 'Votre compte propriétaire n\'est pas encore configuré.'
            : body['message'] ?? 'Erreur serveur');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Erreur de connexion au serveur');
    }
    setState(() => _isLoading = false);
  }

  // ══════════════════════════════════════
  // Dialog Ajouter / Modifier
  // ══════════════════════════════════════
  Future<void> _showAjouterDialog({Map? vehicule}) async {
    final marqueCtrl = TextEditingController(text: vehicule?['marque'] ?? '');
    final modeleCtrl = TextEditingController(text: vehicule?['modele'] ?? '');
    final capaciteCtrl =
        TextEditingController(text: vehicule?['capacite']?.toString() ?? '30');
    final puissanceCtrl =
        TextEditingController(text: vehicule?['puissance']?.toString() ?? '');
    final anneeCtrl = TextEditingController(
        text: vehicule?['annee_service']?.toString() ?? '');

    // Matricule champ unique
    final matriculeCtrl =
        TextEditingController(text: vehicule?['immatriculation'] ?? '');

    String etat = vehicule?['etat'] ?? 'actif';
    String typeVehicule = vehicule?['type_vehicule'] ?? 'Bus';
    Color couleurSel = _hexToColor(vehicule?['couleur'] ?? '#3B82F6');

    String? marqueErr;
    String? wilayaErr;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: couleurSel,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_bus,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(vehicule == null ? 'Ajouter véhicule' : 'Modifier véhicule',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),

              // ── Couleur ──
              _sectionLabel('Couleur du véhicule'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _couleurs
                    .map((c) => GestureDetector(
                          onTap: () => setS(() => couleurSel = c),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: couleurSel == c
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: couleurSel == c
                                  ? [
                                      BoxShadow(
                                          color: c.withOpacity(0.5),
                                          blurRadius: 6)
                                    ]
                                  : null,
                            ),
                            child: couleurSel == c
                                ? Icon(Icons.check,
                                    color: c == Colors.white
                                        ? Colors.black
                                        : Colors.white,
                                    size: 16)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // ── Matricule ──
              _sectionLabel('Matricule (ex: XX-XX-X-XXXXX)'),
              const SizedBox(height: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: matriculeCtrl,
                  style: const TextStyle(color: Colors.white),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  onChanged: (_) => setS(() => wilayaErr = null),
                  decoration: InputDecoration(
                    hintText: 'ex: XX-XX-X-XXXXX',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: wilayaErr != null ? Colors.red : Colors.white38),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: wilayaErr != null
                          ? const BorderSide(color: Colors.red)
                          : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: wilayaErr != null
                          ? const BorderSide(color: Colors.red)
                          : BorderSide.none,
                    ),
                  ),
                ),
                if (wilayaErr != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(wilayaErr!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 11)),
                  ),
              ]),
              const SizedBox(height: 14),

              // ── Type véhicule ──
              _sectionLabel('Type de véhicule'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: typeVehicule,
                dropdownColor: AppTheme.background,
                style: const TextStyle(color: Colors.white),
                decoration: _dropDeco(),
                items: _typesVehicule
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setS(() => typeVehicule = v!),
              ),
              const SizedBox(height: 10),

              // ── Marque ──
              _dialogField(marqueCtrl, 'Marque *', Icons.directions_bus,
                  errorText: marqueErr,
                  onChanged: (_) => setS(() => marqueErr = null)),
              const SizedBox(height: 10),

              // ── Modèle ──
              _dialogField(modeleCtrl, 'Modèle', Icons.info_outline),
              const SizedBox(height: 10),

              // ── Capacité + Puissance ──
              Row(children: [
                Expanded(
                    child: _dialogField(
                        capaciteCtrl, 'Places', Icons.event_seat,
                        type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _dialogField(
                        puissanceCtrl, 'Puissance (CV)', Icons.speed,
                        type: TextInputType.number)),
              ]),
              const SizedBox(height: 10),

              // ── Année de service ──
              _dialogField(anneeCtrl, 'Année de service', Icons.calendar_today,
                  type: TextInputType.number),
              const SizedBox(height: 10),

              const SizedBox(height: 16),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                bool valid = true;
                if (marqueCtrl.text.trim().isEmpty) {
                  setS(() => marqueErr = 'La marque est obligatoire');
                  valid = false;
                }
                // Validation matricule
                final mat = matriculeCtrl.text.trim();
                final matRegex = RegExp(r'^\d{2}-\d{2}-\d{1}-\d{4,5}$');
                if (mat.isEmpty) {
                  setS(() => wilayaErr = 'Le matricule est obligatoire');
                  valid = false;
                } else if (!matRegex.hasMatch(mat)) {
                  setS(() => wilayaErr = 'Format invalide (ex: XX-XX-X-XXXXX)');
                  valid = false;
                }
                if (!valid) return;

                Navigator.pop(ctx);
                await _saveVehicule(
                  vehicule: vehicule,
                  marque: marqueCtrl.text.trim(),
                  modele: modeleCtrl.text.trim(),
                  immatriculation: matriculeCtrl.text.trim(),
                  capacite: int.tryParse(capaciteCtrl.text) ?? 30,
                  puissance: int.tryParse(puissanceCtrl.text),
                  anneeService: int.tryParse(anneeCtrl.text),
                  typeVehicule: typeVehicule,
                  couleur: _colorToHex(couleurSel),
                  etat: etat,
                  wilayaMat: '',
                  typeMat: '',
                  serieMat: '',
                  anneeMat: '',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: couleurSel,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(vehicule == null ? 'Ajouter' : 'Modifier',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVehicule({
    Map? vehicule,
    required String marque,
    required String modele,
    required String immatriculation,
    required int capacite,
    int? puissance,
    int? anneeService,
    required String typeVehicule,
    required String couleur,
    required String etat,
    required String wilayaMat,
    required String typeMat,
    required String serieMat,
    required String anneeMat,
  }) async {
    final body = {
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'capacite': capacite,
      'etat': etat,
      'couleur': couleur,
      'puissance': puissance,
      'annee_service': anneeService,
      'type_vehicule': typeVehicule,
      'wilaya_mat': wilayaMat,
      'type_mat': typeMat,
      'serie_mat': serieMat,
      'annee_mat': anneeMat,
    };
    try {
      final r = vehicule == null
          ? await http
              .post(Uri.parse(ApiConstants.vehicules),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $_token'
                  },
                  body: jsonEncode(body))
              .timeout(const Duration(seconds: 10))
          : await http
              .put(Uri.parse('${ApiConstants.vehicules}/${vehicule['id']}'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $_token'
                  },
                  body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnack(jsonDecode(r.body)['message'] ?? 'Opération terminée',
          r.statusCode < 300);
      if (r.statusCode < 300) _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur de connexion au serveur', false);
    }
  }

  Future<void> _supprimer(int id, String marque) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Supprimer ?',
                  style: TextStyle(color: Colors.white)),
              content: Text('Supprimer "$marque" ?',
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
            ));
    if (ok != true) return;
    try {
      final r = await http.delete(Uri.parse('${ApiConstants.vehicules}/$id'),
          headers: {
            'Authorization': 'Bearer $_token'
          }).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      _showSnack(jsonDecode(r.body)['message'] ?? '', r.statusCode == 200);
      if (r.statusCode == 200) _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur de connexion', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mes Véhicules',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('${_vehicules.length} véhicule(s)',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_vehicule',
        onPressed: () => _showAjouterDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    if (_errorMsg != null)
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 60),
          const SizedBox(height: 16),
          Text(_errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
        ]),
      ));
    if (_vehicules.isEmpty)
      return const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 70, color: Colors.white24),
          SizedBox(height: 16),
          Text('Aucun véhicule', style: TextStyle(color: Colors.white38)),
          SizedBox(height: 8),
          Text('Appuyez sur + pour en ajouter',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _vehicules.length,
      itemBuilder: (_, i) {
        final v = _vehicules[i];
        final etat = v['etat'] ?? 'actif';
        final ec = _etatColor(etat);
        final vColor = _hexToColor(v['couleur'] ?? '#3B82F6');
        final mat = v['immatriculation'] ?? '';
        final type = v['type_vehicule'] ?? '';
        final annee = v['annee_service'];
        final puiss = v['puissance'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ec.withOpacity(0.25)),
          ),
          child: Column(children: [
            // ── Header coloré ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: vColor.withOpacity(0.12),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border:
                    Border(bottom: BorderSide(color: vColor.withOpacity(0.2))),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: vColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 3),
                      // Matricule mis en valeur
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: vColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: vColor.withOpacity(0.4)),
                        ),
                        child: Text(mat,
                            style: TextStyle(
                                color: vColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ),
                    ])),
                Column(children: [
                  IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white70, size: 20),
                      onPressed: () => _showAjouterDialog(vehicule: v)),
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () => _supprimer(
                          v['id'], '${v['marque']} ${v['modele'] ?? ''}')),
                ]),
              ]),
            ),

            // ── Détails ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  // État
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ec.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_etatIcon(etat), color: ec, size: 12),
                      const SizedBox(width: 4),
                      Text(etat,
                          style: TextStyle(
                              color: ec,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Type
                  if (type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(type,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _infoChip(Icons.event_seat_outlined,
                      '${v['capacite'] ?? '—'} places', Colors.white54),
                  const SizedBox(width: 12),
                  if (puiss != null)
                    _infoChip(
                        Icons.speed_outlined, '$puiss CV', Colors.white54),
                  const SizedBox(width: 12),
                  if (annee != null)
                    _infoChip(Icons.calendar_today_outlined, '$annee',
                        Colors.white54),
                ]),
              ]),
            ),
          ]),
        );
      },
    );
  }

  // ── Helpers UI ──
  Widget _sectionLabel(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Text(t,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _infoChip(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      );

  InputDecoration _dropDeco() => InputDecoration(
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text,
      String? errorText,
      ValueChanged<String>? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon,
              color: errorText != null ? Colors.red : Colors.white38),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.red)
                  : BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.red)
                  : BorderSide.none),
        ),
      ),
      if (errorText != null)
        Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(errorText,
                style: const TextStyle(color: Colors.red, fontSize: 11))),
    ]);
  }

  void _showSnack(String msg, bool success) {
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

  Color _etatColor(String e) {
    switch (e) {
      case 'actif':
        return AppTheme.secondary;
      case 'en panne':
        return AppTheme.error;
      case 'en maintenance':
        return AppTheme.warning;
      default:
        return AppTheme.secondary;
    }
  }

  IconData _etatIcon(String e) {
    switch (e) {
      case 'en panne':
        return Icons.build;
      case 'en maintenance':
        return Icons.settings;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
}
