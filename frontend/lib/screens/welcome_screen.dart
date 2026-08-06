import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'login_screen.dart';
import 'register_choice_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ══════════════════════════════════════════════════
  // COULEURS NÉON — VIOLET / ROSE (جديد)
  // ══════════════════════════════════════════════════
  static const Color _bg = Color(0xFF0A0612);
  static const Color _surface = Color(0xFF13091F);
  static const Color _neonPrimary =
      Color.fromARGB(255, 78, 33, 185); // Violet néon
  static const Color _neonSecondary =
      Color.fromARGB(255, 118, 146, 255); // Rose néon
  static const Color _white = Colors.white;
  static const Color _white60 = Color(0x99FFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _gold = Color(0xFFF59E0B);

  int _selectedIndex = 0;

  // ════════ Bus tracking state ════════
  Map<String, _BusData> _buses = {};
  bool _isLoadingBuses = true;
  bool _socketOk = false;
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  IO.Socket? _socket;
  Timer? _fallbackTimer;

  static const LatLng _defaultCenter = LatLng(36.2, 6.26);

  @override
  void initState() {
    super.initState();
    _loadInitialBuses();
    _connectSocket();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _fallbackTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════
  // BUS TRACKING LOGIC
  // ════════════════════════════════════════
  Future<void> _loadInitialBuses() async {
    if (!mounted) return;
    setState(() => _isLoadingBuses = _buses.isEmpty);
    try {
      final r = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/trajets/actifs'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && mounted) {
        final list = jsonDecode(r.body) as List;
        _majDepuisListe(list);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingBuses = false);
  }

  void _majDepuisListe(List list) {
    final newBuses = <String, _BusData>{};
    for (final p in list) {
      final id = p['trajet_id']?.toString() ?? '';
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
      if (mounted) setState(() => _socketOk = true);
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _socketOk = false);
      _fallbackTimer ??= Timer.periodic(
          const Duration(seconds: 15), (_) => _loadInitialBuses());
    });

    _socket!.onConnectError((_) {
      if (mounted) setState(() => _socketOk = false);
      _fallbackTimer ??= Timer.periodic(
          const Duration(seconds: 15), (_) => _loadInitialBuses());
    });

    _socket!.on('position_broadcast', (data) {
      if (!mounted) return;
      final trajetId = data['trajet_id']?.toString() ?? '';
      if (trajetId.isEmpty) return;

      setState(() {
        final old = _buses[trajetId];
        final newLat = _toDouble(data['latitude']);
        final newLng = _toDouble(data['longitude']);

        _buses[trajetId] = _BusData(
          trajetId: trajetId,
          lat: newLat,
          lng: newLng,
          previousLat: old?.lat ?? newLat,
          previousLng: old?.lng ?? newLng,
          vitesse: _toDouble(data['vitesse']),
          ligneId: data['ligne_id']?.toString() ?? '',
          ligneNumero: data['ligne_numero'] ?? '',
          ligneNom: data['ligne_nom'] ?? '',
          conducteurNom: data['conducteur_nom'] ?? '',
          immatriculation: data['immatriculation'] ?? '',
          lastUpdate: DateTime.now(),
        );
      });

      final busesList = _buses.values.toList();
      if (busesList.length == 1 && _searchCtrl.text.isEmpty) {
        _mapCtrl.move(
          LatLng(_toDouble(data['latitude']), _toDouble(data['longitude'])),
          _mapCtrl.camera.zoom,
        );
      }
    });

    _socket!.on('trajet_demarre', (_) => _loadInitialBuses());

    _socket!.on('trajet_termine', (data) {
      final trajetId = data['trajet_id']?.toString() ?? '';
      if (trajetId.isNotEmpty && mounted) {
        setState(() => _buses.remove(trajetId));
      }
    });
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
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

  void _onSearchChanged() {
    setState(() {});
    final filtres = _busesFiltres;
    if (_searchCtrl.text.trim().isNotEmpty && filtres.length == 1) {
      _mapCtrl.move(LatLng(filtres[0].lat, filtres[0].lng), 15);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showBusDetails(_BusData bus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _white.withOpacity(0.08)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _neonPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _neonPrimary.withOpacity(0.3)),
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    color: _neonPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ligne ${bus.ligneNumero}',
                          style: const TextStyle(
                              color: _white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(bus.ligneNom,
                          style:
                              const TextStyle(color: _textMuted, fontSize: 13)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _neonPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _neonPrimary.withOpacity(0.3)),
                ),
                child: const Text('En service',
                    style: TextStyle(
                        color: _neonPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            Divider(color: _white.withOpacity(0.08), height: 24),
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
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: _textMuted, size: 18),
      const SizedBox(width: 10),
      Text('$label : ',
          style: const TextStyle(color: _textMuted, fontSize: 13)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                color: _white, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    ]);
  }

  // ════════════════════════════════════════
  // LANGUE
  // ════════════════════════════════════════
  void _showLanguageSheet() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Langue / اللغة / Language',
                style: TextStyle(
                    color: _white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _langSheetItem(
                  '🇫🇷', 'Français', const Locale('fr'), localeProvider),
              const SizedBox(height: 10),
              _langSheetItem(
                  '🇸🇦', 'العربية', const Locale('ar'), localeProvider),
              const SizedBox(height: 10),
              _langSheetItem(
                  '🇬🇧', 'English', const Locale('en'), localeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langSheetItem(
      String flag, String label, Locale locale, LocaleProvider provider) {
    final isActive = provider.locale.languageCode == locale.languageCode;
    return GestureDetector(
      onTap: () {
        provider.setLocale(locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? _neonPrimary.withOpacity(0.15) : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? _neonPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _neonPrimary : _white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check_circle_rounded,
                  color: _neonPrimary, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final l = AppLocalizations.of(context)!;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bg,
          extendBodyBehindAppBar: true,
          drawer: _buildDrawer(l),
          body: _buildBody(l),
          bottomNavigationBar: _buildBottomNav(l),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations l) {
    switch (_selectedIndex) {
      case 0:
        return _buildHome(l);
      case 1:
        return _buildLignesView(l);
      case 3:
        return _buildAnnoncesView(l);
      default:
        return _buildHome(l);
    }
  }

  // ════════════════════════════════════════
  // 🏠 HOME — خريطة + بار بحث زجاجي
  // ════════════════════════════════════════
  Widget _buildHome(AppLocalizations l) {
    final buses = _busesFiltres;

    return Stack(
      children: [
        // ── الخريطة الحقيقية ──
        Positioned.fill(
          child: _isLoadingBuses
              ? Container(
                  color: _bg,
                  child: const Center(
                      child: CircularProgressIndicator(color: _neonPrimary)),
                )
              : FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: buses.isNotEmpty
                        ? LatLng(buses[0].lat, buses[0].lng)
                        : _defaultCenter,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.transportdz.app',
                    ),
                    MarkerLayer(
                      markers: buses
                          .map((bus) => Marker(
                                point: LatLng(bus.lat, bus.lng),
                                width: 70,
                                height: 70,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeInOut,
                                  builder: (ctx, t, child) {
                                    return GestureDetector(
                                      onTap: () => _showBusDetails(bus),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _neonPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _neonPrimary
                                                      .withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              bus.ligneNumero.isEmpty
                                                  ? '?'
                                                  : bus.ligneNumero,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const Icon(
                                              Icons.directions_bus_rounded,
                                              color: _neonPrimary,
                                              size: 32),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
        ),

        // ── HEADER زجاجي ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GlassButton(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(Icons.menu_rounded,
                          color: _white, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _neonPrimary.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text('TransportDz',
                              style: TextStyle(
                                  color: _white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                          Text('DZ',
                              style: TextStyle(
                                  color: _neonPrimary.withOpacity(0.9),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3)),
                        ],
                      ),
                    ),
                    _GlassButton(
                      onTap: _showLanguageSheet,
                      child: const Icon(Icons.language_rounded,
                          color: _white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── SEARCH BAR زجاجي ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _surface.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: _neonPrimary.withOpacity(0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: _neonPrimary.withOpacity(0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search_rounded,
                              color: _neonPrimary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style:
                                  const TextStyle(color: _white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Rechercher une ligne (ex: L1)...',
                                hintStyle: const TextStyle(
                                    color: _textMuted, fontSize: 14),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.clear,
                                    color: _textMuted, size: 18),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.all(7),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _socketOk
                                  ? _neonPrimary.withOpacity(0.15)
                                  : _neonSecondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _socketOk
                                    ? _neonPrimary.withOpacity(0.4)
                                    : _neonSecondary.withOpacity(0.4),
                              ),
                            ),
                            child: Icon(
                              _socketOk
                                  ? Icons.wifi_rounded
                                  : Icons.wifi_off_rounded,
                              color: _socketOk ? _neonPrimary : _neonSecondary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── badge En direct + count ──
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _surface.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _neonPrimary.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: _neonPrimary.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: _neonPrimary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(l.enDirect,
                              style: const TextStyle(
                                  color: _neonPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _surface.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _white.withOpacity(0.08)),
                      ),
                      child: Text(
                        buses.isEmpty
                            ? 'Aucun bus'
                            : '${buses.length} bus en service',
                        style: const TextStyle(color: _white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── boutons zoom + recentrage ──
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              _mapButton(Icons.add, onTap: () {
                _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
              }),
              const SizedBox(height: 8),
              _mapButton(Icons.remove, onTap: () {
                _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
              }),
              const SizedBox(height: 8),
              _mapButton(Icons.refresh_rounded,
                  color: _neonPrimary, onTap: _loadInitialBuses),
            ],
          ),
        ),

        // ── رسالة "ماكاينش بوصات" ──
        if (!_isLoadingBuses && buses.isEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          color: _textMuted, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _searchCtrl.text.isNotEmpty
                            ? 'Aucun bus trouvé pour cette recherche'
                            : 'Aucun bus en service pour le moment',
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mapButton(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (color ?? _textMuted).withOpacity(0.3)),
            ),
            child: Icon(icon, color: color ?? _textMuted, size: 18),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // LIGNES VIEW — ديزاين نيون
  // ════════════════════════════════════════
  Widget _buildLignesView(AppLocalizations l) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(l.lignes,
                style: const TextStyle(
                    color: _white, fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchLignesReelles(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(
                      child: CircularProgressIndicator(color: _neonPrimary));
                if (!snap.hasData || snap.data!.isEmpty)
                  return const Center(
                    child: Text('Aucune ligne disponible',
                        style: TextStyle(color: _textMuted)),
                  );
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final lg = snap.data![i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _LigneDetailPage(ligne: lg),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surface.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: _neonPrimary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_neonPrimary, _neonSecondary],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _neonPrimary.withOpacity(0.3),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  lg['numero'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lg['nom'] ?? '',
                                      style: const TextStyle(
                                          color: _white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    if (lg['heure_debut'] != null) ...[
                                      const Icon(Icons.access_time,
                                          color: _textMuted, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${lg['heure_debut'].toString().substring(0, 5)} → ${lg['heure_fin'].toString().substring(0, 5)}',
                                        style: const TextStyle(
                                            color: _textMuted, fontSize: 12),
                                      ),
                                    ],
                                    if (lg['moyenne'] != null &&
                                        lg['moyenne'].toString() != 'null') ...[
                                      const SizedBox(width: 10),
                                      const Icon(Icons.star,
                                          color: _gold, size: 13),
                                      const SizedBox(width: 3),
                                      Text(lg['moyenne'].toString(),
                                          style: const TextStyle(
                                              color: _textMuted, fontSize: 12)),
                                    ],
                                  ]),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: _white30, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchLignesReelles() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/ligne'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  // ════════════════════════════════════════
  // ANNONCES VIEW — ديزاين نيون جديد ✨
  // ════════════════════════════════════════
  Widget _buildAnnoncesView(AppLocalizations l) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _neonPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _neonPrimary.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: _neonPrimary.withOpacity(0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: _neonPrimary, size: 26),
                ),
                const SizedBox(width: 14),
                Text(l.annonces,
                    style: const TextStyle(
                        color: _white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: _AnnoncesBanner(
              bg: _bg,
              surface: _surface,
              gold: _gold,
              text: _white,
              textMuted: _textMuted,
              neonPrimary: _neonPrimary,
              neonSecondary: _neonSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // BOTTOM NAV — زجاجي نيون
  // ════════════════════════════════════════
  Widget _buildBottomNav(AppLocalizations l) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.75),
            border: Border(
              top: BorderSide(color: _neonPrimary.withOpacity(0.15)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.map_rounded, 'Carte', 0),
                  _navItem(Icons.route_rounded, l.navLignes, 1),
                  _navItem(Icons.campaign_rounded, l.navAnnonces, 3),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_neonPrimary, _neonSecondary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _neonPrimary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.login_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.navConnexion,
                          style: const TextStyle(
                            color: _neonPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _neonPrimary : _textMuted, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: isSelected ? _neonPrimary : _textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // DRAWER — ديزاين نيون
  // ════════════════════════════════════════
  Widget _buildDrawer(AppLocalizations l) {
    return Drawer(
      backgroundColor: _bg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _neonPrimary.withOpacity(0.2),
                  _bg,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_neonPrimary, _neonSecondary]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _neonPrimary.withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                const Text('TransportDz',
                    style: TextStyle(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(l.reseauTransport,
                    style: const TextStyle(color: _textMuted, fontSize: 13)),
              ],
            ),
          ),
          _drawerItem(Icons.map_rounded, 'Carte en direct',
              () => setState(() => _selectedIndex = 0)),
          _drawerItem(
              Icons.route, l.lignes, () => setState(() => _selectedIndex = 1)),
          _drawerItem(Icons.campaign_rounded, l.annonces,
              () => setState(() => _selectedIndex = 3)),
          _drawerItem(Icons.warning_amber, l.retardsPannes, () {},
              color: _gold),
          _drawerItem(Icons.info, l.informations, () {}),
          Divider(color: _white.withOpacity(0.08)),
          _drawerItem(Icons.language_rounded, '${l.language} / اللغة',
              _showLanguageSheet),
          _drawerItem(Icons.login_rounded, l.seConnecter, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          }, color: _neonPrimary),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? _textMuted, size: 22),
      title:
          Text(label, style: TextStyle(color: color ?? _white, fontSize: 15)),
      onTap: onTap,
    );
  }
}

// ════════════════════════════════════════
// DATA CLASS
// ════════════════════════════════════════
class _BusData {
  final String trajetId;
  final double lat;
  final double lng;
  final double previousLat;
  final double previousLng;
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
    this.previousLat = 0,
    this.previousLng = 0,
    required this.vitesse,
    required this.ligneId,
    required this.ligneNumero,
    required this.ligneNom,
    required this.conducteurNom,
    required this.immatriculation,
    required this.lastUpdate,
  });
}

// ══════════════════════════════════════
// LIGNE DETAIL PAGE — ديزاين نيون
// ══════════════════════════════════════
class _LigneDetailPage extends StatelessWidget {
  final Map<String, dynamic> ligne;
  const _LigneDetailPage({required this.ligne});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0612),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13091F),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          '${ligne['numero']} — ${ligne['nom']}',
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info ligne ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ligne['numero'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      if (ligne['moyenne'] != null &&
                          ligne['moyenne'].toString() != 'null')
                        Row(children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(ligne['moyenne'].toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ligne['nom'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (ligne['heure_debut'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${ligne['heure_debut'].toString().substring(0, 5)} → ${ligne['heure_fin'].toString().substring(0, 5)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Horaires ──
            const Text('Horaires disponibles',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _fetchHoraires(ligne['id']),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                if (!snap.hasData || snap.data!.isEmpty)
                  return const Text('Aucun horaire disponible',
                      style: TextStyle(color: Color(0xFF94A3B8)));
                return Column(
                  children: snap.data!.map((h) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13091F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(children: [
                              Text(
                                h['heure_depart']?.toString().substring(0, 5) ??
                                    '--:--',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded,
                                    color: Color(0xFF94A3B8), size: 16),
                              ),
                              Text(
                                h['heure_arrivee']
                                        ?.toString()
                                        .substring(0, 5) ??
                                    '--:--',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ),
                          if (h['point_depart'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  h['point_depart'] ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                                Text(
                                  h['point_arrivee'] ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchHoraires(int? ligneId) async {
    if (ligneId == null) return [];
    try {
      final r = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/ligne/$ligneId/horaires'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }
}

// ════════════════════════════════════════
// ANNONCES — ديزاين نيون جديد ✨
// ════════════════════════════════════════
class _AnnoncesBanner extends StatefulWidget {
  final Color bg;
  final Color surface;
  final Color gold;
  final Color text;
  final Color textMuted;
  final Color neonPrimary;
  final Color neonSecondary;

  const _AnnoncesBanner({
    required this.bg,
    required this.surface,
    required this.gold,
    required this.text,
    required this.textMuted,
    required this.neonPrimary,
    required this.neonSecondary,
  });

  @override
  State<_AnnoncesBanner> createState() => _AnnoncesBannerState();
}

class _AnnoncesBannerState extends State<_AnnoncesBanner> {
  List<Map<String, dynamic>> _annonces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await http
          .get(Uri.parse(ApiConstants.annonces))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final List<dynamic> data = jsonDecode(r.body);
        setState(() {
          _annonces = List<Map<String, dynamic>>.from(
            data.where((item) => item != null && item is Map),
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading annonces: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _iconFromType(String? type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'alert':
        return Icons.error_outline_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _colorFromType(String? type) {
    switch (type) {
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'alert':
        return const Color(0xFFEF4444);
      case 'success':
        return const Color(0xFF10B981);
      case 'info':
      default:
        return widget.neonPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }
    if (_annonces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined,
                size: 72, color: widget.text.withOpacity(0.08)),
            const SizedBox(height: 16),
            Text(
              'Aucune annonce pour le moment',
              style: TextStyle(
                color: widget.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez plus tard pour les mises à jour',
              style: TextStyle(
                color: widget.textMuted.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _annonces.length,
      itemBuilder: (_, i) {
        final annonce = _annonces[i];
        final String? type = annonce['type']?.toString();
        final String title = annonce['titre']?.toString() ?? 'Sans titre';
        final String desc = annonce['contenu']?.toString() ?? '';
        final dynamic createdAt = annonce['created_at'];
        final String date =
            createdAt != null ? createdAt.toString().substring(0, 10) : '';
        final Color typeColor = _colorFromType(type);
        final IconData iconData = _iconFromType(type);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.surface.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: typeColor.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // أيقونة كبيرة ملونة داخل مربع نيون
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                typeColor.withOpacity(0.3),
                                typeColor.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: typeColor.withOpacity(0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: typeColor.withOpacity(0.15),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Icon(iconData, color: typeColor, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: typeColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  date,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // خط فاصل خفيف
                    Container(
                      width: double.infinity,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: TextStyle(
                        color: widget.textMuted,
                        fontSize: 13.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════
// GLASS BUTTON — مكون مشترك
// ══════════════════════════════════════════════════
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border:
                  Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
