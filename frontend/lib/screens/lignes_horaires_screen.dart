import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

/// ═════════════════════════════════════════════════════════════════════════════
/// APP BLUE THEME (Thème Bleu Sombre Royal avec Effet Glow)
/// ═════════════════════════════════════════════════════════════════════════════
class AppBlueTheme {
  static const Color background = Color(0xFF070C1B); // Fond principal bleu nuit
  static const Color surface = Color(0xFF0F172A); // Surface des cartes
  static const Color cardBorder = Color(0xFF1E293B); // Bordure subtile
  static const Color primaryBlue = Color(0xFF0284C7); // Bleu royal
  static const Color accentBlue = Color(0xFF3B82F6); // Bleu vif متوهج
  static const Color cyan = Color(0xFF06B6D4); // Cyan متألق
  static const Color purple = Color(0xFF8B5CF6); // Violet
  static const Color gold = Color(0xFFF59E0B); // Doré
  static const Color danger = Color(0xFFEF4444); // Rouge suppression
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;
}

/// ═════════════════════════════════════════════════════════════════════════════
/// 1. ECRAN PRINCIPAL : LIGNES & HORAIRES
/// ═════════════════════════════════════════════════════════════════════════════
class LignesHorairesScreen extends StatefulWidget {
  const LignesHorairesScreen({super.key});

  @override
  State<LignesHorairesScreen> createState() => _LignesHorairesScreenState();
}

