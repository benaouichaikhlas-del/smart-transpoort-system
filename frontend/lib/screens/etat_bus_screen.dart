import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class EtatBusScreen extends StatefulWidget {
  const EtatBusScreen({super.key});
  @override
  State<EtatBusScreen> createState() => _EtatBusScreenState();
}

class _EtatBusScreenState extends State<EtatBusScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _vehicules = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Socket + Timer
  IO.Socket? _socket;
  Timer? _refreshTimer;
  bool _socketConnected = false;

  // Animation pour pulse
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _load();
    _initSocket();
    // Fallback refresh
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_socket?.connected != true) _load();
      },
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().user!.token;
  int get _userId => context.read<AuthProvider>().user!.id;

  // ══════════════════════════════════════
  // 🔌 SOCKET.IO
  // ══════════════════════════════════════
  void _initSocket() {
    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': _token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('🔌 EtatBusSocket connecté');
      setState(() => _socketConnected = true);

      // ← JOIN ROOM PROPRIÉTAIRE
      _socket!.emit('join_proprietaire', {'proprietaire_id': _userId});
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 EtatBusSocket déconnecté');
      setState(() => _socketConnected = false);
    });

    // 🚨 PANNE DÉCLARÉE PAR CONDUCTEUR
    _socket!.on('panne_declaree', (data) {
      debugPrint('🚨 Panne reçue: $data');
      if (!mounted) return;

      final vehiculeId = data['vehicule_id'];

      setState(() {
        final index = _vehicules.indexWhere((v) => v['id'] == vehiculeId);
        if (index != -1) {
          _vehicules[index]['etat'] = 'en panne';
          _vehicules[index]['panne_info'] = data;
        }
      });

      _showSnack(
        '🚨 ${data['conducteur']?['prenom'] ?? ''} ${data['conducteur']?['nom'] ?? ''} '
        'a déclaré une panne!\n'
        '🚌 ${data['immatriculation'] ?? ''}\n'
        '🔧 ${data['type_panne'] ?? ''}',
        AppTheme.error,
      );
    });

    // ✅ PANNE RÉSOLUE
    _socket!.on('panne_resolue', (data) {
      debugPrint('✅ Panne résolue: $data');
      if (!mounted) return;

      final vehiculeId = data['vehicule_id'];

      setState(() {
        final index = _vehicules.indexWhere((v) => v['id'] == vehiculeId);
        if (index != -1) {
          _vehicules[index]['etat'] = 'actif';
          _vehicules[index].remove('panne_info');
        }
      });

      _showSnack(
        '✅ Véhicule réparé: ${data['immatriculation'] ?? ''}',
        AppTheme.secondary,
      );
    });

    // ⏱️ RETARD DÉCLARÉ
    _socket!.on('retard_declare', (data) {
      debugPrint('⏱️ Retard reçu: $data');
      if (!mounted) return;

      _showSnack(
        '⏱️ Retard déclaré — Ligne ${data['ligne']?['numero'] ?? ''}\n'
        '${data['duree_minutes']} min — ${data['motif']}',
        AppTheme.warning,
      );
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════
  // 📡 LOAD DATA
  // ══════════════════════════════════════
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.vehicules),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        setState(() => _vehicules = b is List ? b : []);
      } else {
        setState(() => _errorMsg = 'Erreur ${r.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Connexion impossible');
    }
    setState(() => _isLoading = false);
  }

  // ══════════════════════════════════════
  // 💬 Details Dialog
  // ══════════════════════════════════════
  Future<void> _showDetailsDialog(Map v) async {
    Map? details;
    bool loading = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loading) {
            http
                .get(
                  Uri.parse('${ApiConstants.vehicules}/${v['id']}/etat'),
                  headers: {'Authorization': 'Bearer $_token'},
                )
                .timeout(const Duration(seconds: 10))
                .then((r) {
                  if (r.statusCode == 200) {
                    setS(() {
                      details = jsonDecode(r.body);
                      loading = false;
                    });
                  } else {
                    setS(() => loading = false);
                  }
                })
                .catchError((_) => setS(() => loading = false));
          }

          final etat = v['etat'] ?? 'actif';
          final etatColor = _etatColor(etat);
          final conducteur = details?['conducteur'];
          final pannes = details?['pannes'] as List? ?? [];
          final position = details?['position'];
          final panneInfo = v['panne_info'];

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: etatColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_etatIcon(etat), color: etatColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Text(v['immatriculation'] ?? '',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: etatColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(etat,
                    style: TextStyle(
                        color: etatColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            content: loading
                ? const SizedBox(
                    height: 80,
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.primary)))
                : SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _detailTile(Icons.event_seat_outlined,
                              '${v['capacite'] ?? '—'} places', Colors.white54),

                          // ← PANNE INFO SI DISPONIBLE
                          if (panneInfo != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: AppTheme.error, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Panne déclarée',
                                        style: TextStyle(
                                            color: AppTheme.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _detailTile(
                                      Icons.build_circle_outlined,
                                      '${panneInfo['type_panne']}',
                                      Colors.white),
                                  const SizedBox(height: 4),
                                  _detailTile(
                                      Icons.person_outline,
                                      'Par: ${panneInfo['conducteur']?['prenom'] ?? ''} ${panneInfo['conducteur']?['nom'] ?? ''}',
                                      Colors.white70),
                                  const SizedBox(height: 4),
                                  _detailTile(
                                      Icons.access_time,
                                      _formatDate(panneInfo['timestamp']),
                                      Colors.white54),
                                ],
                              ),
                            ),
                          ],

                          const Divider(color: Colors.white12, height: 20),

                          // ── Conducteur ──
                          _sectionTitle('Conducteur affecté'),
                          const SizedBox(height: 8),
                          conducteur != null
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            AppTheme.primary.withOpacity(0.2)),
                                  ),
                                  child: Column(children: [
                                    _detailTile(
                                        Icons.person_outline,
                                        '${conducteur['nom']} ${conducteur['prenom']}',
                                        Colors.white),
                                    const SizedBox(height: 6),
                                    _detailTile(
                                        Icons.phone_outlined,
                                        conducteur['telephone'] ?? '—',
                                        Colors.white54),
                                    if (conducteur['ligne_numero'] != null) ...[
                                      const SizedBox(height: 6),
                                      _detailTile(
                                          Icons.route_outlined,
                                          'Ligne ${conducteur['ligne_numero']}${conducteur['ligne_nom'] != null ? ' — ${conducteur['ligne_nom']}' : ''}',
                                          AppTheme.warning),
                                    ],
                                  ]),
                                )
                              : _emptyMsg('Aucun conducteur affecté'),

                          const Divider(color: Colors.white12, height: 20),

                          // ── Position GPS ──
                          _sectionTitle('Position GPS'),
                          const SizedBox(height: 8),
                          position != null
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.secondary
                                            .withOpacity(0.2)),
                                  ),
                                  child: Column(children: [
                                    _detailTile(
                                        Icons.speed_outlined,
                                        '${position['vitesse'] ?? 0} km/h',
                                        AppTheme.secondary),
                                    const SizedBox(height: 6),
                                    _detailTile(
                                        Icons.access_time_outlined,
                                        _formatTime(position['updated_at']),
                                        Colors.white54),
                                  ]),
                                )
                              : _emptyMsg('Véhicule non géolocalisé'),

                          const Divider(color: Colors.white12, height: 20),

                          // ── Pannes ──
                          _sectionTitle('Pannes déclarées'),
                          const SizedBox(height: 8),

                          if (etat == 'en panne')
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: const Row(children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: AppTheme.error, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ce véhicule est en panne. Voir les déclarations ci-dessous.',
                                    style: TextStyle(
                                        color: AppTheme.error, fontSize: 12),
                                  ),
                                ),
                              ]),
                            ),

                          pannes.isNotEmpty
                              ? Column(
                                  children: pannes
                                      .map((p) => Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.error
                                                  .withOpacity(0.06),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: AppTheme.error
                                                      .withOpacity(0.15)),
                                            ),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(children: [
                                                    const Icon(
                                                        Icons
                                                            .build_circle_outlined,
                                                        color: AppTheme.error,
                                                        size: 14),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                          p['description'] ??
                                                              '—',
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      12)),
                                                    ),
                                                  ]),
                                                  const SizedBox(height: 4),
                                                  Row(children: [
                                                    _statusBadge(
                                                        p['statut'] ?? '—'),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                        _formatDate(
                                                            p['created_at']),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white38,
                                                            fontSize: 10)),
                                                    if (p['ligne_numero'] !=
                                                        null) ...[
                                                      const SizedBox(width: 8),
                                                      Text(
                                                          'Ligne ${p['ligne_numero']}',
                                                          style: const TextStyle(
                                                              color: AppTheme
                                                                  .warning,
                                                              fontSize: 10)),
                                                    ],
                                                  ]),
                                                ]),
                                          ))
                                      .toList(),
                                )
                              : _emptyMsg('Aucune panne déclarée'),
                        ]),
                  ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child:
                    const Text('Fermer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════
  // 🏗️ BUILD
  // ══════════════════════════════════════
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
            const Text('État des Véhicules',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('${_vehicules.length} véhicule(s)',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          // ← Socket status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _socketConnected ? AppTheme.secondary : AppTheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_socketConnected
                              ? AppTheme.secondary
                              : AppTheme.error)
                          .withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    if (_errorMsg != null) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 60),
          const SizedBox(height: 16),
          Text(_errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Réessayer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ));
    }
    if (_vehicules.isEmpty) {
      return const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 70, color: Colors.white24),
          SizedBox(height: 16),
          Text('Aucun véhicule enregistré',
              style: TextStyle(color: Colors.white38, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ));
    }

    final actifs = _vehicules.where((v) => v['etat'] == 'actif').length;
    final pannes = _vehicules.where((v) => v['etat'] == 'en panne').length;
    final maintenances =
        _vehicules.where((v) => v['etat'] == 'en maintenance').length;

    return Column(children: [
      // Stats bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppTheme.surface,
        child: Row(children: [
          _statChip(_vehicules.length.toString(), 'Total', Colors.white54),
          const SizedBox(width: 8),
          _statChip(actifs.toString(), 'Actifs', AppTheme.secondary),
          const SizedBox(width: 8),
          _statChip(pannes.toString(), 'En panne', AppTheme.error),
          const SizedBox(width: 8),
          _statChip(maintenances.toString(), 'Maint.', AppTheme.warning),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _vehicules.length,
          itemBuilder: (_, i) {
            final v = _vehicules[i];
            final etat = v['etat'] ?? 'actif';
            final color = _etatColor(etat);
            final hasPanne = v['panne_info'] != null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _showDetailsDialog(v),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                    boxShadow: etat == 'en panne'
                        ? [
                            BoxShadow(
                              color: AppTheme.error.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(children: [
                    // Icon avec pulse si en panne
                    etat == 'en panne'
                        ? AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, child) => Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(
                                  0.12 + (_pulseCtrl.value * 0.1),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  Icon(_etatIcon(etat), color: color, size: 24),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                Icon(_etatIcon(etat), color: color, size: 24),
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(v['immatriculation'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(etat,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.event_seat_outlined,
                                color: Colors.white38, size: 12),
                            const SizedBox(width: 4),
                            Text('${v['capacite'] ?? '—'} places',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                            if (hasPanne) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.warning_amber,
                                  color: AppTheme.error, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${v['panne_info']['type_panne'] ?? 'Panne'}',
                                style: const TextStyle(
                                    color: AppTheme.error, fontSize: 10),
                              ),
                            ],
                          ]),
                        ])),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white24, size: 14),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));

  Widget _detailTile(IconData icon, String text, Color color) => Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13))),
      ]);

  Widget _emptyMsg(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(msg,
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 12,
                fontStyle: FontStyle.italic)),
      );

  Widget _statusBadge(String statut) {
    Color c;
    switch (statut) {
      case 'accepte':
        c = AppTheme.secondary;
        break;
      case 'refuse':
        c = AppTheme.error;
        break;
      default:
        c = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(statut,
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statChip(String count, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Text(count,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
          ]),
        ),
      );

  String _formatTime(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  Color _etatColor(String etat) {
    switch (etat) {
      case 'actif':
        return AppTheme.secondary;
      case 'en panne':
        return AppTheme.error;
      case 'en maintenance':
        return AppTheme.warning;
      default:
        return Colors.white38;
    }
  }

  IconData _etatIcon(String etat) {
    switch (etat) {
      case 'en panne':
        return Icons.build_circle_outlined;
      case 'en maintenance':
        return Icons.settings_outlined;
      default:
        return Icons.directions_bus_rounded;
    }
  }
}
