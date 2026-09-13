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
    Color(0xFF8B5CF6), // Purple (sélection par défaut)
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF9CA3AF), // Gray
    Color(0xFF1F2937), // Dark Gray
    Color(0xFFFFFFFF), // White
    Color(0xFFDC2626), // Dark Red
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
      final r = await http.get(
        Uri.parse(ApiConstants.vehicules),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

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

  Future<void> _showAjouterDialog({Map? vehicule}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VehicleFormPage(
          vehicule: vehicule,
          couleurs: _couleurs,
          typesVehicule: _typesVehicule,
          onSave: (data) => _saveVehicule(vehicule: vehicule, data: data),
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _saveVehicule({
    Map? vehicule,
    required Map<String, dynamic> data,
  }) async {
    final body = {
      'marque': data['marque'],
      'modele': data['modele'],
      'immatriculation': data['immatriculation'],
      'capacite': data['capacite'],
      'etat': data['etat'],
      'couleur': data['couleur'],
      'puissance': data['puissance'],
      'annee_service': data['annee_service'],
      'type_vehicule': data['type_vehicule'],
      'wilaya_mat': '',
      'type_mat': '',
      'serie_mat': '',
      'annee_mat': '',
    };
    try {
      final r = vehicule == null
          ? await http
              .post(
                Uri.parse(ApiConstants.vehicules),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $_token',
                },
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 10))
          : await http
              .put(
                Uri.parse('${ApiConstants.vehicules}/${vehicule['id']}'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $_token',
                },
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnack(
        jsonDecode(r.body)['message'] ?? 'Opération terminée',
        r.statusCode < 300,
      );
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
        backgroundColor: const Color(0xFF131324),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2A48)),
        ),
        title: const Text(
          'Supprimer ?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Supprimer "$marque" ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        Uri.parse('${ApiConstants.vehicules}/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

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
      backgroundColor: const Color(0xFF0B0B16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B16),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C38),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Véhicules',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_vehicules.length} véhicule(s)',
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.refresh, color: Color(0xFF8B5CF6), size: 20),
              onPressed: _load,
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'add_vehicule',
          onPressed: () => _showAjouterDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Ajouter',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Réessayer',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_vehicules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 70,
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text('Aucun véhicule',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur + pour en ajouter',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _vehicules.length,
      itemBuilder: (_, i) {
        final v = _vehicules[i];
        final etat = v['etat'] ?? 'actif';
        final ec = _etatColor(etat);
        final mat = v['immatriculation'] ?? '';
        final type = v['type_vehicule'] ?? '';
        final annee = v['annee_service'];
        final puiss = v['puissance'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131324),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v['marque'] ?? ''} ${v['modele'] ?? ''}'.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Matricule Badge (Purple theme)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              mat,
                              style: const TextStyle(
                                color: Color(0xFFC084FC),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _actionBtn(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showAjouterDialog(vehicule: v),
                        ),
                        const SizedBox(width: 8),
                        _actionBtn(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFEF4444),
                          onTap: () => _supprimer(
                            v['id'],
                            '${v['marque']} ${v['modele'] ?? ''}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Détails ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // État
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: ec.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_etatIcon(etat), color: ec, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                etat,
                                style: TextStyle(
                                  color: ec,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Type
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _infoChip(
                          Icons.event_seat_outlined,
                          '${v['capacite'] ?? '—'} places',
                          const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 16),
                        if (puiss != null) ...[
                          _infoChip(
                            Icons.speed_outlined,
                            '$puiss CV',
                            const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (annee != null)
                          _infoChip(
                            Icons.calendar_today_outlined,
                            '$annee',
                            const Color(0xFF94A3B8),
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

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 14),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      );

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
      backgroundColor:
          success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Color _etatColor(String e) {
    switch (e) {
      case 'actif':
        return const Color(0xFF10B981);
      case 'en panne':
        return const Color(0xFFEF4444);
      case 'en maintenance':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
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
      return const Color(0xFF8B5CF6);
    }
  }
}

// ══════════════════════════════════════════════════════
// PAGE FORMULAIRE — Design Violet / Purple
// ══════════════════════════════════════════════════════

class VehicleFormPage extends StatefulWidget {
  final Map? vehicule;
  final List<Color> couleurs;
  final List<String> typesVehicule;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const VehicleFormPage({
    super.key,
    this.vehicule,
    required this.couleurs,
    required this.typesVehicule,
    required this.onSave,
  });

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  static const Color _bg = Color(0xFF0B0B16);
  static const Color _card = Color(0xFF131324);
  static const Color _fieldFill = Color(0xFF191931);
  static const Color _fieldBorder = Color(0xFF2A2A48);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purple2 = Color(0xFF6366F1);
  static const Color _textSecondary = Color(0xFF94A3B8);

  final _marqueCtrl = TextEditingController();
  final _modeleCtrl = TextEditingController();
  final _capaciteCtrl = TextEditingController();
  final _puissanceCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();

  late Color _couleurSel;
  late String _typeVehicule;
  bool _saving = false;

  String? _marqueErr;
  String? _matriculeErr;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicule;
    _marqueCtrl.text = v?['marque'] ?? '';
    _modeleCtrl.text = v?['modele'] ?? '';
    _capaciteCtrl.text = v?['capacite']?.toString() ?? '30';
    _puissanceCtrl.text = v?['puissance']?.toString() ?? '';
    _anneeCtrl.text = v?['annee_service']?.toString() ?? '';
    _matriculeCtrl.text = v?['immatriculation'] ?? '';
    _typeVehicule = v?['type_vehicule'] ?? 'Bus';
    _couleurSel = _hexToColor(v?['couleur'] ?? '#8B5CF6');
  }

  @override
  void dispose() {
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _capaciteCtrl.dispose();
    _puissanceCtrl.dispose();
    _anneeCtrl.dispose();
    _matriculeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicule != null;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: _purple.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ═══ En-tête ═══
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_purple, _purple2],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: _purple.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.directions_bus_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit
                                      ? 'Modifier véhicule'
                                      : 'Ajouter véhicule',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isEdit
                                      ? 'Modifiez les informations du véhicule'
                                      : 'Enregistrez les informations du nouveau véhicule',
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ═══ Couleur ═══
                      const _Label('Couleur'),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                        itemCount: widget.couleurs.length,
                        itemBuilder: (_, i) {
                          final c = widget.couleurs[i];
                          final selected = _couleurSel == c;
                          return GestureDetector(
                            onTap: () => setState(() => _couleurSel = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: c.withOpacity(0.55),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? Icon(
                                      Icons.check,
                                      color: c.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 26),

                      // ═══ Matricule ═══
                      const _Label('Matricule (ex: XX-XX-X-XXXXX)'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _matriculeCtrl,
                        hint: 'ex: XX-XX-X-XXXXX',
                        icon: Icons.badge_outlined,
                        error: _matriculeErr,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Z0-9\-]')),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        onChanged: (_) => setState(() => _matriculeErr = null),
                      ),
                      const SizedBox(height: 20),

                      // ═══ Type de véhicule ═══
                      const _Label('Type de véhicule'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _fieldFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _fieldBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _typeVehicule,
                            dropdownColor: const Color(0xFF1C1C38),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: _textSecondary),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.directions_bus_outlined,
                                  color: _purple),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 14),
                            ),
                            items: widget.typesVehicule
                                .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style: const TextStyle(
                                            color: Colors.white))))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _typeVehicule = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ═══ Marque ═══
                      _buildField(
                        controller: _marqueCtrl,
                        hint: 'Marque *',
                        icon: Icons.verified_user_outlined,
                        error: _marqueErr,
                        onChanged: (_) => setState(() => _marqueErr = null),
                      ),
                      const SizedBox(height: 14),

                      // ═══ Modèle ═══
                      _buildField(
                        controller: _modeleCtrl,
                        hint: 'Modèle',
                        icon: Icons.directions_car_outlined,
                      ),
                      const SizedBox(height: 14),

                      // ═══ Capacité + Puissance ═══
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _capaciteCtrl,
                              hint: 'capacité',
                              labelInside: 'capacité',
                              icon: Icons.event_seat_outlined,
                              type: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _puissanceCtrl,
                              hint: 'Puissance',
                              labelInside: 'Puissance',
                              icon: Icons.speed_outlined,
                              type: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ═══ Année de service ═══
                      _buildField(
                        controller: _anneeCtrl,
                        hint: 'Année de service',
                        labelInside: 'Année de service',
                        icon: Icons.calendar_today_outlined,
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 26),

                      // ═══ Boutons ═══
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: _fieldBorder, width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [_purple, _purple2],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _purple.withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _saving ? null : _submit,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Center(
                                      child: _saving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              isEdit ? 'Modifier' : 'Ajouter',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? labelInside,
    TextInputType type = TextInputType.text,
    String? error,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null ? Colors.red : _fieldBorder,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _purple, size: 22),
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF5A5A78), fontSize: 14),
              labelText: labelInside,
              labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 5),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    bool valid = true;
    if (_marqueCtrl.text.trim().isEmpty) {
      setState(() => _marqueErr = 'La marque est obligatoire');
      valid = false;
    }
    final mat = _matriculeCtrl.text.trim();
    final matRegex = RegExp(r'^\d{2}-\d{2}-\d{1}-\d{4,5}$');
    if (mat.isEmpty) {
      setState(() => _matriculeErr = 'Le matricule est obligatoire');
      valid = false;
    } else if (!matRegex.hasMatch(mat)) {
      setState(() => _matriculeErr = 'Format invalide (ex: XX-XX-X-XXXXX)');
      valid = false;
    }
    if (!valid) return;

    setState(() => _saving = true);
    await widget.onSave({
      'marque': _marqueCtrl.text.trim(),
      'modele': _modeleCtrl.text.trim(),
      'immatriculation': mat,
      'capacite': int.tryParse(_capaciteCtrl.text) ?? 30,
      'puissance': int.tryParse(_puissanceCtrl.text),
      'annee_service': int.tryParse(_anneeCtrl.text),
      'type_vehicule': _typeVehicule,
      'couleur': _colorToHex(_couleurSel),
      'etat': widget.vehicule?['etat'] ?? 'actif',
    });
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