class _LignesHorairesScreenState extends State<LignesHorairesScreen> {
  List<dynamic> _lignes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _token => context.read<AuthProvider>().user!.token;

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.lignes),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (r.statusCode == 200 && mounted) {
        final decoded = jsonDecode(r.body);
        if (decoded is List) {
          setState(() => _lignes = decoded);
        } else if (decoded is Map && decoded['lignes'] is List) {
          setState(() => _lignes = decoded['lignes']);
        } else if (decoded is Map && decoded['data'] is List) {
          setState(() => _lignes = decoded['data']);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showAjouterDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AjouterLigneSheet(token: _token),
    );
    if (result == true) _load();
  }

  Future<void> _ouvrirDetail(Map<String, dynamic> ligne) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LigneDetailScreen(
          ligne: ligne,
          token: _token,
          onRefresh: _load,
        ),
      ),
    );
  }

  String _fmtHeure(dynamic t) {
    if (t == null) return '--:--';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBlueTheme.background,
      appBar: _modernHeader(
        title: 'Lignes & Horaires',
        subtitle: '${_lignes.length} ligne(s)',
        onRefresh: _load,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppBlueTheme.accentBlue.withOpacity(0.55),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'add_ligne',
          onPressed: _showAjouterDialog,
          backgroundColor: AppBlueTheme.primaryBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Ajouter ligne',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppBlueTheme.cyan))
          : _lignes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 70, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('Aucune ligne disponible',
                          style: TextStyle(color: Colors.white38)),
                      SizedBox(height: 8),
                      Text('Appuyez sur + pour en ajouter une nouvelle',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppBlueTheme.cyan,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _lignes.length,
                    itemBuilder: (context, i) {
                      final item = _lignes[i];
                      if (item is! Map) return const SizedBox.shrink();
                      final l = Map<String, dynamic>.from(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _LigneCard(
                          ligne: l,
                          color: AppBlueTheme.cyan,
                          fmtHeure: _fmtHeure,
                          onTap: () => _ouvrirDetail(l),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// ── Carte d'une Ligne مع الشعاع والتوهج ──
class _LigneCard extends StatelessWidget {
  final Map<String, dynamic> ligne;
  final Color color;
  final String Function(dynamic) fmtHeure;
  final VoidCallback? onTap;

  const _LigneCard({
    required this.ligne,
    required this.color,
    required this.fmtHeure,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppBlueTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppBlueTheme.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppBlueTheme.accentBlue.withOpacity(0.18),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l['numero']?.toString() ?? '',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l['nom']?.toString() ?? l['numero']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppBlueTheme.cyan),
                      const SizedBox(width: 6),
                      Text(
                        '${fmtHeure(l['heure_debut'])} → ${fmtHeure(l['heure_fin'])}',
                        style: const TextStyle(
                          color: AppBlueTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppBlueTheme.accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppBlueTheme.accentBlue.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppBlueTheme.accentBlue,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════════
/// 2. ECRAN DETAIL : Ligne Detail Screen
/// ═════════════════════════════════════════════════════════════════════════════
class LigneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ligne;
  final String token;
  final VoidCallback onRefresh;

  const LigneDetailScreen({
    super.key,
    required this.ligne,
    required this.token,
    required this.onRefresh,
  });

  @override
  State<LigneDetailScreen> createState() => _LigneDetailScreenState();
}

class _LigneDetailScreenState extends State<LigneDetailScreen> {
  late Map<String, dynamic> _ligne;
  List<dynamic> _arrets = [];
  List<dynamic> _horaires = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ligne = Map<String, dynamic>.from(widget.ligne);
    _loadDetails();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final id = _ligne['id'];
      final results = await Future.wait([
        _get('${ApiConstants.lignes}/$id/arrets'),
        _get('${ApiConstants.lignes}/$id/horaires'),
      ]);
      if (mounted) {
        setState(() {
          _arrets = results[0];
          _horaires = results[1];
        });
      }
    } catch (e) {
      _snack('Erreur de chargement', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<dynamic>> _get(String url) async {
    try {
      final r = await http.get(Uri.parse(url), headers: _headers);
      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('arrets') && decoded['arrets'] is List) {
            return decoded['arrets'];
          } else if (decoded.containsKey('horaires') &&
              decoded['horaires'] is List) {
            return decoded['horaires'];
          } else if (decoded.containsKey('data') && decoded['data'] is List) {
            return decoded['data'];
          }
        }
      }
    } catch (_) {}
    return [];
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppBlueTheme.danger : Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<bool> _confirm(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(title: title, content: content),
    );
    return result == true;
  }

  Future<void> _showModifierDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppBlueTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ModifierLigneSheet(ligne: _ligne, headers: _headers),
    );
    if (result != null && mounted) {
      setState(() => _ligne = result);
      widget.onRefresh();
      _snack('Ligne modifiée ✅');
    }
  }

  Future<void> _ajouterArret() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppBlueTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AjouterArretSheet(
        ligneId: _ligne['id'] is int
            ? _ligne['id']
            : int.tryParse(_ligne['id'].toString()) ?? 0,
        ordre: _arrets.length,
        headers: _headers,
      ),
    );
    if (result != null && mounted) {
      setState(() => _arrets.add(result));
      _snack('Arrêt ajouté ✅');
    }
  }

  Future<void> _ajouterHoraire() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppBlueTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AjouterHoraireSheet(
        ligneId: _ligne['id'] is int
            ? _ligne['id']
            : int.tryParse(_ligne['id'].toString()) ?? 0,
        headers: _headers,
      ),
    );
    if (result != null && mounted) {
      setState(() => _horaires.add(result));
      _snack('Horaire ajouté ✅');
    }
  }

  Future<void> _supprimerLigne() async {
    if (!await _confirm('Supprimer la ligne ?',
        'Supprimer "${_ligne['nom']}" et toutes ses données ?')) return;
    final r = await http.delete(
      Uri.parse('${ApiConstants.lignes}/${_ligne['id']}'),
      headers: _headers,
    );
    if (!mounted) return;
    if (r.statusCode == 200) {
      widget.onRefresh();
      Navigator.pop(context);
      _snack('Ligne supprimée');
    } else {
      _snack('Erreur de suppression', isError: true);
    }
  }

  Future<void> _supprimerArret(int id) async {
    if (!await _confirm('Supprimer ?', 'Supprimer cet arrêt ?')) return;
    final r = await http.delete(
      Uri.parse('${ApiConstants.lignes}/${_ligne['id']}/arrets/$id'),
      headers: _headers,
    );
    if (r.statusCode == 200) {
      setState(() => _arrets.removeWhere((a) => (a is Map &&
          (a['id'] == id || a['id'].toString() == id.toString()))));
    }
  }

  Future<void> _supprimerHoraire(int id) async {
    if (!await _confirm('Supprimer ?', 'Supprimer cet horaire ?')) return;
    final r = await http.delete(
      Uri.parse('${ApiConstants.lignes}/${_ligne['id']}/horaires/$id'),
      headers: _headers,
    );
    if (r.statusCode == 200) {
      setState(() => _horaires.removeWhere((h) => (h is Map &&
          (h['id'] == id || h['id'].toString() == id.toString()))));
    }
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _ligne;

    return Scaffold(
      backgroundColor: AppBlueTheme.background,
      appBar: AppBar(
        backgroundColor: AppBlueTheme.surface,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const BackButton(color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l['nom']?.toString() ?? l['numero']?.toString() ?? 'Détail',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Ligne ${l['numero']?.toString() ?? ''}',
              style: const TextStyle(color: AppBlueTheme.cyan, fontSize: 11),
            ),
          ],
        ),
        actions: [
          _actionBtn(
              Icons.edit_rounded, AppBlueTheme.accentBlue, _showModifierDialog),
          const SizedBox(width: 8),
          _actionBtn(Icons.delete_outline_rounded, AppBlueTheme.danger,
              _supprimerLigne),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppBlueTheme.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    ligne: l,
                    arrets: _arrets,
                    horaires: _horaires,
                    cyan: AppBlueTheme.cyan,
                    blue: AppBlueTheme.accentBlue,
                    purple: AppBlueTheme.purple,
                  ),
                  const SizedBox(height: 24),
                  _SectionArrets(
                    arrets: _arrets,
                    teal: AppBlueTheme.cyan,
                    purple: AppBlueTheme.purple,
                    onDelete: _supprimerArret,
                    onAdd: _ajouterArret,
                  ),
                  const SizedBox(height: 24),
                  _SectionHoraires(
                    horaires: _horaires,
                    teal: AppBlueTheme.cyan,
                    purple: AppBlueTheme.purple,
                    amber: AppBlueTheme.gold,
                    onDelete: _supprimerHoraire,
                    onAdd: _ajouterHoraire,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

/// ── Info Card ──
class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> ligne;
  final List<dynamic> arrets, horaires;
  final Color cyan, blue, purple;

  const _InfoCard({
    required this.ligne,
    required this.arrets,
    required this.horaires,
    required this.cyan,
    required this.blue,
    required this.purple,
  });

  String _fmtHeure(dynamic t) {
    if (t == null) return '--:--';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppBlueTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppBlueTheme.accentBlue.withOpacity(0.15),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cyan.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    l['numero']?.toString() ?? '',
                    style: TextStyle(
                      color: cyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l['nom']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 13, color: AppBlueTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmtHeure(l['heure_debut'])} → ${_fmtHeure(l['heure_fin'])}',
                          style: const TextStyle(
                              color: AppBlueTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.location_on,
                  value: '${arrets.length}',
                  label: 'Arrêts',
                  accent: cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  icon: Icons.schedule,
                  value: '${horaires.length}',
                  label: 'Horaires',
                  accent: purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color accent;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppBlueTheme.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: AppBlueTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// ── Section Header ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onAdd;
  final Color teal, addColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.onAdd,
    required this.teal,
    required this.addColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: teal, size: 19),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: teal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: teal, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: addColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: addColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.add, color: addColor, size: 15),
                const SizedBox(width: 4),
                Text('Ajouter',
                    style: TextStyle(
                        color: addColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionArrets extends StatelessWidget {
  final List<dynamic> arrets;
  final Color teal, purple;
  final Function(int) onDelete;
  final VoidCallback onAdd;

  const _SectionArrets({
    required this.arrets,
    required this.teal,
    required this.purple,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Arrêts',
          icon: Icons.location_on,
          count: arrets.length,
          onAdd: onAdd,
          teal: teal,
          addColor: AppBlueTheme.primaryBlue,
        ),
        const SizedBox(height: 12),
        if (arrets.isEmpty)
          _EmptyBox(
              msg: 'Aucun arrêt',
              onAdd: onAdd,
              addLabel: 'Ajouter le premier arrêt')
        else
          ...arrets.asMap().entries.map((e) {
            final item = e.value;
            if (item is! Map) return const SizedBox.shrink();
            final a = Map<String, dynamic>.from(item);
            final itemId = a['id'] is int
                ? a['id'] as int
                : int.tryParse(a['id']?.toString() ?? '0') ?? 0;
            return _ArretItem(
              index: e.key,
              arret: a,
              teal: teal,
              onDelete: () => onDelete(itemId),
            );
          }),
      ],
    );
  }
}

class _ArretItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> arret;
  final Color teal;
  final VoidCallback onDelete;

  const _ArretItem({
    required this.index,
    required this.arret,
    required this.teal,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasGps = arret['lat'] != null && arret['lng'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppBlueTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                    color: teal, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arret['nom']?.toString() ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                if (hasGps)
                  Text(
                    'GPS: ${arret['lat']}, ${arret['lng']}',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (hasGps)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 16),
            ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded,
                  color: AppBlueTheme.danger, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHoraires extends StatelessWidget {
  final List<dynamic> horaires;
  final Color teal, purple, amber;
  final Function(int) onDelete;
  final VoidCallback onAdd;

  const _SectionHoraires({
    required this.horaires,
    required this.teal,
    required this.purple,
    required this.amber,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Horaires',
          icon: Icons.schedule,
          count: horaires.length,
          onAdd: onAdd,
          teal: purple,
          addColor: purple,
        ),
        const SizedBox(height: 12),
        if (horaires.isEmpty)
          _EmptyBox(
              msg: 'Aucun horaire',
              onAdd: onAdd,
              addLabel: 'Ajouter le premier horaire')
        else
          ...horaires.map((h) {
            if (h is! Map) return const SizedBox.shrink();
            final horaireMap = Map<String, dynamic>.from(h);
            final itemId = horaireMap['id'] is int
                ? horaireMap['id'] as int
                : int.tryParse(horaireMap['id']?.toString() ?? '0') ?? 0;
            return _HoraireItem(
              horaire: horaireMap,
              teal: teal,
              amber: amber,
              onDelete: () => onDelete(itemId),
            );
          }),
      ],
    );
  }
}

class _HoraireItem extends StatelessWidget {
  final Map<String, dynamic> horaire;
  final Color teal, amber;
  final VoidCallback onDelete;

  const _HoraireItem({
    required this.horaire,
    required this.teal,
    required this.amber,
    required this.onDelete,
  });

  String _fmt(dynamic t) {
    if (t == null) return '--:--';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    final estRetour =
        horaire['type'] == 'retour' || horaire['est_retour'] == true;
    final color = estRetour ? amber : teal;
    final icon = estRetour ? Icons.arrow_back : Icons.arrow_forward;

    dynamic jRaw = horaire['jours'] ?? horaire['jours_semaine'];
    String jours = '';
    if (jRaw is String) {
      jours = jRaw;
    } else if (jRaw is List) {
      const labels = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      jours = jRaw
          .map((j) {
            final idx = j is int ? j : int.tryParse(j.toString()) ?? 0;
            return (idx > 0 && idx < labels.length) ? labels[idx] : '';
          })
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppBlueTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${horaire['point_depart'] ?? horaire['depart'] ?? ''} → ${horaire['point_arrivee'] ?? horaire['arrivee'] ?? ''}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(horaire['heure_depart'])} → ${_fmt(horaire['heure_arrivee'])}',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (jours.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(jours,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded,
                  color: AppBlueTheme.danger, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String msg;
  final VoidCallback? onAdd;
  final String? addLabel;

  const _EmptyBox({required this.msg, this.onAdd, this.addLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppBlueTheme.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 36, color: Colors.white24),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppBlueTheme.primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppBlueTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add,
                        color: AppBlueTheme.primaryBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      addLabel ?? 'Ajouter',
                      style: const TextStyle(
                        color: AppBlueTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, content;

  const _ConfirmDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppBlueTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppBlueTheme.danger),
          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════════
/// 3. DATA CLASSES & BOTTOM SHEETS D'AJOUT MULTI-ÉTAPES AVEC VALIDATION STRICTE FORMAT L12
/// ═════════════════════════════════════════════════════════════════════════════

class _ArretData {
  final TextEditingController nomCtrl = TextEditingController();
  double? lat, lng;
  _ArretData({String nom = ''}) {
    nomCtrl.text = nom;
  }
  void dispose() => nomCtrl.dispose();
}

class _CourseData {
  String type;
  final TextEditingController pointDepartCtrl = TextEditingController();
  final TextEditingController pointArriveeCtrl = TextEditingController();
  final TextEditingController heureDepartCtrl = TextEditingController();
  final TextEditingController heureArriveeCtrl = TextEditingController();
  double? departLat, departLng, arriveeLat, arriveeLng;
  List<int> jours;
  _CourseData({this.type = 'aller'}) : jours = [1, 2, 3, 4, 5, 6, 7];
  void dispose() {
    pointDepartCtrl.dispose();
    pointArriveeCtrl.dispose();
    heureDepartCtrl.dispose();
    heureArriveeCtrl.dispose();
  }
}

class _AjouterLigneSheet extends StatefulWidget {
  final String token;
  const _AjouterLigneSheet({required this.token});

  @override
  State<_AjouterLigneSheet> createState() => _AjouterLigneSheetState();
}

class _AjouterLigneSheetState extends State<_AjouterLigneSheet> {
  int _etape = 0;
  final _numCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _debCtrl = TextEditingController(text: '06:00');
  final _finCtrl = TextEditingController(text: '22:00');
  final List<_ArretData> _arrets = [_ArretData()];
  final List<_CourseData> _courses = [_CourseData(type: 'aller')];
  bool _loading = false;

  @override
  void dispose() {
    _numCtrl.dispose();
    _nomCtrl.dispose();
    _debCtrl.dispose();
    _finCtrl.dispose();
    for (final a in _arrets) a.dispose();
    for (final c in _courses) c.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppBlueTheme.danger : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  Future<({double lat, double lng})?> _saisiGps(String titre) async {
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    return showDialog<({double lat, double lng})>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppBlueTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniField(
                latCtrl,
                'Latitude (ex: 36.4501)',
                const TextInputType.numberWithOptions(
                    signed: true, decimal: true)),
            const SizedBox(height: 10),
            _miniField(
                lngCtrl,
                'Longitude (ex: 6.2644)',
                const TextInputType.numberWithOptions(
                    signed: true, decimal: true)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppBlueTheme.primaryBlue),
            onPressed: () {
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (lat == null || lng == null) return;
              Navigator.pop(ctx, (lat: lat, lng: lng));
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickTime(String initial) async {
    final parts = initial.split(':');
    final init = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppBlueTheme.cyan),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  void _ajouterCourse() {
    final last = _courses.last;
    final type = last.type == 'aller' ? 'retour' : 'aller';
    final newC = _CourseData(type: type);
    newC.pointDepartCtrl.text = last.pointArriveeCtrl.text;
    newC.pointArriveeCtrl.text = last.pointDepartCtrl.text;
    newC.departLat = last.arriveeLat;
    newC.departLng = last.arriveeLng;
    newC.arriveeLat = last.departLat;
    newC.arriveeLng = last.departLng;
    newC.jours = List<int>.from(last.jours);
    setState(() => _courses.add(newC));
  }

  /// 🛑 التحقق الصارم من صيغة رقم الخط (L12) وصيغة الاتجاه (A → B)
  bool _validerChampsEtape0() {
    String numText = _numCtrl.text.trim();
    if (numText.isEmpty) {
      _snack('يرجى إدخال رقم الخط (مثال: L12)', isError: true);
      return false;
    }

    // إذا كتب المستخدم l12 تحول تلقائياً إلى L12
    if (numText.startsWith('l')) {
      numText = 'L' + numText.substring(1);
      _numCtrl.text = numText;
    }

    // ⛔ التحقق من أن رقم الخط يبدأ بحرف L متبوعاً بأرقام فقط (مثال: L12, L1, L105)
    final numRegex = RegExp(r'^L\d+$');
    if (!numRegex.hasMatch(numText)) {
      _snack(
        'خطأ: رقم الخط يجب أن يكون بالشكل L12 (حرف L متبوعاً بأرقام فقط، مثال: L12, L1, L22)',
        isError: true,
      );
      return false;
    }

    String nomText = _nomCtrl.text.trim();
    if (nomText.isEmpty) {
      _snack('Veuillez saisir le nom de la police (exemple : A → B)', isError: true);
      return false;
    }

    // تحويل الشرطة العادية إلى سهم تلقائياً إذا وجدت
    if (!nomText.contains('→') &&
        !nomText.contains('->') &&
        nomText.contains('-')) {
      nomText = nomText.replaceAll('-', '→');
      _nomCtrl.text = nomText;
    }

    // ⛔ التحقق من وجود سهم في اسم الخط
    final hasArrow = nomText.contains('->') ||
        nomText.contains('→') ||
        nomText.contains('=>') ||
        nomText.contains(' - ');

    if (!hasArrow) {
      _snack(
        'خطأ: يجب أن يحتوي اسم الخط على سهم من نقطة الذهاب للوصول (مثال: Mila → Constantine أو A -> B)',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Future<void> _soumettre() async {
    if (!_validerChampsEtape0()) return;

    setState(() => _loading = true);
    try {
      final rLigne = await http.post(
        Uri.parse(ApiConstants.lignes),
        headers: _headers,
        body: jsonEncode({
          'numero': _numCtrl.text.trim(),
          'nom': _nomCtrl.text.trim(),
          'heure_debut': _debCtrl.text.trim(),
          'heure_fin': _finCtrl.text.trim(),
        }),
      );

      if (rLigne.statusCode != 201) {
        _snack(
            jsonDecode(rLigne.body)['message'] ??
                'Erreur lors de la création de la ligne',
            isError: true);
        setState(() => _loading = false);
        return;
      }

      final ligneId = jsonDecode(rLigne.body)['ligne']['id'] as int;

      for (int i = 0; i < _arrets.length; i++) {
        final a = _arrets[i];
        if (a.nomCtrl.text.trim().isEmpty) continue;
        await http.post(
          Uri.parse('${ApiConstants.lignes}/$ligneId/arrets'),
          headers: _headers,
          body: jsonEncode({
            'nom': a.nomCtrl.text.trim(),
            'ordre': i,
            if (a.lat != null) 'lat': a.lat,
            if (a.lng != null) 'lng': a.lng,
          }),
        );
      }

      for (final c in _courses) {
        if (c.heureDepartCtrl.text.trim().isEmpty) continue;
        await http.post(
          Uri.parse('${ApiConstants.lignes}/$ligneId/horaires'),
          headers: _headers,
          body: jsonEncode({
            'type': c.type,
            'point_depart': c.pointDepartCtrl.text.trim(),
            'point_arrivee': c.pointArriveeCtrl.text.trim(),
            'heure_depart': c.heureDepartCtrl.text.trim(),
            'heure_arrivee': c.heureArriveeCtrl.text.trim(),
            'jours': c.jours,
            if (c.departLat != null) 'depart_lat': c.departLat,
            if (c.departLng != null) 'depart_lng': c.departLng,
            if (c.arriveeLat != null) 'arrivee_lat': c.arriveeLat,
            if (c.arriveeLng != null) 'arrivee_lng': c.arriveeLng,
          }),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      _snack('Ligne créée avec succès ✅');
    } catch (e) {
      _snack('Erreur réseau lors de l\'enregistrement', isError: true);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppBlueTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildStepper(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _etape == 0
                  ? _buildEtape0()
                  : _etape == 1
                      ? _buildEtape1()
                      : _buildEtape2(),
            ),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Infos', 'Arrêts', 'Horaires'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final passed = (i ~/ 2) < _etape;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: passed ? AppBlueTheme.primaryBlue : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < _etape;
          final active = idx == _etape;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (done || active)
                      ? AppBlueTheme.primaryBlue
                      : AppBlueTheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppBlueTheme.primaryBlue.withOpacity(0.55),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: active ? Colors.white : Colors.white38,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[idx],
                style: TextStyle(
                  color: active ? AppBlueTheme.cyan : Colors.white38,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEtape0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 1: Informations de la ligne',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _field(_numCtrl, 'Numéro de ligne (ex: L12, L1)', Icons.tag),
        const SizedBox(height: 4),
        const Text(
          '⚠️ Le format numérique est obligatoire : L suivi des chiffres (exemple : L12, L1, L22)',
          style: TextStyle(
              color: Color.fromARGB(255, 16, 135, 154),
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        _field(_nomCtrl, 'Nom (ex: Mila → Constantine)', Icons.route),
        const SizedBox(height: 4),
        const Text(
          '⚠️ اسم الخط يجب أن يحتوي على سهم بين الذهاب والوصول (مثال: A → B)',
          style: TextStyle(
              color: AppBlueTheme.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 18),
        const Text('Horaires d\'exploitation',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _timeBox(_debCtrl, 'Heure début')),
            const SizedBox(width: 12),
            Expanded(child: _timeBox(_finCtrl, 'Heure fin')),
          ],
        ),
      ],
    );
  }

  Widget _buildEtape1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 2: Arrêts de la ligne',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Ajoutez les stations dans l\'ordre (départ → arrivée)',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 14),
        ..._arrets.asMap().entries.map((e) {
          final idx = e.key;
          final a = e.value;
          final hasGps = a.lat != null && a.lng != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppBlueTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppBlueTheme.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppBlueTheme.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                          color: AppBlueTheme.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: a.nomCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Nom de l\'arrêt',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final r = await _saisiGps('GPS — Arrêt ${idx + 1}');
                    if (r != null) {
                      setState(() {
                        a.lat = r.lat;
                        a.lng = r.lng;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasGps
                          ? Colors.greenAccent.withOpacity(0.15)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.gps_fixed,
                      size: 18,
                      color: hasGps ? Colors.greenAccent : Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (_arrets.length > 1)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        a.dispose();
                        _arrets.removeAt(idx);
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          color: AppBlueTheme.danger, size: 18),
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppBlueTheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => setState(() => _arrets.add(_ArretData())),
          icon: const Icon(Icons.add_location_alt_rounded,
              color: AppBlueTheme.cyan),
          label: const Text('Ajouter un arrêt',
              style: TextStyle(
                  color: AppBlueTheme.cyan, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildEtape2() {
    const jourLabels = ['L', 'M', 'Me', 'J', 'V', 'S', 'D'];
    final joursCommuns =
        _courses.isNotEmpty ? _courses.first.jours : [1, 2, 3, 4, 5, 6, 7];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 3: Horaires & Courses',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Jours de service',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (j) {
            final jourNum = j + 1;
            final selected = joursCommuns.contains(jourNum);
            return GestureDetector(
              onTap: () => setState(() {
                for (final c in _courses) {
                  if (selected) {
                    c.jours.remove(jourNum);
                  } else {
                    c.jours.add(jourNum);
                    c.jours.sort();
                  }
                }
              }),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? AppBlueTheme.primaryBlue
                      : AppBlueTheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: AppBlueTheme.primaryBlue.withOpacity(0.4),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    jourLabels[j],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white38,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        ...List.generate(_courses.length, (i) {
          final c = _courses[i];
          final isAller = c.type == 'aller';
          final color = isAller ? AppBlueTheme.cyan : AppBlueTheme.purple;
          final icon =
              isAller ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
          final label =
              isAller ? 'ALLER ${(i ~/ 2) + 1}' : 'RETOUR ${(i ~/ 2) + 1}';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppBlueTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_courses.length > 1)
                      GestureDetector(
                        onTap: () => setState(() {
                          c.dispose();
                          _courses.removeAt(i);
                          for (int j = i; j < _courses.length; j++) {
                            _courses[j].type =
                                (j % 2 == 0) ? 'aller' : 'retour';
                          }
                        }),
                        child: const Icon(Icons.close,
                            color: Colors.white38, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(c.pointDepartCtrl, 'Point de départ',
                    Icons.trip_origin_rounded),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _timeTile(c.heureDepartCtrl, 'Heure départ',
                          () async {
                        final t = await _pickTime(c.heureDepartCtrl.text);
                        if (t != null)
                          setState(() => c.heureDepartCtrl.text = t);
                      }),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final r = await _saisiGps('GPS départ — $label');
                        if (r != null) {
                          setState(() {
                            c.departLat = r.lat;
                            c.departLng = r.lng;
                          });
                        }
                      },
                      child: _gpsIcon(c.departLat != null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(c.pointArriveeCtrl, 'Point d\'arrivée',
                    Icons.place_rounded),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _timeTile(c.heureArriveeCtrl, 'Heure arrivée',
                          () async {
                        final t = await _pickTime(c.heureArriveeCtrl.text);
                        if (t != null)
                          setState(() => c.heureArriveeCtrl.text = t);
                      }),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final r = await _saisiGps('GPS arrivée — $label');
                        if (r != null) {
                          setState(() {
                            c.arriveeLat = r.lat;
                            c.arriveeLng = r.lng;
                          });
                        }
                      },
                      child: _gpsIcon(c.arriveeLat != null),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        ElevatedButton.icon(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppBlueTheme.surface),
          onPressed: _ajouterCourse,
          icon: Icon(
            _courses.last.type == 'aller' ? Icons.add : Icons.add,
            color: AppBlueTheme.purple,
          ),
          label: Text(
            _courses.last.type == 'aller' ? 'Ajouter retour' : 'Ajouter aller',
            style: const TextStyle(
                color: AppBlueTheme.purple, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_etape > 0) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppBlueTheme.cardBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => setState(() => _etape--),
                child: const Text('Retour',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppBlueTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _etape == 2
                      ? Colors.green.shade600
                      : AppBlueTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading
                    ? null
                    : () {
                        if (_etape == 0) {
                          if (!_validerChampsEtape0()) return;
                          setState(() => _etape = 1);
                        } else if (_etape == 1) {
                          setState(() => _etape = 2);
                        } else {
                          _soumettre();
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _etape == 2 ? 'Enregistrer' : 'Suivant',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _etape < 2
                                ? Icons.arrow_forward_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBlueTheme.cardBorder),
      ),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icon, color: AppBlueTheme.cyan, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
      ),
    );
  }

  Widget _timeBox(TextEditingController c, String label) {
    return GestureDetector(
      onTap: () async {
        final t = await _pickTime(c.text);
        if (t != null) setState(() => c.text = t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppBlueTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppBlueTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppBlueTheme.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: AppBlueTheme.cyan, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(c.text.isEmpty ? '--:--' : c.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(TextEditingController c, String hint, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppBlueTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppBlueTheme.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: AppBlueTheme.cyan, size: 18),
            const SizedBox(width: 8),
            Text(
              c.text.isEmpty ? hint : c.text,
              style: TextStyle(
                color: c.text.isEmpty ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gpsIcon(bool hasGps) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasGps ? Colors.greenAccent.withOpacity(0.15) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.gps_fixed,
        size: 18,
        color: hasGps ? Colors.greenAccent : Colors.white38,
      ),
    );
  }

  Widget _miniField(TextEditingController c, String hint, TextInputType type) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: AppBlueTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}

/// ── Bottom Sheet Modifier Ligne ──
class _ModifierLigneSheet extends StatefulWidget {
  final Map<String, dynamic> ligne;
  final Map<String, String> headers;

  const _ModifierLigneSheet({required this.ligne, required this.headers});

  @override
  State<_ModifierLigneSheet> createState() => _ModifierLigneSheetState();
}

class _ModifierLigneSheetState extends State<_ModifierLigneSheet> {
  late final TextEditingController numCtrl, nomCtrl, debCtrl, finCtrl;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final l = widget.ligne;
    numCtrl = TextEditingController(text: l['numero']?.toString() ?? '');
    nomCtrl = TextEditingController(text: l['nom']?.toString() ?? '');
    debCtrl = TextEditingController(text: _fmt(l['heure_debut']));
    finCtrl = TextEditingController(text: _fmt(l['heure_fin']));
  }

  String _fmt(dynamic t) {
    if (t == null) return '06:00';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  void dispose() {
    numCtrl.dispose();
    nomCtrl.dispose();
    debCtrl.dispose();
    finCtrl.dispose();
    super.dispose();
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
        minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      ),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppBlueTheme.cyan),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppBlueTheme.danger : Colors.green.shade700,
    ));
  }

  Future<void> _save() async {
    String numText = numCtrl.text.trim();
    if (numText.isEmpty) {
      _snack('Numéro obligatoire', isError: true);
      return;
    }

    if (numText.startsWith('l')) {
      numText = 'L' + numText.substring(1);
      numCtrl.text = numText;
    }

    final numRegex = RegExp(r'^L\d+$');
    if (!numRegex.hasMatch(numText)) {
      _snack('Le numéro de ligne doit être au format L12 (ex: L12, L1, L22)',
          isError: true);
      return;
    }

    String nomText = nomCtrl.text.trim();
    if (nomText.isEmpty) {
      _snack('Nom obligatoire', isError: true);
      return;
    }

    if (!nomText.contains('→') &&
        !nomText.contains('->') &&
        nomText.contains('-')) {
      nomText = nomText.replaceAll('-', '→');
      nomCtrl.text = nomText;
    }

    final hasArrow = nomText.contains('->') ||
        nomText.contains('→') ||
        nomText.contains('=>') ||
        nomText.contains(' - ');
    if (!hasArrow) {
      _snack(
          'اسم الخط يجب أن يحتوي على سهم من نقطة الذهاب للوصول (مثال: Mila → Constantine)',
          isError: true);
      return;
    }

    setState(() => loading = true);
    final body = {
      'numero': numText,
      'nom': nomText,
      'heure_debut': debCtrl.text.trim(),
      'heure_fin': finCtrl.text.trim(),
    };
    final r = await http.put(
      Uri.parse('${ApiConstants.lignes}/${widget.ligne['id']}'),
      headers: widget.headers,
      body: jsonEncode(body),
    );
    setState(() => loading = false);
    if (!mounted) return;
    if (r.statusCode == 200) {
      final decoded = jsonDecode(r.body);
      final updatedLigne = decoded is Map &&
              decoded.containsKey('ligne') &&
              decoded['ligne'] is Map
          ? Map<String, dynamic>.from(decoded['ligne'])
          : body;
      Navigator.pop(context, updatedLigne);
    } else {
      _snack(jsonDecode(r.body)['message'] ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Modifier la ligne',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _field(numCtrl, 'Numéro (ex: L12)', Icons.tag),
            const SizedBox(height: 10),
            _field(nomCtrl, 'Nom / Description (ex: Mila → Constantine)',
                Icons.route),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _timeTile(debCtrl, 'Heure début', () async {
                    final t = await _pickTime(debCtrl.text);
                    if (t != null) setState(() => debCtrl.text = t);
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeTile(finCtrl, 'Heure fin', () async {
                    final t = await _pickTime(finCtrl.text);
                    if (t != null) setState(() => finCtrl.text = t);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppBlueTheme.primaryBlue),
                onPressed: loading ? null : _save,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppBlueTheme.cyan, size: 20),
        filled: true,
        fillColor: AppBlueTheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _timeTile(TextEditingController c, String hint, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: AppBlueTheme.surface,
            borderRadius: BorderRadius.circular(12)),
        child: Text(c.text.isEmpty ? hint : c.text,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// ── Bottom Sheet Ajouter Arrêt ──
class _AjouterArretSheet extends StatefulWidget {
  final int ligneId, ordre;
  final Map<String, String> headers;

  const _AjouterArretSheet(
      {required this.ligneId, required this.ordre, required this.headers});

  @override
  State<_AjouterArretSheet> createState() => _AjouterArretSheetState();
}

class _AjouterArretSheetState extends State<_AjouterArretSheet> {
  final _nomCtrl = TextEditingController();
  double? _lat, _lng;
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppBlueTheme.danger : Colors.green.shade700,
    ));
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      _snack("Nom de l'arrêt obligatoire", isError: true);
      return;
    }
    setState(() => _loading = true);
    final r = await http.post(
      Uri.parse('${ApiConstants.lignes}/${widget.ligneId}/arrets'),
      headers: widget.headers,
      body: jsonEncode({
        'nom': _nomCtrl.text.trim(),
        'ordre': widget.ordre,
        if (_lat != null) 'lat': _lat,
        if (_lng != null) 'lng': _lng,
      }),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (r.statusCode == 201) {
      final decoded = jsonDecode(r.body);
      final arretMap = decoded is Map &&
              decoded.containsKey('arret') &&
              decoded['arret'] is Map
          ? Map<String, dynamic>.from(decoded['arret'])
          : {
              'nom': _nomCtrl.text.trim(),
              'ordre': widget.ordre,
              'lat': _lat,
              'lng': _lng,
              'id': DateTime.now().millisecondsSinceEpoch
            };
      Navigator.pop(context, arretMap);
    } else {
      _snack(jsonDecode(r.body)['message'] ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajouter un arrêt',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nomCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Nom de l'arrêt (ex: Ain smara)",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.location_on, color: AppBlueTheme.cyan),
              filled: true,
              fillColor: AppBlueTheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppBlueTheme.primaryBlue),
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Ajouter',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Bottom Sheet Ajouter Horaire ──
class _AjouterHoraireSheet extends StatefulWidget {
  final int ligneId;
  final Map<String, String> headers;

  const _AjouterHoraireSheet({required this.ligneId, required this.headers});

  @override
  State<_AjouterHoraireSheet> createState() => _AjouterHoraireSheetState();
}

class _AjouterHoraireSheetState extends State<_AjouterHoraireSheet> {
  final _departCtrl = TextEditingController();
  final _arriveeCtrl = TextEditingController();
  final _hDepartCtrl = TextEditingController();
  final _hArriveeCtrl = TextEditingController();
  bool _estRetour = false;
  final List<int> _jours = [1, 2, 3, 4, 5, 6, 7];
  bool _loading = false;

  @override
  void dispose() {
    _departCtrl.dispose();
    _arriveeCtrl.dispose();
    _hDepartCtrl.dispose();
    _hArriveeCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppBlueTheme.danger : Colors.green.shade700,
    ));
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
        minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      ),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppBlueTheme.cyan),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_departCtrl.text.trim().isEmpty ||
        _hDepartCtrl.text.trim().isEmpty ||
        _arriveeCtrl.text.trim().isEmpty ||
        _hArriveeCtrl.text.trim().isEmpty) {
      _snack('Tous les champs sont obligatoires', isError: true);
      return;
    }
    setState(() => _loading = true);
    final r = await http.post(
      Uri.parse('${ApiConstants.lignes}/${widget.ligneId}/horaires'),
      headers: widget.headers,
      body: jsonEncode({
        'type': _estRetour ? 'retour' : 'aller',
        'point_depart': _departCtrl.text.trim(),
        'heure_depart': _hDepartCtrl.text.trim(),
        'point_arrivee': _arriveeCtrl.text.trim(),
        'heure_arrivee': _hArriveeCtrl.text.trim(),
        'jours': _jours,
      }),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (r.statusCode == 201) {
      final decoded = jsonDecode(r.body);
      final horaireMap = decoded is Map &&
              decoded.containsKey('horaire') &&
              decoded['horaire'] is Map
          ? Map<String, dynamic>.from(decoded['horaire'])
          : {
              'type': _estRetour ? 'retour' : 'aller',
              'point_depart': _departCtrl.text.trim(),
              'heure_depart': _hDepartCtrl.text.trim(),
              'point_arrivee': _arriveeCtrl.text.trim(),
              'heure_arrivee': _hArriveeCtrl.text.trim(),
              'jours': _jours,
              'id': DateTime.now().millisecondsSinceEpoch,
            };
      Navigator.pop(context, horaireMap);
    } else {
      _snack(jsonDecode(r.body)['message'] ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajouter un horaire',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Aller'),
                    selected: !_estRetour,
                    onSelected: (v) => setState(() => _estRetour = !v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Retour'),
                    selected: _estRetour,
                    onSelected: (v) => setState(() => _estRetour = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_departCtrl, 'Point de départ', Icons.trip_origin),
            const SizedBox(height: 8),
            _timeTile(_hDepartCtrl, 'Heure départ', () async {
              final t = await _pickTime(_hDepartCtrl.text);
              if (t != null) setState(() => _hDepartCtrl.text = t);
            }),
            const SizedBox(height: 12),
            _field(_arriveeCtrl, 'Point d \'arrivée', Icons.place),
            const SizedBox(height: 8),
            _timeTile(_hArriveeCtrl, 'Heure arrivée', () async {
              final t = await _pickTime(_hArriveeCtrl.text);
              if (t != null) setState(() => _hArriveeCtrl.text = t);
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppBlueTheme.primaryBlue),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajouter',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppBlueTheme.purple, size: 20),
        filled: true,
        fillColor: AppBlueTheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _timeTile(TextEditingController c, String hint, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: AppBlueTheme.surface,
            borderRadius: BorderRadius.circular(12)),
        child: Text(c.text.isEmpty ? hint : c.text,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
