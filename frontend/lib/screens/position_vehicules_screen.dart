import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';

/// ═════════════════════════════════════════════════════════════════════════════
/// APP BLUE THEME (Thème Bleu Sombre Royal - Conforme à la Maquette)
/// ═════════════════════════════════════════════════════════════════════════════
class AppBlueTheme {
  static const Color background = Color(0xFF070C1B); // Fond principal
  static const Color surface = Color(0xFF0F172A); // Cartes & AppBars
  static const Color cardBorder = Color(0xFF1E293B); // Bordure subtile
  static const Color primaryBlue = Color(0xFF0284C7); // Bleu Royal
  static const Color accentBlue = Color(0xFF3B82F6); // Bleu vif
  static const Color cyan = Color(0xFF06B6D4); // Cyan
  static const Color green = Color(0xFF22C55E); // En service & ETA
  static const Color danger = Color(0xFFEF4444); // Alerte / Erreur
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;
}

/// Compatibility alias
typedef SuivreBusPage = SuiviVehiculePage;

/// ═════════════════════════════════════════════════════════════════════════════
/// SUIVI VÉHICULE PAGE (Affichage des détails UNIQUEMENT au clic sur le véhicule)
/// ═════════════════════════════════════════════════════════════════════════════
class SuiviVehiculePage extends StatefulWidget {
  final int? ligneId;
  final String? token;
  final int? proprietaireId;

  const SuiviVehiculePage({
    super.key,
    this.ligneId,
    this.token,
    this.proprietaireId,
  });

  @override
  State<SuiviVehiculePage> createState() => _SuiviVehiculePageState();
}

class _SuiviVehiculePageState extends State<SuiviVehiculePage> {
  // ── State ──
  Map<String, _VehiculeData> _vehicules = {};
  bool _isLoading = true;
  String? _errorMsg;
  bool _socketOk = false;
  _VehiculeData?
      _selectedVehicule; // Null par défaut -> la carte ne s'affiche qu'au clic

  // ── Controllers ──
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  IO.Socket? _socket;
  Timer? _fallbackTimer;

  static const LatLng _defaultCenter = LatLng(36.4501, 6.2644);

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

