import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════
// MODIFIER ARRÊT SCREEN
// ═══════════════════════════════════════════════════════════

class ModifierArretScreen extends StatefulWidget {
  final Map<String, dynamic> arret;
  final int ligneId;
  final Map<String, String> headers;

  const ModifierArretScreen({
    super.key,
    required this.arret,
    required this.ligneId,
    required this.headers,
  });

  @override
  State<ModifierArretScreen> createState() => _ModifierArretScreenState();
}

class _ModifierArretScreenState extends State<ModifierArretScreen> {
  late final TextEditingController _nomCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.arret['nom'] ?? '');
  }

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

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      _snack("Nom de l'arrêt obligatoire", isError: true);
      return;
    }
    setState(() => _loading = true);

    final body = {
      'nom': _nomCtrl.text.trim(),
      'ordre': widget.arret['ordre'] ?? 0,
    };

    final r = await http.put(
      Uri.parse(
          '${ApiConstants.lignes}/${widget.ligneId}/arrets/${widget.arret['id']}'),
      headers: widget.headers,
      body: jsonEncode(body),
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (r.statusCode == 200) {
      final updated = jsonDecode(r.body)['arret'];
      Navigator.pop(context, updated);
    } else {
      _snack(jsonDecode(r.body)['message'] ?? 'Erreur de modification',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: const Text('Modifier Arrêt',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Modifier l\'arrêt',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('ID: ${widget.arret['id']}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Nom de l\'arrêt', Icons.label),
          const SizedBox(height: 10),
          _StyledTextField(
            controller: _nomCtrl,
            hint: 'Ex: Gare centrale, Place des martyrs...',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 40),
          _SaveButton(loading: _loading, onPressed: _save),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODIFIER HORAIRE SCREEN
// ═══════════════════════════════════════════════════════════

class ModifierHoraireScreen extends StatefulWidget {
  final Map<String, dynamic> horaire;
  final int ligneId;
  final Map<String, String> headers;

  const ModifierHoraireScreen({
    super.key,
    required this.horaire,
    required this.ligneId,
    required this.headers,
  });

  @override
  State<ModifierHoraireScreen> createState() => _ModifierHoraireScreenState();
}

class _ModifierHoraireScreenState extends State<ModifierHoraireScreen> {
  late final TextEditingController _departCtrl;
  late final TextEditingController _arriveeCtrl;
  late final TextEditingController _hDepartCtrl;
  late final TextEditingController _hArriveeCtrl;
  late List<int> _jours;
  late bool _estRetour;
  double? _dLat, _dLng, _aLat, _aLng;
  bool _loading = false;

  static const _jourLabels = ['L', 'M', 'Me', 'J', 'V', 'S', 'D'];
  static const _jourFullLabels = [
    '',
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim'
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.horaire;
    _departCtrl = TextEditingController(text: h['point_depart'] ?? '');
    _arriveeCtrl = TextEditingController(text: h['point_arrivee'] ?? '');
    _hDepartCtrl = TextEditingController(text: _fmtTime(h['heure_depart']));
    _hArriveeCtrl = TextEditingController(text: _fmtTime(h['heure_arrivee']));
    _estRetour = h['est_retour'] == true;

    final rawJours = h['jours_semaine'];
    _jours = rawJours is List
        ? rawJours.whereType<int>().toList()
        : [1, 2, 3, 4, 5, 6, 7];

    final gpsDep = h['position_depart_gps'];
    if (gpsDep is Map) {
      _dLat = gpsDep['lat']?.toDouble();
      _dLng = gpsDep['lng']?.toDouble();
    }
    final gpsArr = h['position_arrivee_gps'];
    if (gpsArr is Map) {
      _aLat = gpsArr['lat']?.toDouble();
      _aLng = gpsArr['lng']?.toDouble();
    }
  }

  @override
  void dispose() {
    _departCtrl.dispose();
    _arriveeCtrl.dispose();
    _hDepartCtrl.dispose();
    _hArriveeCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
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
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
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
          _MiniTextField(latCtrl, 'Latitude'),
          const SizedBox(height: 10),
          _MiniTextField(lngCtrl, 'Longitude'),
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

    final body = {
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
    };

    final r = await http.put(
      Uri.parse(
          '${ApiConstants.lignes}/${widget.ligneId}/horaires/${widget.horaire['id']}'),
      headers: widget.headers,
      body: jsonEncode(body),
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (r.statusCode == 200) {
      final updated = jsonDecode(r.body)['horaire'];
      Navigator.pop(context, updated);
    } else {
      _snack(jsonDecode(r.body)['message'] ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _estRetour ? Colors.orange : AppTheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: const Text('Modifier Horaire',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionLabel('Type de course', Icons.swap_horiz),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _TypeToggle(
                label: 'Aller',
                icon: Icons.arrow_forward,
                selected: !_estRetour,
                color: AppTheme.primary,
                onTap: () => setState(() => _estRetour = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeToggle(
                label: 'Retour',
                icon: Icons.arrow_back,
                selected: _estRetour,
                color: Colors.orange,
                onTap: () => setState(() => _estRetour = true),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel('Point de départ', Icons.trip_origin),
          const SizedBox(height: 10),
          _StyledTextField(
              controller: _departCtrl,
              hint: 'Ex: Gare routière, Place...',
              icon: Icons.trip_origin),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _TimeTile(
                controller: _hDepartCtrl,
                hint: 'Heure départ',
                color: color,
                onTap: () async {
                  final t = await _pickTime(_hDepartCtrl.text);
                  if (t != null) setState(() => _hDepartCtrl.text = t);
                },
              ),
            ),
            const SizedBox(width: 10),
            _GpsIconBtn(
              hasGps: _dLat != null,
              onTap: () async {
                final r = await _pickGps('GPS — Départ');
                if (r != null)
                  setState(() {
                    _dLat = r.lat;
                    _dLng = r.lng;
                  });
              },
            ),
          ]),
          const SizedBox(height: 20),
          _SectionLabel('Point d\'arrivée', Icons.place),
          const SizedBox(height: 10),
          _StyledTextField(
              controller: _arriveeCtrl,
              hint: 'Ex: Terminal, Centre-ville...',
              icon: Icons.place),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _TimeTile(
                controller: _hArriveeCtrl,
                hint: 'Heure arrivée',
                color: color,
                onTap: () async {
                  final t = await _pickTime(_hArriveeCtrl.text);
                  if (t != null) setState(() => _hArriveeCtrl.text = t);
                },
              ),
            ),
            const SizedBox(width: 10),
            _GpsIconBtn(
              hasGps: _aLat != null,
              onTap: () async {
                final r = await _pickGps('GPS — Arrivée');
                if (r != null)
                  setState(() {
                    _aLat = r.lat;
                    _aLng = r.lng;
                  });
              },
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel('Jours de service', Icons.calendar_today),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (j) {
              final num = j + 1;
              final selected = _jours.contains(num);
              return GestureDetector(
                onTap: () => setState(() {
                  selected
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
                    color: selected ? color : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_jourLabels[j],
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white38,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _jours.isEmpty
                ? 'Aucun jour sélectionné'
                : _jours
                    .map((j) =>
                        j < _jourFullLabels.length ? _jourFullLabels[j] : '')
                    .where((s) => s.isNotEmpty)
                    .join(', '),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 40),
          _SaveButton(loading: _loading, onPressed: _save),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 16),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

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
        fillColor: AppTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class _MiniTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _MiniTextField(this.controller, this.hint);

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

class _TimeTile extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  const _TimeTile({
    required this.controller,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(Icons.access_time, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            controller.text.isEmpty ? hint : controller.text,
            style: TextStyle(
              color: controller.text.isEmpty ? Colors.white38 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }
}

class _GpsIconBtn extends StatelessWidget {
  final bool hasGps;
  final VoidCallback onTap;
  const _GpsIconBtn({required this.hasGps, required this.onTap});

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
        child: Icon(
          hasGps ? Icons.gps_fixed : Icons.gps_not_fixed,
          size: 20,
          color: hasGps ? Colors.greenAccent : Colors.white38,
        ),
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  final double? lat, lng;
  final String label;
  final VoidCallback onTap, onClear;
  const _GpsCard({
    required this.lat,
    required this.lng,
    required this.label,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final has = lat != null && lng != null;
    return GestureDetector(
      onTap: has ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: has ? Colors.greenAccent.withOpacity(0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: has ? Colors.greenAccent.withOpacity(0.3) : Colors.white10,
          ),
        ),
        child: Row(children: [
          Icon(
            has ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: has ? Colors.greenAccent : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                  has
                      ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                      : 'Appuyer pour saisir les coordonnées',
                  style: TextStyle(
                    color: has ? Colors.greenAccent : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (has)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, color: Colors.white38, size: 16),
            )
          else
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ]),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : Colors.white10,
            width: selected ? 1.5 : 1,
          ),
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

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _SaveButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onPressed,
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
                  Text('Enregistrer les modifications',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
      ),
    );
  }
}
