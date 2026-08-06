import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import 'modifier_screens.dart';

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

  // ════════════════════════════════════════
  // DATA LOADING
  // ════════════════════════════════════════

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
    final r = await http.get(Uri.parse(url), headers: _headers);
    return r.statusCode == 200 ? jsonDecode(r.body) : [];
  }

  // ════════════════════════════════════════
  // SNACKBAR
  // ════════════════════════════════════════

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

  // ════════════════════════════════════════
  // CONFIRM DIALOG
  // ════════════════════════════════════════

  Future<bool> _confirm(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(title: title, content: content),
    );
    return result == true;
  }

  // ════════════════════════════════════════
  // MODIFIER LIGNE
  // ════════════════════════════════════════

  Future<void> _showModifierDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
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

  // ════════════════════════════════════════
  // AJOUTER ARRÊT
  // ════════════════════════════════════════

  Future<void> _ajouterArret() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AjouterArretSheet(
        ligneId: _ligne['id'],
        ordre: _arrets.length,
        headers: _headers,
      ),
    );
    if (result != null && mounted) {
      setState(() => _arrets.add(result));
      _snack('Arrêt ajouté ✅');
    }
  }

  // ════════════════════════════════════════
  // MODIFIER ARRÊT
  // ════════════════════════════════════════

  Future<void> _modifierArret(Map<String, dynamic> arret) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifierArretScreen(
          arret: arret,
          ligneId: _ligne['id'],
          headers: _headers,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        final idx = _arrets.indexWhere((a) => a['id'] == result['id']);
        if (idx >= 0) _arrets[idx] = result;
      });
      _snack('Arrêt modifié ✅');
    }
  }

  // ════════════════════════════════════════
  // AJOUTER HORAIRE
  // ════════════════════════════════════════

  Future<void> _ajouterHoraire() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AjouterHoraireSheet(
        ligneId: _ligne['id'],
        headers: _headers,
      ),
    );
    if (result != null && mounted) {
      setState(() => _horaires.add(result));
      _snack('Horaire ajouté ✅');
    }
  }

  // ════════════════════════════════════════
  // MODIFIER HORAIRE
  // ════════════════════════════════════════

  Future<void> _modifierHoraire(Map<String, dynamic> horaire) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifierHoraireScreen(
          horaire: horaire,
          ligneId: _ligne['id'],
          headers: _headers,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        final idx = _horaires.indexWhere((h) => h['id'] == result['id']);
        if (idx >= 0) _horaires[idx] = result;
      });
      _snack('Horaire modifié ✅');
    }
  }

  // ════════════════════════════════════════
  // DELETE ACTIONS
  // ════════════════════════════════════════

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
    if (r.statusCode == 200)
      setState(() => _arrets.removeWhere((a) => a['id'] == id));
  }

  Future<void> _supprimerHoraire(int id) async {
    if (!await _confirm('Supprimer ?', 'Supprimer cet horaire ?')) return;
    final r = await http.delete(
      Uri.parse('${ApiConstants.lignes}/${_ligne['id']}/horaires/$id'),
      headers: _headers,
    );
    if (r.statusCode == 200)
      setState(() => _horaires.removeWhere((h) => h['id'] == id));
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════

  final _colors = [
    AppTheme.primary,
    AppTheme.secondary,
    AppTheme.warning,
    const Color(0xFFb06af0),
    AppTheme.error,
  ];

  @override
  Widget build(BuildContext context) {
    final l = _ligne;
    final c = _colors[(l['id'] ?? 0) % _colors.length];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l['nom'] ?? l['numero'] ?? 'Détail',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text('Ligne ${l['numero'] ?? ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primary),
            onPressed: _showModifierDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _supprimerLigne,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    ligne: l,
                    arrets: _arrets,
                    horaires: _horaires,
                    color: c,
                  ),
                  const SizedBox(height: 24),
                  _SectionArrets(
                    arrets: _arrets,
                    onDelete: _supprimerArret,
                    onEdit: _modifierArret,
                    onAdd: _ajouterArret,
                  ),
                  const SizedBox(height: 24),
                  _SectionHoraires(
                    horaires: _horaires,
                    onDelete: _supprimerHoraire,
                    onEdit: _modifierHoraire,
                    onAdd: _ajouterHoraire,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INFO CARD
// ═══════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> ligne;
  final List<dynamic> arrets, horaires;
  final Color color;

  const _InfoCard({
    required this.ligne,
    required this.arrets,
    required this.horaires,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _NumeroBadge(numero: l['numero'] ?? '', color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['nom'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  _HeureRow(debut: l['heure_debut'], fin: l['heure_fin']),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _StatChip('${arrets.length}', 'Arrêts', Icons.location_on,
                AppTheme.primary),
            const SizedBox(width: 8),
            _StatChip('${horaires.length}', 'Horaires', Icons.schedule,
                Colors.purple),
          ]),
        ],
      ),
    );
  }
}

