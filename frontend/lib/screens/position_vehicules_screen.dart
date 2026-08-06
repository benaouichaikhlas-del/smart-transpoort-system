import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';

// ══════════════════════════════════════════════════════════
// SUIVRE BUS PAGE
// تتبع الباص في الوقت الحقيقي عبر Socket.IO
// يُستخدم من: PassagerHomeScreen / VisiteurScreen
// ══════════════════════════════════════════════════════════
class SuivreBusPage extends StatefulWidget {
  final int? ligneId;
  final String? token;
  final int? proprietaireId;

  const SuivreBusPage({
    super.key,
    this.ligneId,
    this.token,
    this.proprietaireId,
  });

  @override
  State<SuivreBusPage> createState() => _SuivreBusPageState();
}

class _SuivreBusPageState extends State<SuivreBusPage> {
  // ── State ──
  Map<String, _BusData> _buses = {}; // trajet_id → BusData
  bool _isLoading = true;
  String? _errorMsg;
  bool _socketOk = false;

  // ── Controllers ──
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  IO.Socket? _socket;
  Timer? _fallbackTimer; // HTTP fallback كل 15 ثانية

  // الجزائر — مركز افتراضي
  static const LatLng _defaultCenter = LatLng(36.2, 6.26); // ميلة تقريباً

  // ══════════════════════════════════════
  // INIT / DISPOSE
  // ══════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _loadInitial();
    _connectSocket();
    _searchCtrl.addListener(_filtrer);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _fallbackTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  // HTTP — تحميل أولي
  // ══════════════════════════════════════
  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      String url = '${ApiConstants.baseUrl}/trajets/actifs';
      if (widget.proprietaireId != null) {
        url += '?proprietaire_id=${widget.proprietaireId}';
      } else if (widget.ligneId != null) {
        url += '?ligne_id=${widget.ligneId}';
      }

