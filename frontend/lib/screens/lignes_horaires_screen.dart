import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'ligne_detail_screen.dart';

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
      if (r.statusCode == 200 && mounted)
        setState(() => _lignes = jsonDecode(r.body));
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

  final List<Color> _colors = [
    AppTheme.primary,
    AppTheme.secondary,
    AppTheme.warning,
    const Color(0xFFb06af0),
    AppTheme.error,
  ];

  String _fmtHeure(dynamic t) {
    if (t == null) return '--';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lignes & Horaires',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('${_lignes.length} ligne(s)',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_ligne',
        onPressed: _showAjouterDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Ajouter ligne', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _lignes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 70, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('Aucune ligne',
                          style: TextStyle(color: Colors.white38)),
                      SizedBox(height: 8),
                      Text('Appuyez sur + pour en ajouter',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _lignes.length,
                    itemBuilder: (_, i) {
                      final l = _lignes[i];
                      final c = _colors[i % _colors.length];
                      return _LigneCard(
                        ligne: l,
                        color: c,
                        fmtHeure: _fmtHeure,
                        onTap: () => _ouvrirDetail(l),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Ligne Card ───────────────────────────────────────────────

class _LigneCard extends StatelessWidget {
  final Map<String, dynamic> ligne;
  final Color color;
  final String Function(dynamic) fmtHeure;
  final VoidCallback onTap;

  const _LigneCard({
    required this.ligne,
    required this.color,
    required this.fmtHeure,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Numéro badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  l['numero'] ?? '',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Nom + horaires
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l['nom'] ?? l['numero'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      '${fmtHeure(l['heure_debut'])} → ${fmtHeure(l['heure_fin'])}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ]),
                ],
              ),
            ),
            // Flèche indiquant qu'on peut entrer
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════
// AJOUTER LIGNE SHEET (multi-étapes)
// ══════════════════════════════════════════════════════════

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
      backgroundColor: isError ? AppTheme.error : Colors.green.shade700,
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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _miniField(
              latCtrl,
              'Latitude  (ex: 36.3650)',
              const TextInputType.numberWithOptions(
                  signed: true, decimal: true)),
          const SizedBox(height: 10),
          _miniField(
              lngCtrl,
              'Longitude (ex: 6.6147)',
              const TextInputType.numberWithOptions(
                  signed: true, decimal: true)),
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
            colorScheme: const ColorScheme.dark(primary: AppTheme.primary)),
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

  Future<void> _soumettre() async {
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
        _snack(jsonDecode(rLigne.body)['message'] ?? 'Erreur', isError: true);
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
      _snack('Erreur réseau', isError: true);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        _buildStepper(),
        const Divider(height: 1, color: Colors.white10),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _etape == 0
                  ? _buildEtape0()
                  : _etape == 1
                      ? _buildEtape1()
                      : _buildEtape2(),
            ),
          ),
        ),
        _buildNavBar(),
      ]),
    );
  }

  Widget _buildStepper() {
    final steps = ['Infos', 'Arrêts', 'Horaires'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd)
            return Expanded(
                child: Container(
                    height: 1,
                    color:
                        i ~/ 2 < _etape ? AppTheme.primary : Colors.white12));
          final idx = i ~/ 2;
          final done = idx < _etape;
          final active = idx == _etape;
          return Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done || active ? AppTheme.primary : Colors.white10,
                shape: BoxShape.circle,
                border: Border.all(
                    color: active ? AppTheme.primary : Colors.transparent,
                    width: 2),
              ),
              child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              color: active ? Colors.white : Colors.white38,
                              fontSize: 13,
                              fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 4),
            Text(steps[idx],
                style: TextStyle(
                    color: active ? AppTheme.primary : Colors.white38,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ]);
        }),
      ),
    );
  }

  Widget _buildEtape0() {
    return Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Informations de base', Icons.route),
          const SizedBox(height: 12),
          _field(_numCtrl, 'Numéro (ex: L1, 15)', Icons.tag),
          const SizedBox(height: 10),
          _field(_nomCtrl, 'Nom / Description (ex: Mila → Constantine)',
              Icons.route),
          const SizedBox(height: 16),
          _sectionLabel('Horaires d\'exploitation', Icons.schedule),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _timeField(_debCtrl, 'Heure début')),
            const SizedBox(width: 10),
            Expanded(child: _timeField(_finCtrl, 'Heure fin')),
          ]),
          const SizedBox(height: 16),
        ]);
  }

  Widget _buildEtape1() {
    return Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Arrêts de la ligne', Icons.location_on),
          const SizedBox(height: 4),
          const Text('Ajoutez les stations dans l\'ordre (départ → arrivée)',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 14),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _arrets.length,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (newIdx > oldIdx) newIdx--;
                final item = _arrets.removeAt(oldIdx);
                _arrets.insert(newIdx, item);
              });
            },
            itemBuilder: (_, i) => _arretTile(
                key: ValueKey(_arrets[i]), index: i, arret: _arrets[i]),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _arrets.add(_ArretData())),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_location_alt,
                        color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Ajouter un arrêt',
                        style:
                            TextStyle(color: AppTheme.primary, fontSize: 13)),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
        ]);
  }

  Widget _arretTile(
      {required Key key, required int index, required _ArretData arret}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: TextField(
          controller: arret.nomCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Nom de l\'arrêt',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        )),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            final r = await _saisiGps('GPS — Arrêt ${index + 1}');
            if (r != null)
              setState(() {
                arret.lat = r.lat;
                arret.lng = r.lng;
              });
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: arret.lat != null
                    ? Colors.greenAccent.withOpacity(0.12)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.gps_fixed,
                size: 16,
                color: arret.lat != null ? Colors.greenAccent : Colors.white38),
          ),
        ),
        const SizedBox(width: 4),
        if (_arrets.length > 1)
          GestureDetector(
            onTap: () => setState(() {
              arret.dispose();
              _arrets.removeAt(index);
            }),
            child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.redAccent, size: 16)),
          ),
        const SizedBox(width: 4),
        const Icon(Icons.drag_handle, color: Colors.white24, size: 18),
      ]),
    );
  }

  Widget _buildEtape2() {
    const jourLabels = ['L', 'M', 'Me', 'J', 'V', 'S', 'D'];
    final joursCommuns =
        _courses.isNotEmpty ? _courses.first.jours : [1, 2, 3, 4, 5, 6, 7];

    return Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Courses de la journée', Icons.schedule),
          const SizedBox(height: 4),
          const Text(
              'Ajoutez autant de courses que nécessaire (aller/retour/aller...)',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 14),
          _sectionLabel('Jours de service', Icons.calendar_today),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (j) {
              final jourNum = j + 1;
              final selected = joursCommuns.contains(jourNum);
              return GestureDetector(
                onTap: () => setState(() {
                  for (final c in _courses) {
                    if (selected)
                      c.jours.remove(jourNum);
                    else {
                      c.jours.add(jourNum);
                      c.jours.sort();
                    }
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white10,
                      shape: BoxShape.circle),
                  child: Center(
                      child: Text(jourLabels[j],
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.white38,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal))),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ...List.generate(_courses.length, (i) {
            final c = _courses[i];
            final isAller = c.type == 'aller';
            final color = isAller ? AppTheme.primary : Colors.orange;
            final icon = isAller ? Icons.arrow_forward : Icons.arrow_back;
            final label =
                isAller ? 'ALLER ${(i ~/ 2) + 1}' : 'RETOUR ${(i ~/ 2) + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
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
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 18),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    _field(c.pointDepartCtrl, 'Point de départ',
                        Icons.trip_origin),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _timePickerRow(
                        icon: Icons.schedule,
                        color: color,
                        controller: c.heureDepartCtrl,
                        hint: 'Heure départ',
                        onTap: () async {
                          final t = await _pickTime(c.heureDepartCtrl.text);
                          if (t != null)
                            setState(() => c.heureDepartCtrl.text = t);
                        },
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final r = await _saisiGps('GPS départ — $label');
                          if (r != null)
                            setState(() {
                              c.departLat = r.lat;
                              c.departLng = r.lng;
                            });
                        },
                        child: _gpsIcon(c.departLat != null),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _field(c.pointArriveeCtrl, 'Point d\'arrivée', Icons.place),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _timePickerRow(
                        icon: Icons.schedule,
                        color: color,
                        controller: c.heureArriveeCtrl,
                        hint: 'Heure arrivée',
                        onTap: () async {
                          final t = await _pickTime(c.heureArriveeCtrl.text);
                          if (t != null)
                            setState(() => c.heureArriveeCtrl.text = t);
                        },
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final r = await _saisiGps('GPS arrivée — $label');
                          if (r != null)
                            setState(() {
                              c.arriveeLat = r.lat;
                              c.arriveeLng = r.lng;
                            });
                        },
                        child: _gpsIcon(c.arriveeLat != null),
                      ),
                    ]),
                  ]),
            );
          }),
          GestureDetector(
            onTap: _ajouterCourse,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3))),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                    _courses.last.type == 'aller'
                        ? Icons.arrow_back
                        : Icons.arrow_forward,
                    color: Colors.purple,
                    size: 18),
                const SizedBox(width: 8),
                Text(
                    _courses.last.type == 'aller'
                        ? 'Ajouter retour'
                        : 'Ajouter aller',
                    style: const TextStyle(color: Colors.purple, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
        ]);
  }

  Widget _buildNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(children: [
          if (_etape > 0) ...[
            Expanded(
                child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => setState(() => _etape--),
              child:
                  const Text('Retour', style: TextStyle(color: Colors.white54)),
            )),
            const SizedBox(width: 12),
          ],
          Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _etape == 2 ? Colors.green.shade700 : AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _loading
                    ? null
                    : () {
                        if (_etape == 0) {
                          if (_numCtrl.text.trim().isEmpty ||
                              _nomCtrl.text.trim().isEmpty) {
                            _snack('Numéro et nom obligatoires', isError: true);
                            return;
                          }
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
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                _etape == 2
                                    ? 'Enregistrer la ligne'
                                    : 'Suivant',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15)),
                            const SizedBox(width: 6),
                            Icon(_etape < 2 ? Icons.arrow_forward : Icons.check,
                                color: Colors.white, size: 16),
                          ]),
              )),
        ]),
      ),
    );
  }

  // ── Widgets utilitaires ──────────────────────────────────

  Widget _sectionLabel(String label, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 16),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
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

  Widget _timeField(TextEditingController c, String hint) {
    return GestureDetector(
      onTap: () async {
        final t = await _pickTime(c.text);
        if (t != null) setState(() => c.text = t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.access_time, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Text(c.text.isEmpty ? hint : c.text,
              style: TextStyle(
                  color: c.text.isEmpty ? Colors.white38 : Colors.white,
                  fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _timePickerRow({
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(controller.text.isEmpty ? hint : controller.text,
              style: TextStyle(
                  color:
                      controller.text.isEmpty ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _gpsIcon(bool hasGps) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: hasGps ? Colors.greenAccent.withOpacity(0.12) : Colors.white10,
          borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.gps_fixed,
          size: 18, color: hasGps ? Colors.greenAccent : Colors.white38),
    );
  }

  Widget _gpsRow({
    required String label,
    required double? lat,
    required double? lng,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasGps = lat != null && lng != null;
    return GestureDetector(
      onTap: hasGps ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: hasGps
                ? Colors.greenAccent.withOpacity(0.08)
                : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: hasGps
                    ? Colors.greenAccent.withOpacity(0.3)
                    : Colors.white10)),
        child: Row(children: [
          Icon(hasGps ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: hasGps ? Colors.greenAccent : Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                  hasGps
                      ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                      : 'Appuyer pour saisir les coordonnées',
                  style: TextStyle(
                      color: hasGps ? Colors.greenAccent : Colors.white38,
                      fontSize: 12),
                ),
              ])),
          if (hasGps)
            GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, color: Colors.white38, size: 16))
          else
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ]),
      ),
    );
  }

  Widget _miniField(TextEditingController c, String hint, TextInputType type) {
    return TextField(
      controller: c,
      keyboardType: type,
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