class _NumeroBadge extends StatelessWidget {
  final String numero;
  final Color color;
  const _NumeroBadge({required this.numero, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(numero,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

class _HeureRow extends StatelessWidget {
  final dynamic debut, fin;
  const _HeureRow({required this.debut, required this.fin});

  String _fmt(dynamic t) {
    if (t == null) return '--';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.schedule, size: 13, color: Colors.white38),
      const SizedBox(width: 4),
      Text('${_fmt(debut)} → ${_fmt(fin)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String val, label;
  final IconData icon;
  final Color color;
  const _StatChip(this.val, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(val,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION HEADER with + button
// ═══════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onAdd;
  final Color addColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.onAdd,
    this.addColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count',
            style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      const Spacer(),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: addColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: addColor.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.add, color: addColor, size: 14),
            const SizedBox(width: 4),
            Text('Ajouter',
                style: TextStyle(
                    color: addColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION ARRÊTS
// ═══════════════════════════════════════════════════════════

class _SectionArrets extends StatelessWidget {
  final List<dynamic> arrets;
  final Function(int) onDelete;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onAdd;

  const _SectionArrets({
    required this.arrets,
    required this.onDelete,
    required this.onEdit,
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
          addColor: AppTheme.primary,
        ),
        const SizedBox(height: 12),
        if (arrets.isEmpty)
          _EmptyBox(
            msg: 'Aucun arrêt',
            onAdd: onAdd,
            addLabel: 'Ajouter le premier arrêt',
          )
        else
          ...arrets.asMap().entries.map((e) => _ArretItem(
                index: e.key,
                arret: e.value,
                isLast: e.key == arrets.length - 1,
                onDelete: () => onDelete(e.value['id']),
                onEdit: () => onEdit(e.value),
              )),
      ],
    );
  }
}

class _ArretItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> arret;
  final bool isLast;
  final VoidCallback onDelete, onEdit;

  const _ArretItem({
    required this.index,
    required this.arret,
    required this.isLast,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('${index + 1}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(arret['nom'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              if (arret['position_gps'] is Map)
                Text(
                  '${arret['position_gps']['lat']?.toStringAsFixed(4)}, ${arret['position_gps']['lng']?.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ),
        if (!isLast)
          const Icon(Icons.keyboard_arrow_down,
              color: Colors.white24, size: 16),
        IconButton(
          icon: const Icon(Icons.edit, color: AppTheme.primary, size: 18),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.redAccent, size: 18),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION HORAIRES
// ═══════════════════════════════════════════════════════════

class _SectionHoraires extends StatelessWidget {
  final List<dynamic> horaires;
  final Function(int) onDelete;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onAdd;

  const _SectionHoraires({
    required this.horaires,
    required this.onDelete,
    required this.onEdit,
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
          addColor: Colors.purple,
        ),
        const SizedBox(height: 12),
        if (horaires.isEmpty)
          _EmptyBox(
            msg: 'Aucun horaire',
            onAdd: onAdd,
            addLabel: 'Ajouter le premier horaire',
          )
        else
          ...horaires.map((h) => _HoraireItem(
                horaire: h,
                onDelete: () => onDelete(h['id']),
                onEdit: () => onEdit(h),
              )),
      ],
    );
  }
}

class _HoraireItem extends StatelessWidget {
  final Map<String, dynamic> horaire;
  final VoidCallback onDelete, onEdit;

  const _HoraireItem({
    required this.horaire,
    required this.onDelete,
    required this.onEdit,
  });

  String _fmt(dynamic t) {
    if (t == null) return '--';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    final estRetour = horaire['est_retour'] == true;
    final color = estRetour ? Colors.orange : AppTheme.primary;
    final icon = estRetour ? Icons.arrow_back : Icons.arrow_forward;

    final jours = (horaire['jours_semaine'] as List<dynamic>? ?? [])
        .map((j) {
          const labels = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
          return (j is int && j < labels.length) ? labels[j] : '';
        })
        .where((s) => s.isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
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
                '${horaire['point_depart'] ?? ''} → ${horaire['point_arrivee'] ?? ''}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.schedule, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  '${_fmt(horaire['heure_depart'])} → ${_fmt(horaire['heure_arrivee'])}',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ]),
              if (jours.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(jours,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: AppTheme.primary, size: 18),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.redAccent, size: 18),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// EMPTY BOX
// ═══════════════════════════════════════════════════════════

class _EmptyBox extends StatelessWidget {
  final String msg;
  final VoidCallback? onAdd;
  final String? addLabel;

  const _EmptyBox({required this.msg, this.onAdd, this.addLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: [
        const Icon(Icons.info_outline, size: 36, color: Colors.white24),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        if (onAdd != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: AppTheme.primary, size: 14),
                const SizedBox(width: 6),
                Text(addLabel ?? 'Ajouter',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════

class _ConfirmDialog extends StatelessWidget {
  final String title, content;
  const _ConfirmDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODIFIER LIGNE SHEET
// ═══════════════════════════════════════════════════════════

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
    nomCtrl = TextEditingController(text: l['nom'] ?? '');
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
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
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
      backgroundColor: isError ? AppTheme.error : Colors.green.shade700,
    ));
  }

  Future<void> _save() async {
    if (numCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty) {
      _snack('Numéro et nom obligatoires', isError: true);
      return;
    }
    setState(() => loading = true);
    final body = {
      'numero': numCtrl.text.trim(),
      'nom': nomCtrl.text.trim(),
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
      Navigator.pop(context, jsonDecode(r.body)['ligne']);
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
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.edit, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Modifier la ligne',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            _SheetLabel('Informations', Icons.route),
            const SizedBox(height: 10),
            _SheetField(numCtrl, 'Numéro', Icons.tag),
            const SizedBox(height: 10),
            _SheetField(nomCtrl, 'Nom / Description', Icons.route),
            const SizedBox(height: 16),
            _SheetLabel('Horaires d\'exploitation', Icons.schedule),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _SheetTimeTile(debCtrl, 'Heure début', () async {
                final t = await _pickTime(debCtrl.text);
                if (t != null) setState(() => debCtrl.text = t);
              })),
              const SizedBox(width: 10),
              Expanded(
                  child: _SheetTimeTile(finCtrl, 'Heure fin', () async {
                final t = await _pickTime(finCtrl.text);
                if (t != null) setState(() => finCtrl.text = t);
              })),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: loading ? null : _save,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.check, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Enregistrer',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15)),
                          ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AJOUTER ARRÊT SHEET
// ═══════════════════════════════════════════════════════════

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
      backgroundColor: isError ? AppTheme.error : Colors.green.shade700,
    ));
  }

  Future<({double lat, double lng})?> _pickGps() async {
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    return showDialog<({double lat, double lng})>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('GPS — Arrêt',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _MiniField(latCtrl, 'Latitude (ex: 36.3650)'),
          const SizedBox(height: 10),
          _MiniField(lngCtrl, 'Longitude (ex: 6.6147)'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
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
      Navigator.pop(context, jsonDecode(r.body)['arret']);
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_location_alt,
                        color: AppTheme.primary, size: 20)),
                const SizedBox(width: 12),
                const Text('Ajouter un arrêt',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _SheetLabel('Nom de l\'arrêt', Icons.label),
              const SizedBox(height: 10),
              _SheetField(_nomCtrl, 'Ex: Gare centrale, Place des martyrs...',
                  Icons.location_on),
              const SizedBox(height: 16),
              _SheetLabel('Position GPS (optionnel)', Icons.gps_fixed),
              const SizedBox(height: 10),
              _SheetGpsBtn(
                label: 'Position de l\'arrêt',
                lat: _lat,
                lng: _lng,
                onTap: () async {
                  final r = await _pickGps();
                  if (r != null)
                    setState(() {
                      _lat = r.lat;
                      _lng = r.lng;
                    });
                },
                onClear: () => setState(() {
                  _lat = null;
                  _lng = null;
                }),
              ),
              const SizedBox(height: 24),
              _SheetSaveBtn(
                  loading: _loading,
                  label: 'Ajouter l\'arrêt',
                  onPressed: _save),
            ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AJOUTER HORAIRE SHEET
// ═══════════════════════════════════════════════════════════

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
  List<int> _jours = [1, 2, 3, 4, 5, 6, 7];
  double? _dLat, _dLng, _aLat, _aLng;
  bool _loading = false;

  static const _jourLabels = ['L', 'M', 'Me', 'J', 'V', 'S', 'D'];

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
      backgroundColor: isError ? AppTheme.error : Colors.green.shade700,
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
            colorScheme: const ColorScheme.dark(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<({double lat, double lng})?> _pickGps(String title) async {
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    return showDialog<({double lat, double lng})>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _MiniField(latCtrl, 'Latitude'),
          const SizedBox(height: 10),
          _MiniField(lngCtrl, 'Longitude'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
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
        if (_dLat != null) 'depart_lat': _dLat,
        if (_dLng != null) 'depart_lng': _dLng,
        if (_aLat != null) 'arrivee_lat': _aLat,
        if (_aLng != null) 'arrivee_lng': _aLng,
      }),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (r.statusCode == 201) {
      Navigator.pop(context, jsonDecode(r.body)['horaire']);
    } else {
      _snack(jsonDecode(r.body)['message'] ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _estRetour ? Colors.orange : AppTheme.primary;
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.schedule,
                        color: Colors.purple, size: 20)),
                const SizedBox(width: 12),
                const Text('Ajouter un horaire',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _TypeBtn(
                        label: 'Aller',
                        icon: Icons.arrow_forward,
                        selected: !_estRetour,
                        color: AppTheme.primary,
                        onTap: () => setState(() => _estRetour = false))),
                const SizedBox(width: 10),
                Expanded(
                    child: _TypeBtn(
                        label: 'Retour',
                        icon: Icons.arrow_back,
                        selected: _estRetour,
                        color: Colors.orange,
                        onTap: () => setState(() => _estRetour = true))),
              ]),
              const SizedBox(height: 16),
              _SheetLabel('Point de départ', Icons.trip_origin),
              const SizedBox(height: 10),
              _SheetField(
                  _departCtrl, 'Ex: Gare routière...', Icons.trip_origin),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child:
                        _SheetTimeTile(_hDepartCtrl, 'Heure départ', () async {
                  final t = await _pickTime(_hDepartCtrl.text);
                  if (t != null) setState(() => _hDepartCtrl.text = t);
                }, color: color)),
                const SizedBox(width: 8),
                _GpsIconBtn2(
                    hasGps: _dLat != null,
                    onTap: () async {
                      final r = await _pickGps('GPS Départ');
                      if (r != null)
                        setState(() {
                          _dLat = r.lat;
                          _dLng = r.lng;
                        });
                    }),
              ]),
              const SizedBox(height: 16),
              _SheetLabel('Point d\'arrivée', Icons.place),
              const SizedBox(height: 10),
              _SheetField(
                  _arriveeCtrl, 'Ex: Terminal, Centre-ville...', Icons.place),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _SheetTimeTile(_hArriveeCtrl, 'Heure arrivée',
                        () async {
                  final t = await _pickTime(_hArriveeCtrl.text);
                  if (t != null) setState(() => _hArriveeCtrl.text = t);
                }, color: color)),
                const SizedBox(width: 8),
                _GpsIconBtn2(
                    hasGps: _aLat != null,
                    onTap: () async {
                      final r = await _pickGps('GPS Arrivée');
                      if (r != null)
                        setState(() {
                          _aLat = r.lat;
                          _aLng = r.lng;
                        });
                    }),
              ]),
              const SizedBox(height: 16),
              _SheetLabel('Jours de service', Icons.calendar_today),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (j) {
                  final num = j + 1;
                  final sel = _jours.contains(num);
                  return GestureDetector(
                    onTap: () => setState(() {
                      sel
                          ? _jours.remove(num)
                          : (_jours
                            ..add(num)
                            ..sort());
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: sel ? color : Colors.white10,
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(_jourLabels[j],
                              style: TextStyle(
                                  color: sel ? Colors.white : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal))),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              _SheetSaveBtn(
                  loading: _loading,
                  label: 'Ajouter l\'horaire',
                  onPressed: _save),
            ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED SHEET WIDGETS
// ═══════════════════════════════════════════════════════════

class _SheetLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SheetLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 15),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _SheetField(this.controller, this.hint, this.icon,
      {this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class _SheetTimeTile extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onTap;
  final Color color;

  const _SheetTimeTile(this.controller, this.hint, this.onTap,
      {this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.access_time, color: color, size: 18),
          const SizedBox(width: 8),
          Text(controller.text.isEmpty ? hint : controller.text,
              style: TextStyle(
                  color:
                      controller.text.isEmpty ? Colors.white38 : Colors.white,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}

class _SheetGpsBtn extends StatelessWidget {
  final String label;
  final double? lat, lng;
  final VoidCallback onTap, onClear;

  const _SheetGpsBtn(
      {required this.label,
      required this.lat,
      required this.lng,
      required this.onTap,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    final has = lat != null && lng != null;
    return GestureDetector(
      onTap: has ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              has ? Colors.greenAccent.withOpacity(0.08) : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  has ? Colors.greenAccent.withOpacity(0.3) : Colors.white10),
        ),
        child: Row(children: [
          Icon(has ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: has ? Colors.greenAccent : Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                    has
                        ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                        : 'Appuyer pour saisir',
                    style: TextStyle(
                        color: has ? Colors.greenAccent : Colors.white38,
                        fontSize: 12)),
              ])),
          if (has)
            GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, color: Colors.white38, size: 16))
          else
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ]),
      ),
    );
  }
}

class _SheetSaveBtn extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  const _SheetSaveBtn(
      {required this.loading, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ]),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color.withOpacity(0.5) : Colors.white10,
              width: selected ? 1.5 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? color : Colors.white38, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: selected ? color : Colors.white38,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}

class _GpsIconBtn2 extends StatelessWidget {
  final bool hasGps;
  final VoidCallback onTap;
  const _GpsIconBtn2({required this.hasGps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasGps ? Colors.greenAccent.withOpacity(0.12) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(hasGps ? Icons.gps_fixed : Icons.gps_not_fixed,
            size: 20, color: hasGps ? Colors.greenAccent : Colors.white38),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _MiniField(this.controller, this.hint);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
    );
  }
}
