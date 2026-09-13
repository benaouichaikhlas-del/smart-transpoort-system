import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/api_constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _headerBg = Color(0xFF0E1526);
  static const Color _card = Color(0xFF111827);
  static const Color _surface = Color(0xFF161D2E);
  static const Color _primary = Color(0xFF3B82F6);
  static const Color _accent = Color(0xFF10B981);
  static const Color _text = Colors.white;
  static const Color _muted = Color(0xFF64748B);

  final MapController _mapCtrl = MapController();

  // ══════════════════════════════════════════
  // ⭐ بيانات الحافلات: 3 خرائط منفصلة
  // ══════════════════════════════════════════
  final Map<String, Map<String, dynamic>> _busesInfo = {};
  final Map<String, LatLng> _targetPositions = {};
  final Map<String, LatLng> _displayedPositions = {};

  Timer? _animationTicker;
  Timer? _fallbackTimer;
  IO.Socket? _socket;

  List<Map<String, dynamic>> _lignes = [];
  Map<String, dynamic>? _ligneActive;
  bool _loading = true;
  bool _connected = false;

  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _chargerLignes();
    _connecterSocket();
    _startAnimationTicker();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _animationTicker?.cancel();
    _fallbackTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // ⭐ التحريك السلس
  // ════════════════════════════════════════════
  void _startAnimationTicker() {
    _animationTicker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      if (_targetPositions.isEmpty) return;

      setState(() {
        _targetPositions.forEach((busId, target) {
          final current = _displayedPositions[busId] ?? target;
          const factor = 0.10;
          final newLat =
              current.latitude + (target.latitude - current.latitude) * factor;
          final newLng = current.longitude +
              (target.longitude - current.longitude) * factor;
          _displayedPositions[busId] = LatLng(newLat, newLng);
        });
      });
    });
  }

  // ════════════════════════════════════════════
  // SOCKET.IO
  // ════════════════════════════════════════════
  void _connecterSocket() {
    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      if (!mounted) return;
      setState(() => _connected = true);
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      _chargerTrajetsActifs(_ligneActive?['id']?.toString());
    });

    _socket!.onDisconnect((_) {
      if (!mounted) return;
      setState(() => _connected = false);
      _fallbackTimer ??= Timer.periodic(
        const Duration(seconds: 15),
        (_) => _chargerTrajetsActifs(_ligneActive?['id']?.toString()),
      );
    });

    _socket!.on('position_broadcast', (data) {
      if (!mounted || data == null) return;

      final ligneId = data['ligne_id']?.toString();
      final conducteurId = data['conducteur_id']?.toString();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null || conducteurId == null) return;

      if (_ligneActive != null && ligneId != _ligneActive!['id']?.toString()) {
        return;
      }

      setState(() {
        _busesInfo[conducteurId] = {
          'ligne_id': ligneId,
          'ligne_numero': data['ligne_numero'],
          'immatriculation': data['immatriculation'],
          ...data,
        };
        _targetPositions[conducteurId] = LatLng(lat, lng);
        _displayedPositions.putIfAbsent(conducteurId, () => LatLng(lat, lng));
      });
    });

    _socket!.on('trajet_termine', (data) {
      if (!mounted) return;
      final conducteurId = data['conducteur_id']?.toString();
      if (conducteurId == null) return;
      setState(() {
        _busesInfo.remove(conducteurId);
        _targetPositions.remove(conducteurId);
        _displayedPositions.remove(conducteurId);
      });
    });
  }

  // ════════════════════════════════════════════
  // API
  // ════════════════════════════════════════════
  Future<void> _chargerLignes() async {
    try {
      final r = await http
          .get(Uri.parse(ApiConstants.lignes))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(r.body);
        setState(() {
          _lignes = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chargerTrajetsActifs(String? ligneId) async {
    try {
      final url = ligneId != null
          ? '${ApiConstants.baseUrl}/trajets/actifs?ligne_id=$ligneId'
          : '${ApiConstants.baseUrl}/trajets/actifs';

      final r =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (r.statusCode == 200 && mounted) {
        final List<dynamic> list = jsonDecode(r.body);
        setState(() {
          for (final t in list) {
            final lat = (t['latitude'] as num?)?.toDouble();
            final lng = (t['longitude'] as num?)?.toDouble();
            final conducteurId = t['conducteur_id']?.toString();
            if (lat != null && lng != null && conducteurId != null) {
              _busesInfo[conducteurId] = {
                'ligne_id': t['ligne_id']?.toString(),
                'ligne_numero': t['ligne_numero'],
                'immatriculation': t['immatriculation'],
                ...t,
              };
              _targetPositions[conducteurId] = LatLng(lat, lng);
              _displayedPositions.putIfAbsent(
                  conducteurId, () => LatLng(lat, lng));
            }
          }
        });
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════
  // البحث
  // ════════════════════════════════════════════
  void _onSearchChanged(String q) {
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _suggestions = _lignes.where((l) {
        final num = (l['numero'] ?? '').toString().toLowerCase();
        final nom = (l['nom'] ?? '').toString().toLowerCase();
        return num.contains(lower) || nom.contains(lower);
      }).toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _selectionnerLigne(Map<String, dynamic> ligne) {
    setState(() {
      _ligneActive = ligne;
      _showSuggestions = false;
      _busesInfo
          .removeWhere((k, v) => v['ligne_id'] != ligne['id']?.toString());
      _targetPositions.removeWhere((k, v) => !_busesInfo.containsKey(k));
      _displayedPositions.removeWhere((k, v) => !_busesInfo.containsKey(k));
    });
    _searchCtrl.text =
        '${ligne['numero'] ?? ''} — ${ligne['nom'] ?? ''}'.trim();

    _chargerTrajetsActifs(ligne['id']?.toString()).then((_) {
      if (_displayedPositions.isNotEmpty && mounted) {
        final first = _displayedPositions.values.first;
        _mapCtrl.move(first, 13);
      }
    });
  }

  void _reinitialiser() {
    setState(() {
      _ligneActive = null;
      _showSuggestions = false;
      _busesInfo.clear();
      _targetPositions.clear();
      _displayedPositions.clear();
    });
    _searchCtrl.clear();
    _chargerTrajetsActifs(null);
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ═══ الخريطة (tiles فاتحة كيما فالصورة) ═══
          FlutterMap(
            mapController: _mapCtrl,
            options: const MapOptions(
              initialCenter: LatLng(36.7372, 3.0865),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.frontend',
              ),
              MarkerLayer(
                markers: _displayedPositions.entries.map((e) {
                  final info = _busesInfo[e.key] ?? {};
                  final ligne = info['ligne_numero'] ?? info['ligne_id'] ?? '?';
                  return Marker(
                    point: e.value,
                    width: 56,
                    height: 70,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _showBusInfo(info),
                      child: Column(children: [
                        // Badge numéro de ligne (pilule bleue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.45),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            '$ligne',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Icône bus dans un cercle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.6), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ═══ En-tête sombre (titre + boutons) ═══
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: _headerBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(children: [
                    // Retour
                    _headerBtn(Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 14),
                    // Titre + compteur
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Suivi des Bus',
                                style: TextStyle(
                                    color: _text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(
                              '${_displayedPositions.length} bus en service',
                              style: const TextStyle(
                                  color: _primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                    ),
                    // Indicateur connexion (cercle)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _connected ? _accent : _muted,
                        shape: BoxShape.circle,
                        boxShadow: _connected
                            ? [
                                BoxShadow(
                                    color: _accent.withOpacity(0.6),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _headerBtn(Icons.refresh_rounded, onTap: () {
                      _chargerLignes();
                      _chargerTrajetsActifs(_ligneActive?['id']?.toString());
                    }),
                  ]),
                ),
              ),
            ),
          ),

          // ═══ Barre de recherche ═══
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 86, 16, 0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search_rounded,
                              color: _muted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: _onSearchChanged,
                              style:
                                  const TextStyle(color: _text, fontSize: 14),
                              decoration: InputDecoration(
                                hintText:
                                    'Rechercher par numéro ou nom de ligne...',
                                hintStyle:
                                    TextStyle(color: _muted, fontSize: 13.5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          if (_ligneActive != null)
                            GestureDetector(
                              onTap: _reinitialiser,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _muted.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: _muted, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_showSuggestions)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _primary.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount:
                              _suggestions.length > 5 ? 5 : _suggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: _surface),
                          itemBuilder: (_, i) {
                            final l = _suggestions[i];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l['numero'] ?? '',
                                  style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(l['nom'] ?? '',
                                  style: const TextStyle(
                                      color: _text, fontSize: 13)),
                              subtitle: Text(
                                '${l['heure_debut'] ?? ''} → ${l['heure_fin'] ?? ''}',
                                style: const TextStyle(
                                    color: _muted, fontSize: 11),
                              ),
                              onTap: () => _selectionnerLigne(l),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ═══ Badge ligne active ═══
          if (_ligneActive != null)
            Positioned(
              top: 152,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _card.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primary.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus_rounded,
                        color: _primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Ligne ${_ligneActive!['numero'] ?? ''}'
                      ' — ${_ligneActive!['nom'] ?? ''}',
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ═══ Boutons zoom (à droite) ═══
          Positioned(
            right: 16,
            bottom: _ligneActive != null ? 150 : 32,
            child: Column(
              children: [
                _mapButton(Icons.my_location_rounded, color: _primary,
                    onTap: () {
                  _mapCtrl.move(const LatLng(36.7372, 3.0865), 11);
                }),
                const SizedBox(height: 8),
                _mapButton(Icons.add, onTap: () {
                  _mapCtrl.move(
                      _mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
                }),
                const SizedBox(height: 8),
                _mapButton(Icons.remove, onTap: () {
                  _mapCtrl.move(
                      _mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
                }),
              ],
            ),
          ),

          // ═══ Carte infos ligne active (bas) ═══
          if (_ligneActive != null) _buildBottomInfoCard(),

          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // ── Carte du bas : Ligne + En service + Prochain arrêt + ETA ──
  Widget _buildBottomInfoCard() {
    // Première bus de la ligne pour extraire prochain arrêt / ETA
    final firstBus = _busesInfo.values.firstOrNull ?? {};
    final prochainArret = firstBus['prochain_arret'] ?? '—';
    final etaMin = firstBus['eta_minutes'] ?? '—';
    final distanceKm = firstBus['distance_km'] ?? '—';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card.withOpacity(0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _primary.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(children: [
            // Icône bus
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.directions_bus_rounded,
                  color: Colors.white, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ligne ${_ligneActive!['numero'] ?? ''}',
                        style: const TextStyle(
                            color: _text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              _displayedPositions.isNotEmpty ? _accent : _muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _displayedPositions.isNotEmpty
                            ? 'En service'
                            : 'Hors service',
                        style: TextStyle(
                          color:
                              _displayedPositions.isNotEmpty ? _accent : _muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    const Text('Prochain arrêt',
                        style: TextStyle(color: _muted, fontSize: 11.5)),
                    const SizedBox(height: 2),
                    Text('$prochainArret',
                        style: const TextStyle(
                            color: _text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                  ]),
            ),
            // ETA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text('$etaMin min',
                    style: const TextStyle(
                        color: _accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('($distanceKm km)',
                    style: const TextStyle(color: _muted, fontSize: 10.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showBusInfo(Map<String, dynamic> data) {
    final ligne = data['ligne_numero'] ?? data['ligne_id'] ?? '?';
    final immat = data['immatriculation'] ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.directions_bus_rounded,
                  color: _primary, size: 20),
              const SizedBox(width: 8),
              Text('Ligne $ligne',
                  style: const TextStyle(
                      color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            if (immat.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Immatriculation: $immat',
                  style: const TextStyle(color: _muted, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _mapButton(IconData icon,
      {Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _card.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? _muted).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: color ?? _muted, size: 20),
      ),
    );
  }
}