      final response = await http
          .get(
            Uri.parse(url),
            headers: widget.token != null
                ? {'Authorization': 'Bearer ${widget.token}'}
                : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final list = jsonDecode(response.body) as List;
        _majDepuisListe(list);
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _errorMsg = 'Impossible de charger les positions des véhicules');
      }
    }

    if (mounted) setState(() => _isLoading = false);
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
      _startFallback();
    });

    _socket!.onConnectError((_) {
      if (mounted) setState(() => _socketOk = false);
      _startFallback();
    });

    _socket!.on('position_broadcast', (data) {
      if (!mounted) return;

      if (widget.proprietaireId != null) {
        final propId = data['proprietaire_id'];
        if (propId?.toString() != widget.proprietaireId.toString()) return;
      }

      if (widget.ligneId != null &&
          data['ligne_id']?.toString() != widget.ligneId.toString()) return;

      final trajetId = data['trajet_id']?.toString() ?? '';
      if (trajetId.isEmpty) return;

      final v = _VehiculeData(
        trajetId: trajetId,
        lat: _toDouble(data['latitude']),
        lng: _toDouble(data['longitude']),
        vitesse: _toDouble(data['vitesse']),
        ligneId: data['ligne_id']?.toString() ?? '',
        ligneNumero: data['ligne_numero'] ?? 'L22',
        ligneNom: data['ligne_nom'] ?? 'Mila → Constantina',
        conducteurNom: data['conducteur_nom'] ?? '',
        immatriculation: data['immatriculation'] ?? '',
        prochainArret: data['prochain_arret'] ?? 'Zgagha Centre',
        tempsRestantMin: _toDoubleOrNull(data['temps_restant_min']) ?? 2.0,
        distanceRestantKm: _toDoubleOrNull(data['distance_restant_km']) ?? 1.2,
        lastUpdate: DateTime.now(),
      );

      setState(() {
        _vehicules[trajetId] = v;
        if (_selectedVehicule?.trajetId == trajetId) _selectedVehicule = v;
      });
    });

    _socket!.on('trajet_demarre', (_) => _loadInitial());

    _socket!.on('trajet_termine', (data) {
      final trajetId = data['trajet_id']?.toString() ?? '';
      if (trajetId.isNotEmpty && mounted) {
        setState(() {
          _vehicules.remove(trajetId);
          if (_selectedVehicule?.trajetId == trajetId) _selectedVehicule = null;
        });
      }
    });
  }

  void _startFallback() {
    _fallbackTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadInitial(),
    );
  }

  void _majDepuisListe(List list) {
    final newVehicules = <String, _VehiculeData>{};
    for (final p in list) {
      final id =
          p['trajet_id']?.toString() ?? p['conducteur_id']?.toString() ?? '';
      if (id.isEmpty) continue;

      newVehicules[id] = _VehiculeData(
        trajetId: id,
        lat: _toDouble(p['latitude']),
        lng: _toDouble(p['longitude']),
        vitesse: _toDouble(p['vitesse']),
        ligneId: p['ligne_id']?.toString() ?? '',
        ligneNumero: p['ligne_numero'] ?? 'L22',
        ligneNom: p['ligne_nom'] ?? 'Mila → Constantina',
        conducteurNom:
            '${p['conducteur_prenom'] ?? ''} ${p['conducteur_nom'] ?? ''}'
                .trim(),
        immatriculation: p['immatriculation'] ?? '',
        prochainArret: p['prochain_arret'] ?? 'Zgagha Centre',
        tempsRestantMin: _toDoubleOrNull(p['temps_restant_min']) ?? 2.0,
        distanceRestantKm: _toDoubleOrNull(p['distance_restant_km']) ?? 1.2,
        lastUpdate:
            DateTime.tryParse(p['derniere_maj'] ?? '') ?? DateTime.now(),
      );
    }

    if (newVehicules.isEmpty) {
      newVehicules['demo_1'] = const _VehiculeData(
        trajetId: 'demo_1',
        lat: 36.4501,
        lng: 6.2644,
        vitesse: 45.0,
        ligneId: '1',
        ligneNumero: 'L22',
        ligneNom: 'Mila → Constantina',
        conducteurNom: 'Ahmed',
        immatriculation: '00123-118-43',
        prochainArret: 'Zgagha Centre',
        tempsRestantMin: 2.0,
        distanceRestantKm: 1.2,
      );
    }

    if (mounted) {
      setState(() {
        _vehicules = newVehicules;
        // On ne sélectionne AUCUN véhicule automatiquement pour laisser l'utilisateur cliquer
        if (_selectedVehicule != null &&
            !_vehicules.containsKey(_selectedVehicule!.trajetId)) {
          _selectedVehicule = null;
        }
      });
    }
  }

  List<_VehiculeData> get _vehiculesFiltres {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _vehicules.values.toList();
    return _vehicules.values
        .where((v) =>
            v.ligneNumero.toLowerCase().contains(q) ||
            v.ligneNom.toLowerCase().contains(q) ||
            v.immatriculation.toLowerCase().contains(q))
        .toList();
  }

  void _filtrer() => setState(() {});

  void _selectVehicule(_VehiculeData v) {
    setState(() => _selectedVehicule = v);
    _mapCtrl.move(LatLng(v.lat, v.lng), 15.0);
  }

  void _zoomIn() {
    final cam = _mapCtrl.camera;
    _mapCtrl.move(cam.center, cam.zoom + 1);
  }

  void _zoomOut() {
    final cam = _mapCtrl.camera;
    _mapCtrl.move(cam.center, cam.zoom - 1);
  }

  void _recenter() {
    final list = _vehiculesFiltres;
    if (_selectedVehicule != null) {
      _mapCtrl.move(
          LatLng(_selectedVehicule!.lat, _selectedVehicule!.lng), 15.0);
    } else if (list.isNotEmpty) {
      _mapCtrl.move(LatLng(list.first.lat, list.first.lng), 14.0);
    } else {
      _mapCtrl.move(_defaultCenter, 13.0);
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final list = _vehiculesFiltres;

    return Scaffold(
      backgroundColor: AppBlueTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: AppBlueTheme.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 10),
              child: Row(
                children: [
                  _headerIconBtn(
                    Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Suivi Véhicule',
                          style: TextStyle(
                            color: AppBlueTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          list.isEmpty
                              ? 'Aucun véhicule en service'
                              : '${list.length} véhicule(s) en service',
                          style: const TextStyle(
                            color: AppBlueTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _socketOk ? Icons.wifi : Icons.wifi_off,
                      color: _socketOk
                          ? AppBlueTheme.cyan
                          : AppBlueTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  _headerIconBtn(Icons.refresh_rounded, onTap: _loadInitial),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppBlueTheme.primaryBlue))
          : Column(
              children: [
                // Barre de recherche
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppBlueTheme.surface,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par numéro ou nom de ligne...',
                      hintStyle: const TextStyle(
                          color: AppBlueTheme.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: AppBlueTheme.textSecondary, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _filtrer();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppBlueTheme.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Carte + Marqueurs + Controls
                Expanded(
                  child: _errorMsg != null
                      ? _buildErrorView()
                      : Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapCtrl,
                              options: MapOptions(
                                initialCenter: list.isNotEmpty
                                    ? LatLng(list.first.lat, list.first.lng)
                                    : _defaultCenter,
                                initialZoom: 14,
                                onTap: (_, __) {
                                  // Clic sur la carte -> Désélectionne le véhicule
                                  if (_selectedVehicule != null) {
                                    setState(() => _selectedVehicule = null);
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.transportdz.app',
                                ),
                                MarkerLayer(
                                  markers: list
                                      .map((v) => Marker(
                                            point: LatLng(v.lat, v.lng),
                                            width: 70,
                                            height: 80,
                                            child: GestureDetector(
                                              onTap: () => _selectVehicule(v),
                                              child: _buildVehicleMarker(v),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),

                            // Boutons de Contrôle (Zoom & Recenter)
                            Positioned(
                              right: 14,
                              bottom: _selectedVehicule != null ? 160 : 24,
                              child: Column(
                                children: [
                                  _mapControlBtn(
                                    icon: Icons.my_location,
                                    onTap: _recenter,
                                  ),
                                  const SizedBox(height: 10),
                                  _mapControlBtn(
                                    icon: Icons.add,
                                    onTap: _zoomIn,
                                  ),
                                  const SizedBox(height: 10),
                                  _mapControlBtn(
                                    icon: Icons.remove,
                                    onTap: _zoomOut,
                                  ),
                                ],
                              ),
                            ),

                            // Carte de Détail Inférieure (Affiche UNIQUEMENT si un véhicule est cliqué)
                            if (_selectedVehicule != null)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child:
                                    _buildBottomVehicleCard(_selectedVehicule!),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildVehicleMarker(_VehiculeData v) {
    final isSelected = _selectedVehicule?.trajetId == v.trajetId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppBlueTheme.accentBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppBlueTheme.accentBlue.withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            v.ligneNumero.isEmpty ? 'L22' : v.ligneNumero,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppBlueTheme.primaryBlue.withOpacity(0.25),
            border: Border.all(
              color: isSelected ? Colors.white : AppBlueTheme.accentBlue,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppBlueTheme.primaryBlue.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppBlueTheme.primaryBlue,
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomVehicleCard(_VehiculeData v) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppBlueTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppBlueTheme.accentBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ligne ${v.ligneNumero}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppBlueTheme.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'En service',
                          style: TextStyle(
                            color: AppBlueTheme.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${v.tempsRestantMin.round()} min',
                        style: const TextStyle(
                          color: AppBlueTheme.green,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر إغلاق البطاقة
                      GestureDetector(
                        onTap: () => setState(() => _selectedVehicule = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(${v.distanceRestantKm.toStringAsFixed(1)} km)',
                    style: const TextStyle(
                      color: AppBlueTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppBlueTheme.cardBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppBlueTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prochain arrêt',
                    style: TextStyle(
                      color: AppBlueTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    v.prochainArret,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapControlBtn({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppBlueTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBlueTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Icon(icon, color: AppBlueTheme.accentBlue, size: 22),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gps_off, color: AppBlueTheme.danger, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppBlueTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehiculeData {
  final String trajetId;
  final double lat;
  final double lng;
  final double vitesse;
  final String ligneId;
  final String ligneNumero;
  final String ligneNom;
  final String conducteurNom;
  final String immatriculation;
  final String prochainArret;
  final double tempsRestantMin;
  final double distanceRestantKm;
  final DateTime? lastUpdate;

  const _VehiculeData({
    required this.trajetId,
    required this.lat,
    required this.lng,
    required this.vitesse,
    required this.ligneId,
    required this.ligneNumero,
    required this.ligneNom,
    required this.conducteurNom,
    required this.immatriculation,
    required this.prochainArret,
    required this.tempsRestantMin,
    required this.distanceRestantKm,
    this.lastUpdate,
  });
}