      final r =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (r.statusCode == 200 && mounted) {
        final list = jsonDecode(r.body) as List;
        _majDepuisListe(list);
      }
    } catch (_) {
      if (mounted)
        setState(() => _errorMsg = 'Impossible de charger les positions');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ══════════════════════════════════════
  // SOCKET.IO — connexion
  // ══════════════════════════════════════
  void _connectSocket() {
    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('🔌 SuivreBus — Socket connecté');
      if (mounted) setState(() => _socketOk = true);
      // نوقفو الـ fallback timer إذا Socket شغال
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 SuivreBus — Socket déconnecté');
      if (mounted) setState(() => _socketOk = false);
      // نبداو HTTP fallback كل 15 ثانية
      _fallbackTimer ??= Timer.periodic(
        const Duration(seconds: 15),
        (_) => _loadInitial(),
      );
    });

    _socket!.onConnectError((_) {
      debugPrint('❌ SuivreBus — Socket erreur connexion');
      if (mounted) setState(() => _socketOk = false);
      _fallbackTimer ??= Timer.periodic(
        const Duration(seconds: 15),
        (_) => _loadInitial(),
      );
    });

    // ── استقبال الموقع في الوقت الحقيقي ──
    _socket!.on('position_broadcast', (data) {
      if (!mounted) return;
      debugPrint('📍 position_broadcast reçu: $data');

      // نفلترو حسب الـ ligne إذا محددة
      if (widget.proprietaireId != null) {
        final propId = data['proprietaire_id'];
        if (propId?.toString() != widget.proprietaireId.toString()) return;
      }

      if (widget.ligneId != null &&
          data['ligne_id']?.toString() != widget.ligneId.toString()) return;

      final trajetId = data['trajet_id']?.toString() ?? '';
      if (trajetId.isEmpty) return;

      setState(() {
        _buses[trajetId] = _BusData(
          trajetId: trajetId,
          lat: _toDouble(data['latitude']),
          lng: _toDouble(data['longitude']),
          vitesse: _toDouble(data['vitesse']),
          ligneId: data['ligne_id']?.toString() ?? '',
          ligneNumero: data['ligne_numero'] ?? '',
          ligneNom: data['ligne_nom'] ?? '',
          conducteurNom: data['conducteur_nom'] ?? '',
          immatriculation: data['immatriculation'] ?? '',
          lastUpdate: DateTime.now(),
        );
      });
    });

    // ── باص جديد بدأ ──
    _socket!.on('trajet_demarre', (data) {
      debugPrint('🚌 trajet_demarre: $data');
      _loadInitial(); // نعيدو التحميل باش ناخدو تفاصيل الباص
    });

    // ── باص انتهى ──
    _socket!.on('trajet_termine', (data) {
      debugPrint('🛑 trajet_termine: $data');
      final trajetId = data['trajet_id']?.toString() ?? '';
      if (trajetId.isNotEmpty && mounted) {
        setState(() => _buses.remove(trajetId));
      }
    });
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  void _majDepuisListe(List list) {
    final newBuses = <String, _BusData>{};
    for (final p in list) {
      final id =
          p['trajet_id']?.toString() ?? p['conducteur_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      newBuses[id] = _BusData(
        trajetId: id,
        lat: _toDouble(p['latitude']),
        lng: _toDouble(p['longitude']),
        vitesse: _toDouble(p['vitesse']),
        ligneId: p['ligne_id']?.toString() ?? '',
        ligneNumero: p['ligne_numero'] ?? '',
        ligneNom: p['ligne_nom'] ?? '',
        conducteurNom:
            '${p['conducteur_prenom'] ?? ''} ${p['conducteur_nom'] ?? ''}'
                .trim(),
        immatriculation: p['immatriculation'] ?? '',
        lastUpdate:
            DateTime.tryParse(p['derniere_maj'] ?? '') ?? DateTime.now(),
      );
    }
    if (mounted) setState(() => _buses = newBuses);
  }

  List<_BusData> get _busesFiltres {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _buses.values.toList();
    return _buses.values
        .where((b) =>
            b.ligneNumero.toLowerCase().contains(q) ||
            b.ligneNom.toLowerCase().contains(q))
        .toList();
  }

  void _filtrer() => setState(() {});

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Détails du bus (bottom sheet) ──
  void _showBusDetails(_BusData bus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_bus_rounded,
                  color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ligne ${bus.ligneNumero}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(bus.ligneNom,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('En service',
                  style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),

          const Divider(color: Colors.white12, height: 24),

          _infoRow(Icons.person_outline, 'Conducteur',
              bus.conducteurNom.isEmpty ? '—' : bus.conducteurNom),
          const SizedBox(height: 10),
          _infoRow(Icons.directions_car_outlined, 'Véhicule',
              bus.immatriculation.isEmpty ? '—' : bus.immatriculation),
          const SizedBox(height: 10),
          _infoRow(Icons.speed_outlined, 'Vitesse',
              '${bus.vitesse.toStringAsFixed(0)} km/h'),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time_outlined, 'Mise à jour',
              _formatTime(bus.lastUpdate)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.white38, size: 18),
      const SizedBox(width: 10),
      Text('$label : ',
          style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500))),
    ]);
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final buses = _busesFiltres;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi des Bus',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(
            buses.isEmpty
                ? 'Aucun bus en service'
                : '${buses.length} bus en service',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ]),
        actions: [
          // Indicateur Socket
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              _socketOk ? Icons.wifi : Icons.wifi_off,
              color: _socketOk ? AppTheme.secondary : Colors.white38,
              size: 18,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitial,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [
              // ── Barre de recherche ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppTheme.surface,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par numéro ou nom de ligne...',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filtrer();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // ── Carte OpenStreetMap ──
              Expanded(
                child: _errorMsg != null
                    ? _buildError()
                    : FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: buses.isNotEmpty
                              ? LatLng(buses[0].lat, buses[0].lng)
                              : _defaultCenter,
                          initialZoom: 13,
                        ),
                        children: [
                          // Tuiles OpenStreetMap (مجانية)
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.transportdz.app',
                          ),

                          // Marqueurs الباصات
                          MarkerLayer(
                            markers: buses
                                .map((bus) => Marker(
                                      point: LatLng(bus.lat, bus.lng),
                                      width: 60,
                                      height: 60,
                                      child: GestureDetector(
                                        onTap: () => _showBusDetails(bus),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primary
                                                        .withOpacity(0.4),
                                                    blurRadius: 4,
                                                  )
                                                ],
                                              ),
                                              child: Text(
                                                bus.ligneNumero.isEmpty
                                                    ? '?'
                                                    : bus.ligneNumero,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const Icon(
                                                Icons.directions_bus_rounded,
                                                color: AppTheme.primary,
                                                size: 28),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
              ),

              // ── Aucun bus ──
              if (!_isLoading && buses.isEmpty && _errorMsg == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.surface,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white38, size: 16),
                      SizedBox(width: 8),
                      Text('Aucun bus en service pour le moment',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                ),
            ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.gps_off, color: AppTheme.error, size: 60),
          const SizedBox(height: 16),
          Text(_errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadInitial,
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
}

// ══════════════════════════════════════
// DATA CLASS
// ══════════════════════════════════════
class _BusData {
  final String trajetId;
  final double lat;
  final double lng;
  final double vitesse;
  final String ligneId;
  final String ligneNumero;
  final String ligneNom;
  final String conducteurNom;
  final String immatriculation;
  final DateTime lastUpdate;

  const _BusData({
    required this.trajetId,
    required this.lat,
    required this.lng,
    required this.vitesse,
    required this.ligneId,
    required this.ligneNumero,
    required this.ligneNom,
    required this.conducteurNom,
    required this.immatriculation,
    required this.lastUpdate,
  });
}
