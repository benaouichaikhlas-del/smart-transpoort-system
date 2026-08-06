import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════
class _DS {
  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131F);
  static const Color surface2 = Color(0xFF1A1A2E);
  static const Color card = Color(0xFF16162A);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primary2 = Color(0xFFEC4899);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF6B7280);
  static const Color border = Color(0xFF2A2A3C);
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;
  final double radius;
  const _Card(
      {required this.child, this.borderColor, this.padding, this.radius = 16});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor ?? _DS.border, width: 1),
        ),
        child: child,
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
      );
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final List<Color> colors;
  final double height;
  const _GradientBtn(
      {required this.label,
      required this.icon,
      this.onTap,
      this.loading = false,
      this.colors = const [_DS.primary, _DS.primary2],
      this.height = 54});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
                color: colors.first.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                          ]),
              ),
            )),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(title,
            style: const TextStyle(
                color: _DS.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      );
}

class _CircularPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  const _CircularPicker(
      {required this.value,
      required this.onChanged,
      this.min = 5,
      this.max = 120,
      this.step = 5});
  @override
  Widget build(BuildContext context) => _Card(
        borderColor: _DS.warning.withOpacity(0.25),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(children: [
          SizedBox(
              height: 160,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(
                    size: const Size(200, 160),
                    painter: _ArcPainter(
                        progress: (value - min) / (max - min),
                        activeColor: _DS.warning,
                        bgColor: _DS.border)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$value',
                      style: const TextStyle(
                          color: _DS.textMain,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  const SizedBox(height: 4),
                  const Text('minutes',
                      style: TextStyle(
                          color: _DS.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ]),
              ])),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _RoundBtn(
                icon: Icons.remove,
                onTap: value > min ? () => onChanged(value - step) : null,
                color: _DS.primary),
            const SizedBox(width: 40),
            _RoundBtn(
                icon: Icons.add,
                onTap: value < max ? () => onChanged(value + step) : null,
                color: _DS.primary2),
          ]),
          const SizedBox(height: 8),
          Text('Duree estimee du retard',
              style:
                  TextStyle(color: _DS.textDim.withOpacity(0.8), fontSize: 12)),
        ]),
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _RoundBtn({required this.icon, this.onTap, required this.color});
  @override
  Widget build(BuildContext context) => Material(
        color: color.withOpacity(0.15),
        shape: const CircleBorder(),
        child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4))),
              child: Icon(icon, color: color, size: 24),
            )),
      );
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color bgColor;
  _ArcPainter(
      {required this.progress,
      required this.activeColor,
      required this.bgColor});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const startAngle = math.pi * 0.8;
    const sweepAngle = math.pi * 1.4;
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, bgPaint);
    final activePaint = Paint()
      ..shader =
          LinearGradient(colors: [activeColor, activeColor.withOpacity(0.6)])
              .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle * progress, false, activePaint);
    final tickPaint = Paint()
      ..color = bgColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i <= 24; i++) {
      final angle = startAngle + (sweepAngle / 24) * i;
      final p1 = center +
          Offset(
              math.cos(angle) * (radius - 14), math.sin(angle) * (radius - 14));
      final p2 = center +
          Offset(
              math.cos(angle) * (radius - 6), math.sin(angle) * (radius - 6));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
//  CONDUCTEUR HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class ConducteurHomeScreen extends StatefulWidget {
  const ConducteurHomeScreen({super.key});
  @override
  State<ConducteurHomeScreen> createState() => _ConducteurHomeScreenState();
}

class _ConducteurHomeScreenState extends State<ConducteurHomeScreen> {
  int _selectedIndex = 0;
  int? _ligneId;
  final GlobalKey<_PannePageState> _pannePageKey = GlobalKey<_PannePageState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.premierConnexion) _showChangerMotDePasse();
    });
  }

  String get _token => context.read<AuthProvider>().user?.token ?? '';

  void _showChangerMotDePasse() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF151B2B),
              title: const Text('Changer le mot de passe',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              content: const Text(
                  'Veuillez changer votre mot de passe pour des raisons de securite.',
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Plus tard',
                        style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FACFE)),
                    child: const Text('Changer',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: IndexedStack(index: _selectedIndex, children: [
        _AccueilPage(
            token: _token,
            onLigneLoaded: (id) {
              if (_ligneId != id) setState(() => _ligneId = id);
            }),
        _RetardPage(token: _token, ligneId: _ligneId),
        _PannePage(key: _pannePageKey, token: _token, ligneId: _ligneId),
        _ProfilPage(token: _token),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: const Color(0xFF0F1729),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildNavItem(Icons.home_outlined, 'Accueil', 0),
            _buildNavItem(Icons.access_time, 'Retard', 1),
            _buildNavItem(Icons.build_outlined, 'Panne', 2),
            _buildNavItem(Icons.person_outline, 'Profil', 3),
          ]),
        )),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 2) _pannePageKey.currentState?._chargerPannesEnCours();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4FACFE).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: isSelected ? const Color(0xFF4FACFE) : Colors.white38,
              size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: isSelected ? const Color(0xFF4FACFE) : Colors.white38,
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ACCUEIL
// ═══════════════════════════════════════════════════════════════
class _AccueilPage extends StatefulWidget {
  final String token;
  final void Function(int?) onLigneLoaded;
  const _AccueilPage({required this.token, required this.onLigneLoaded});
  @override
  State<_AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<_AccueilPage> {
  bool _gpsActif = false;
  Timer? _gpsTimer;
  String? _trajetId;
  String _gpsStatut = 'GPS desactive';
  IO.Socket? _socket;
  Map<String, dynamic> _reservationsData = {};
  bool _loadingReservations = true;
  Map<String, dynamic> _espacesData = {};
  List<dynamic> _permanences = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    _initSocket();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _socket?.disconnect();
    if (_gpsActif) _desactiverGPS();
    super.dispose();
  }

  void _initSocket() {
    _socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setAuth({'token': widget.token})
            .build());
    _socket!.connect();
    _socket!.onConnect((_) {
      debugPrint('Socket connecte: ${_socket!.id}');
      final userId = _extractUserIdFromToken(widget.token);
      if (userId != null)
        _socket!.emit('join_passager', {'passager_id': userId});
    });
    _socket!.onConnectError((err) => debugPrint('Connexion error: $err'));
    _socket!.onDisconnect((_) => debugPrint('Socket deconnecte'));
    _socket!.on('notification', (data) => _showNotification(data));
    _socket!.on('retard_signale', (data) => _showRetardNotification(data));
    _socket!.on('panne_signalee', (data) => _showPanneNotification(data));
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload['id']?.toString() ?? payload['userId']?.toString();
    } catch (e) {
      return null;
    }
  }

  void _showNotification(dynamic data) {
    if (!mounted) return;
    final String titre = data['titre'] ?? 'Notification';
    final String message = data['message'] ?? '';
    final String type = data['type'] ?? 'info';
    Color color = const Color(0xFF4FACFE);
    IconData icon = Icons.notifications;
    switch (type) {
      case 'retard':
        color = const Color(0xFFFFAB00);
        icon = Icons.access_time;
        break;
      case 'panne':
        color = const Color(0xFFFF5252);
        icon = Icons.build;
        break;
      case 'info':
        color = const Color(0xFF00C853);
        icon = Icons.check_circle;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(titre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]))
      ]),
      backgroundColor: color,
      duration: const Duration(seconds: 6),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showRetardNotification(dynamic data) => _showNotification({
        'titre': 'Retard — Ligne ${data['ligne_numero'] ?? ''}',
        'message':
            'Bus ligne ${data['ligne_numero'] ?? ''} en retard. Motif: ${data['motif'] ?? ''}',
        'type': 'retard'
      });
  void _showPanneNotification(dynamic data) => _showNotification({
        'titre': 'Panne — Ligne ${data['ligne_id'] ?? ''}',
        'message': '${data['type_panne'] ?? ''} — ${data['description'] ?? ''}',
        'type': 'panne'
      });

  Future<void> _chargerDonnees() async {
    await Future.wait(
        [_chargerReservations(), _chargerEspaces(), _chargerPermanences()]);
  }

  Future<void> _chargerReservations() async {
    try {
      final r = await http.get(
          Uri.parse('${ApiConstants.conducteurActions}/reservations-ligne'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (r.statusCode == 200 && mounted)
        setState(() {
          _reservationsData = jsonDecode(r.body);
          _loadingReservations = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingReservations = false);
    }
  }

  Future<void> _chargerEspaces() async {
    try {
      final r = await http.get(
          Uri.parse('${ApiConstants.conducteurActions}/espaces'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        setState(() => _espacesData = data);
        widget.onLigneLoaded(data['ligne_id'] as int?);
      }
    } catch (_) {}
  }

  Future<void> _chargerPermanences() async {
    try {
      final r = await http.get(
          Uri.parse('${ApiConstants.conducteurActions}/permanences'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (r.statusCode == 200 && mounted)
        setState(() => _permanences = jsonDecode(r.body));
    } catch (_) {}
  }

  Future<bool> _demarrerTrajet() async {
    try {
      final r = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/trajets/demarrer'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}'
          });
      if (r.statusCode == 201) {
        final data = jsonDecode(r.body);
        setState(() => _trajetId = data['trajet_id']?.toString());
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _terminerTrajet() async {
    if (_trajetId == null) return;
    try {
      await http.put(
          Uri.parse('${ApiConstants.baseUrl}/trajets/$_trajetId/terminer'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
    } catch (_) {}
    if (mounted) setState(() => _trajetId = null);
  }

  Future<void> _toggleGPS() async {
    if (_gpsActif) {
      await _desactiverGPS();
      return;
    }
    if (_espacesData.isEmpty || _espacesData['ligne_id'] == null) {
      await _chargerEspaces();
      if (_espacesData['ligne_id'] == null) return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    final ok = await _demarrerTrajet();
    if (!ok) return;
    if (!mounted) return;
    setState(() {
      _gpsActif = true;
      _gpsStatut = 'GPS active';
    });
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _envoyerPosition();
    });
    await _envoyerPosition();
  }

  Future<void> _envoyerPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _gpsStatut = 'GPS actif');
      final payload = {
        'trajet_id': _trajetId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'vitesse': pos.speed
      };
      final r = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/trajets/position'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}'
          },
          body: jsonEncode(payload));
      if (r.statusCode == 200 && _socket?.connected == true)
        _socket!.emit('update_position',
            {...payload, 'timestamp': DateTime.now().toIso8601String()});
    } catch (_) {
      if (mounted) setState(() => _gpsStatut = 'Signal faible');
    }
  }

  Future<void> _desactiverGPS() async {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    if (_trajetId != null) await _terminerTrajet();
    if (mounted)
      setState(() {
        _gpsActif = false;
        _gpsStatut = 'GPS desactive';
      });
  }

  Future<void> _showAjusterEspaces() async {
    final total = _espacesData['places_total'] as int? ?? 0;
    final current = _espacesData['places_dispo'] as int? ?? 0;
    int nouvelleValeur = current;
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setS) => AlertDialog(
                  backgroundColor: const Color(0xFF151B2B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Row(children: [
                    Icon(Icons.event_seat, color: Color(0xFF00E676)),
                    SizedBox(width: 8),
                    Text('Ajuster places disponibles',
                        style: TextStyle(color: Colors.white, fontSize: 16))
                  ]),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Capacite totale: $total places',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                          onPressed: () {
                            if (nouvelleValeur > 0)
                              setS(() => nouvelleValeur--);
                          },
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFFFF5252), size: 32)),
                      Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF0A0E1A),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('$nouvelleValeur',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: () {
                            if (nouvelleValeur < total)
                              setS(() => nouvelleValeur++);
                          },
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF00E676), size: 32)),
                    ]),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler',
                            style: TextStyle(color: Colors.white54))),
                    ElevatedButton(
                        onPressed: () async {
                          if (nouvelleValeur == current) {
                            Navigator.pop(ctx);
                            return;
                          }
                          Navigator.pop(ctx);
                          final r = await http.post(
                              Uri.parse(
                                  '${ApiConstants.conducteurActions}/espaces'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer ${widget.token}'
                              },
                              body:
                                  jsonEncode({'places_dispo': nouvelleValeur}));
                          if (!mounted) return;
                          _showSnack(
                              jsonDecode(r.body)['message'] ?? 'Mis a jour',
                              r.statusCode == 200
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFFFF5252));
                          if (r.statusCode == 200) _chargerEspaces();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Confirmer',
                            style: TextStyle(color: Colors.white))),
                  ],
                )));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12)));
  }

  DateTime get _today => DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
  DateTime? _extractDate(dynamic res) {
    if (res == null) return null;
    final dateStr = res['date_reservation'] ?? res['date'] ?? res['created_at'];
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  List<dynamic> get _reservationsForSelectedDate {
    final all = (_reservationsData['reservations'] as List?) ?? [];
    final trajetActif = _reservationsData['trajet'];
    final trajetId = trajetActif?['id'];
    if (_dateMode == 'today') {
      final byDate = all.where((res) {
        final date = _extractDate(res);
        if (date == null) return false;
        return _dateOnly(date).isAtSameMomentAs(_today);
      }).toList();
      if (byDate.isNotEmpty) return byDate;
      if (trajetId != null)
        return all.where((res) => res['trajet_id'] == trajetId).toList();
      return [];
    }
    return all.where((res) {
      final date = _extractDate(res);
      if (date == null) return false;
      return _dateOnly(date).isAtSameMomentAs(_dateOnly(_selectedDate));
    }).toList();
  }

  List<dynamic> get _archivedReservations {
    final all = (_reservationsData['reservations'] as List?) ?? [];
    return all.where((res) {
      final date = _extractDate(res);
      if (date == null) return false;
      return _dateOnly(date).isBefore(_today);
    }).toList();
  }

  List<dynamic> get _futureReservations {
    final all = (_reservationsData['reservations'] as List?) ?? [];
    return all.where((res) {
      final date = _extractDate(res);
      if (date == null) return false;
      return _dateOnly(date).isAfter(_today);
    }).toList();
  }

  List<DateTime> get _archiveDates {
    final dates = <DateTime>{};
    for (final res in _archivedReservations) {
      final date = _extractDate(res);
      if (date != null) dates.add(_dateOnly(date));
    }
    return dates.toList()..sort((a, b) => b.compareTo(a));
  }

  List<DateTime> get _futureDates {
    final dates = <DateTime>{};
    for (final res in _futureReservations) {
      final date = _extractDate(res);
      if (date != null) dates.add(_dateOnly(date));
    }
    return dates.toList()..sort((a, b) => a.compareTo(b));
  }

  String get _dateMode {
    final selected = _dateOnly(_selectedDate);
    final today = _today;
    if (selected.isAtSameMomentAs(today)) return 'today';
    if (selected.isAfter(today)) return 'future';
    return 'past';
  }

  void _openArchive() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _ArchivePage(
                token: widget.token,
                reservationsData: _reservationsData,
                archiveDates: _archiveDates)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF4FACFE),
                      surface: Color(0xFF151B2B),
                      onSurface: Colors.white),
                  dialogBackgroundColor: const Color(0xFF0A0E1A)),
              child: child!,
            ));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _goToToday() => setState(() => _selectedDate = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ligne = _reservationsData['ligne'];
    final reservations = _reservationsForSelectedDate;
    final totalPlaces = _reservationsData['total_places'] as int? ?? 0;
    final placesReservees = reservations.fold<int>(
        0, (sum, r) => sum + ((r['nb_places'] as int?) ?? 0));
    final placesDispo = (totalPlaces - placesReservees).clamp(0, totalPlaces);
    final mode = _dateMode;
    final isToday = mode == 'today';
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A237E),
                            Color(0xFF0D47A1),
                            Color(0xFF00695C)
                          ]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF4FACFE).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ]),
                  child: Row(children: [
                    Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.directions_bus,
                            color: Colors.white, size: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              ligne != null
                                  ? 'Ligne ${ligne['numero']}'
                                  : 'Aucune ligne',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              ligne != null
                                  ? '${ligne['nom'] ?? ''}'
                                  : 'Non affecte',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: _gpsActif
                                        ? const Color(0xFF00E676)
                                        : Colors.white38,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(_gpsStatut,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12))
                          ]),
                        ])),
                    GestureDetector(
                        onTap: _toggleGPS,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: _gpsActif
                                        ? const Color(0xFF00E676)
                                        : Colors.white24)),
                            child: Row(children: [
                              Icon(_gpsActif ? Icons.gps_fixed : Icons.gps_off,
                                  color: _gpsActif
                                      ? const Color(0xFF00E676)
                                      : Colors.white70,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text(_gpsActif ? 'GPS ON' : 'GPS OFF',
                                  style: TextStyle(
                                      color: _gpsActif
                                          ? const Color(0xFF00E676)
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold))
                            ]))),
                  ])),
              const SizedBox(height: 20),
              if (ligne != null) ...[
                Row(children: [
                  _buildStatCard(
                      icon: Icons.airline_seat_recline_normal,
                      value: '$totalPlaces',
                      label: 'Total\nplaces',
                      color: const Color(0xFF4FACFE)),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      icon: Icons.confirmation_number,
                      value: '$placesReservees',
                      label: 'Reservees',
                      color: const Color(0xFFFFAB00)),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      icon: Icons.event_seat,
                      value: '$placesDispo',
                      label: 'Disponibles',
                      color: const Color(0xFF00E676)),
                ]),
                const SizedBox(height: 16),
                GestureDetector(
                    onTap: _showAjusterEspaces,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF151B2B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    const Color(0xFF00E676).withOpacity(0.3))),
                        child: Row(children: [
                          Icon(Icons.tune,
                              color: const Color(0xFF00E676).withOpacity(0.8),
                              size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                              child: Text('Ajuster les espaces vides',
                                  style: TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600))),
                          Icon(Icons.arrow_forward_ios,
                              color: const Color(0xFF00E676).withOpacity(0.5),
                              size: 16)
                        ]))),
                const SizedBox(height: 20),
              ],
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF151B2B),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.06))),
                  child: Column(children: [
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.calendar_today,
                              color: Color(0xFF00E676), size: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: GestureDetector(
                              onTap: _pickDate,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Aujourd'hui",
                                        style: TextStyle(
                                            color: Color(0xFF00E676),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                    Text(_getJourSemaine(_selectedDate),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13)),
                                  ]))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFAB00).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFFFAB00)
                                      .withOpacity(0.3))),
                          child: Column(children: [
                            Row(children: [
                              const Icon(Icons.add_box_outlined,
                                  color: Color(0xFFFFAB00), size: 18),
                              const SizedBox(width: 4),
                              Text('${reservations.length}',
                                  style: const TextStyle(
                                      color: Color(0xFFFFAB00),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))
                            ]),
                            const SizedBox(height: 2),
                            const Text('Reservations',
                                style: TextStyle(
                                    color: Color(0xFFFFAB00), fontSize: 11))
                          ])),
                      const SizedBox(width: 12),
                      GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00E676).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.edit_calendar,
                                  color: Color(0xFF00E676), size: 22))),
                    ]),
                  ])),
              const SizedBox(height: 24),
              Row(children: [
                const Icon(Icons.people, color: Color(0xFF4FACFE), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Passagers reserves',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold))),
                GestureDetector(
                    onTap: _chargerDonnees,
                    child: const Icon(Icons.refresh,
                        color: Colors.white38, size: 20))
              ]),
              const SizedBox(height: 14),
              _loadingReservations
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: Color(0xFF4FACFE))))
                  : reservations.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: const Color(0xFF151B2B),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(
                                    Icons.confirmation_number_outlined,
                                    color: Colors.white38,
                                    size: 28)),
                            const SizedBox(width: 16),
                            const Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text("Aucune reservation active aujourd'hui",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                  SizedBox(height: 4),
                                  Text('Les reservations apparaitront ici',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12))
                                ])),
                          ]))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reservations.length,
                          itemBuilder: (_, i) {
                            final res = reservations[i];
                            String? timeStr;
                            final heureDepart = res['heure_depart'];
                            if (heureDepart != null)
                              timeStr = heureDepart.toString().substring(0, 5);
                            return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF151B2B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFF4FACFE)
                                            .withOpacity(0.2))),
                                child: Row(children: [
                                  Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF4FACFE)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: const Icon(Icons.person,
                                          color: Color(0xFF4FACFE), size: 22)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            res['passager_email'] ?? 'Passager',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('${res['nb_places']} place(s)',
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12)),
                                        if (timeStr != null)
                                          Text('Depart: $timeStr',
                                              style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 11)),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: isToday
                                              ? const Color(0xFF00E676)
                                                  .withOpacity(0.15)
                                              : const Color(0xFFFFAB00)
                                                  .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(
                                          isToday ? 'ACTIF' : 'CONFIRME',
                                          style: TextStyle(
                                              color: isToday
                                                  ? const Color(0xFF00E676)
                                                  : const Color(0xFFFFAB00),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                ]));
                          }),
              const SizedBox(height: 28),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFAB00).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.calendar_today,
                        color: Color(0xFFFFAB00), size: 18)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Tableau des permanences',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold))),
                GestureDetector(
                    onTap: () {},
                    child: Row(children: [
                      Text('Voir tout',
                          style: TextStyle(
                              color: const Color(0xFF4FACFE).withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          color: const Color(0xFF4FACFE).withOpacity(0.7),
                          size: 14)
                    ])),
              ]),
              const SizedBox(height: 14),
              _permanences.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: const Color(0xFF151B2B),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Center(
                          child: Text('Aucune permanence planifiee',
                              style: TextStyle(color: Colors.white38))))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _permanences.length > 3 ? 3 : _permanences.length,
                      itemBuilder: (_, i) {
                        final p = _permanences[i];
                        final repos = p['repos'] == true;
                        String? dateFormatted;
                        final dateRaw = p['date'];
                        if (dateRaw != null) {
                          try {
                            final d = DateTime.parse(dateRaw.toString());
                            dateFormatted =
                                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          } catch (_) {}
                        }
                        return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                                color: const Color(0xFF151B2B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: repos
                                        ? Colors.white12
                                        : const Color(0xFFFFAB00)
                                            .withOpacity(0.25))),
                            child: Row(children: [
                              Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: repos
                                          ? Colors.white24
                                          : const Color(0xFFFFAB00),
                                      borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(p['jour'] ?? '',
                                        style: TextStyle(
                                            color: repos
                                                ? Colors.white38
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    if (dateFormatted != null)
                                      Text(dateFormatted,
                                          style: TextStyle(
                                              color: repos
                                                  ? Colors.white24
                                                  : const Color(0xFFFFAB00)
                                                      .withOpacity(0.8),
                                              fontSize: 13)),
                                  ])),
                              if (!repos) ...[
                                const Icon(Icons.access_time,
                                    color: Color(0xFFFFAB00), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                    '${p['heure_debut'] ?? '--:--'} → ${p['heure_fin'] ?? '--:--'}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500))
                              ] else
                                const Text('Repos',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 14)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white.withOpacity(0.2),
                                  size: 16),
                            ]));
                      }),
              const SizedBox(height: 20),
            ])));
  }

  Widget _buildStatCard(
          {required IconData icon,
          required String value,
          required String label,
          required Color color}) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
            color: const Color(0xFF151B2B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12, height: 1.3)),
        ]),
      ));

  String _getJourSemaine(DateTime d) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return jours[d.weekday - 1];
  }
}

// ═══════════════════════════════════════════════════════════════
//  ARCHIVE
// ═══════════════════════════════════════════════════════════════
class _ArchivePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> reservationsData;
  final List<DateTime> archiveDates;
  const _ArchivePage(
      {required this.token,
      required this.reservationsData,
      required this.archiveDates});
  @override
  State<_ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<_ArchivePage> {
  DateTime? _selectedArchiveDate;
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime? _extractDate(dynamic res) {
    final dateStr = res['date_reservation'] ?? res['date'] ?? res['created_at'];
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return null;
    }
  }

  List<dynamic> get _reservationsForDate {
    if (_selectedArchiveDate == null) return [];
    final all = (widget.reservationsData['reservations'] as List?) ?? [];
    return all.where((res) {
      final date = _extractDate(res);
      if (date == null) return false;
      return _dateOnly(date).isAtSameMomentAs(_dateOnly(_selectedArchiveDate!));
    }).toList();
  }

  String _formatDate(DateTime d) {
    final months = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aout',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _formatDayName(DateTime d) {
    final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return days[d.weekday % 7];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
            backgroundColor: const Color(0xFF0F1729),
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            title: const Row(children: [
              Icon(Icons.archive_outlined, color: Color(0xFFFFAB00), size: 22),
              SizedBox(width: 10),
              Text('Archives des reservations',
                  style: TextStyle(color: Colors.white, fontSize: 16))
            ])),
        body: SafeArea(
            child: Column(children: [
          Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.archiveDates.length,
                  itemBuilder: (_, i) {
                    final date = widget.archiveDates[i];
                    final isSelected = _selectedArchiveDate != null &&
                        _dateOnly(_selectedArchiveDate!)
                            .isAtSameMomentAs(_dateOnly(date));
                    return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedArchiveDate = date),
                        child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFAB00).withOpacity(0.2)
                                    : const Color(0xFF151B2B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFAB00)
                                        : Colors.white12,
                                    width: isSelected ? 2 : 1)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_formatDayName(date),
                                      style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFFFFAB00)
                                              : Colors.white54,
                                          fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('${date.day}',
                                      style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFFFFAB00)
                                              : Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${date.month.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFFFFAB00)
                                                  .withOpacity(0.7)
                                              : Colors.white38,
                                          fontSize: 10)),
                                ])));
                  })),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
              child: _selectedArchiveDate == null
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.calendar_month,
                              color: Colors.white24, size: 48),
                          const SizedBox(height: 16),
                          const Text('Selectionnez une date',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14))
                        ]))
                  : _reservationsForDate.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              Icon(Icons.inbox_outlined,
                                  color: Colors.white24, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                  'Aucune reservation le ${_formatDate(_selectedArchiveDate!)}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 14))
                            ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reservationsForDate.length,
                          itemBuilder: (_, i) {
                            final res = _reservationsForDate[i];
                            String? timeStr;
                            final heureDepart = res['heure_depart'];
                            if (heureDepart != null)
                              timeStr = heureDepart.toString().substring(0, 5);
                            return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF151B2B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFFFAB00)
                                            .withOpacity(0.2))),
                                child: Row(children: [
                                  Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFFAB00)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: const Icon(Icons.person_outline,
                                          color: Color(0xFFFFAB00), size: 24)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            res['passager_email'] ?? 'Passager',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.event_seat,
                                              color: Colors.white38, size: 12),
                                          const SizedBox(width: 4),
                                          Text('${res['nb_places']} place(s)',
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12)),
                                          if (timeStr != null) ...[
                                            const SizedBox(width: 12),
                                            const Icon(Icons.access_time,
                                                color: Colors.white38,
                                                size: 12),
                                            const SizedBox(width: 4),
                                            Text(timeStr,
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12))
                                          ]
                                        ]),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFFAB00)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Text('ARCHIVE',
                                          style: TextStyle(
                                              color: Color(0xFFFFAB00),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                ]));
                          })),
        ])),
      );
}

// ═══════════════════════════════════════════════════════════════
//  RETARD
// ═══════════════════════════════════════════════════════════════
class _RetardPage extends StatefulWidget {
  final String token;
  final int? ligneId;
  const _RetardPage({required this.token, this.ligneId});
  @override
  State<_RetardPage> createState() => _RetardPageState();
}

class _RetardPageState extends State<_RetardPage> {
  int _duree = 15;
  String? _motif;
  bool _loading = false;
  bool _enviando = false;
  Map<String, dynamic>? _retardEnCours;
  bool _chargementRetard = false;

  final List<String> _motifs = [
    'Embouteillage',
    'Incident de route',
    'Probleme technique',
    'Conditions meteo',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _chargerRetardEnCours();
  }

  Future<void> _chargerRetardEnCours() async {
    setState(() => _chargementRetard = true);
    try {
      final res = await http.get(
          Uri.parse('${ApiConstants.conducteurActions}/retard-en-cours'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _retardEnCours = data['retard']);
      }
    } catch (e) {
      debugPrint('Erreur retard en cours: $e');
    } finally {
      if (mounted) setState(() => _chargementRetard = false);
    }
  }

  Future<void> _resoudreRetard(int retardId) async {
    setState(() => _enviando = true);
    try {
      final res = await http.post(
          Uri.parse(
              '${ApiConstants.conducteurActions}/retard/$retardId/resoudre'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        _showSnack('Retard resolu !', _DS.success);
        await _chargerRetardEnCours();
      } else {
        final data = jsonDecode(res.body);
        _showSnack(data['message'] ?? 'Erreur', _DS.error);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Erreur reseau', _DS.error);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _envoyer() async {
    if (_loading || _enviando) return;
    if (_motif == null) {
      _showSnack('Selectionnez un motif', Colors.orange);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await http.post(
          Uri.parse('${ApiConstants.conducteurActions}/retard'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}'
          },
          body: jsonEncode({
            'duree_minutes': _duree,
            'motif': _motif,
            if (widget.ligneId != null) 'ligne_id': widget.ligneId
          }));
      if (!mounted) return;
      final data = jsonDecode(r.body);
      _showSnack(data['message'] ?? 'Erreur',
          r.statusCode == 201 ? _DS.success : _DS.error);
      if (r.statusCode == 201) {
        setState(() {
          _duree = 15;
          _motif = null;
        });
        await _chargerRetardEnCours();
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Connexion perdue, veuillez reessayer', _DS.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: _DS.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.access_time_rounded,
                                color: _DS.warning, size: 24)),
                        const SizedBox(width: 14),
                        const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Declarer un retard',
                                  style: TextStyle(
                                      color: _DS.textMain,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text(
                                  'Le retard sera enregistre et les passagers notifies automatiquement.',
                                  style: TextStyle(
                                      color: _DS.textMuted,
                                      fontSize: 12,
                                      height: 1.4)),
                            ])),
                      ]),
                      if (widget.ligneId != null) ...[
                        const SizedBox(height: 20),
                        _Card(
                            borderColor: _DS.warning.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: _DS.warning.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.route_rounded,
                                      color: _DS.warning, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Ligne #${widget.ligneId}',
                                        style: const TextStyle(
                                            color: _DS.warning,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    const Text('Les passagers seront notifies',
                                        style: TextStyle(
                                            color: _DS.textMuted,
                                            fontSize: 12)),
                                  ])),
                            ])),
                      ],
                      const SizedBox(height: 24),
                      if (_retardEnCours != null) ...[
                        _Card(
                            borderColor: _DS.warning.withOpacity(0.35),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color:
                                                _DS.warning.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Icon(
                                            Icons.access_time_filled,
                                            color: _DS.warning,
                                            size: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              'Retard de ${_retardEnCours!['duree_minutes']} minutes',
                                              style: const TextStyle(
                                                  color: _DS.textMain,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text('${_retardEnCours!['motif']}',
                                              style: const TextStyle(
                                                  color: _DS.textMuted,
                                                  fontSize: 13)),
                                        ])),
                                    const _Badge(
                                        label: 'EN COURS', color: _DS.warning),
                                  ]),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed: _enviando
                                            ? null
                                            : () => _resoudreRetard(
                                                _retardEnCours!['id']),
                                        icon: const Icon(Icons.check,
                                            size: 18, color: Colors.white),
                                        label: const Text('Resoudre',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: _DS.success,
                                            disabledBackgroundColor:
                                                _DS.success.withOpacity(0.3),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                      )),
                                ])),
                        const SizedBox(height: 24),
                      ],
                      const _SectionTitle('Duree du retard'),
                      _CircularPicker(
                          value: _duree,
                          onChanged: (v) => setState(() => _duree = v)),
                      const SizedBox(height: 24),
                      const _SectionTitle('Motif du retard'),
                      _Card(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                            value: _motif,
                            hint: const Text('Selectionnez le motif',
                                style: TextStyle(color: _DS.textDim)),
                            isExpanded: true,
                            dropdownColor: _DS.surface2,
                            style: const TextStyle(
                                color: _DS.textMain, fontSize: 14),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: _DS.textDim),
                            items: _motifs
                                .map((m) =>
                                    DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                            onChanged: (v) => setState(() => _motif = v),
                          ))),
                      const SizedBox(height: 32),
                      _GradientBtn(
                          label: 'Envoyer la declaration',
                          icon: Icons.send_rounded,
                          onTap: _loading ? null : _envoyer,
                          loading: _loading),
                      const SizedBox(height: 24),
                    ]))),
      );
}

// ═══════════════════════════════════════════════════════════════
//  PANNE
// ═══════════════════════════════════════════════════════════════
class _PannePage extends StatefulWidget {
  final String token;
  final int? ligneId;
  const _PannePage({super.key, required this.token, this.ligneId});
  @override
  State<_PannePage> createState() => _PannePageState();
}

class _PannePageState extends State<_PannePage>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _affectation;
  List<dynamic> _pannesEnCours = [];
  bool _enviando = false;
  bool _chargementPannes = false;
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  String? _typePanne;
  final _descriptionCtrl = TextEditingController();
  final List<String> _typesPanne = [
    'Panne moteur',
    'Panne electrique',
    'Panne pneu',
    'Accident',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _chargerAffectation();
    _chargerPannesEnCours();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chargerPannesEnCours();
  }

  @override
  void didUpdateWidget(covariant _PannePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _chargerPannesEnCours();
  }

  Future<void> _chargerAffectation() async {
    try {
      final res = await http.get(
          Uri.parse('${ApiConstants.conducteurActions}/reservations-ligne'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _affectation = data['ligne']);
      }
    } catch (e) {
      debugPrint('Erreur affectation: $e');
    }
  }

  Future<void> _chargerPannesEnCours() async {
    setState(() => _chargementPannes = true);
    try {
      final res = await http.get(
          Uri.parse('${ApiConstants.conducteurActions}/pannes-en-cours'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _pannesEnCours = data['pannes'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur pannes: $e');
    } finally {
      if (mounted) setState(() => _chargementPannes = false);
    }
  }

  Future<void> _envoyer() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) return;
    if (_typePanne == null) {
      _showSnack('Veuillez choisir un type de panne');
      return;
    }
    setState(() => _enviando = true);
    try {
      final body = {
        'type_panne': _typePanne,
        'description': _descriptionCtrl.text.trim(),
        if (_affectation?['id'] != null) 'ligne_id': _affectation!['id']
      };
      final res = await http.post(
          Uri.parse('${ApiConstants.conducteurActions}/panne'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));
      if (!mounted) return;
      if (res.statusCode == 201) {
        _showSnack('Panne declaree !');
        _descriptionCtrl.clear();
        setState(() => _typePanne = null);
        _formKey.currentState?.reset();
        await _chargerPannesEnCours();
      } else {
        final data = jsonDecode(res.body);
        _showSnack(data['message'] ?? 'Erreur serveur');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur reseau');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _resoudrePanne(int panneId) async {
    setState(() => _enviando = true);
    try {
      final res = await http.post(
          Uri.parse(
              '${ApiConstants.conducteurActions}/panne/$panneId/resoudre'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        _showSnack('Panne resolue !');
        await _chargerPannesEnCours();
      } else {
        final data = jsonDecode(res.body);
        _showSnack(data['message'] ?? 'Erreur serveur');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur reseau');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _demanderAssistance(int panneId) {
    _showSnack("Demande d'assistance envoyee !");
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _DS.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon,
          {String? hint}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _DS.textMuted, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: _DS.textDim, fontSize: 13),
        prefixIcon: Icon(icon, color: _DS.textDim, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _DS.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _DS.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _DS.primary, width: 1.5)),
        filled: true,
        fillColor: _DS.bg,
        counterStyle: const TextStyle(color: _DS.textDim, fontSize: 11),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _chargerPannesEnCours,
              color: _DS.error,
              backgroundColor: _DS.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: _DS.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.build_rounded,
                                color: _DS.primary, size: 24)),
                        const SizedBox(width: 14),
                        const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Declarer une panne',
                                  style: TextStyle(
                                      color: _DS.textMain,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text(
                                  'Signalez une panne technique de votre vehicule.',
                                  style: TextStyle(
                                      color: _DS.textMuted,
                                      fontSize: 12,
                                      height: 1.4)),
                            ])),
                      ]),
                      const SizedBox(height: 24),
                      _Card(
                          borderColor: _DS.error.withOpacity(0.2),
                          child: Form(
                              key: _formKey,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Nouvelle panne',
                                        style: TextStyle(
                                            color: _DS.textMain,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 20),
                                    DropdownButtonFormField<String>(
                                      value: _typePanne,
                                      decoration: _inputDecoration(
                                          'Type de panne',
                                          Icons.warning_amber_rounded),
                                      dropdownColor: _DS.surface2,
                                      style: const TextStyle(
                                          color: _DS.textMain, fontSize: 14),
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: _DS.textDim),
                                      items: _typesPanne
                                          .map((t) => DropdownMenuItem(
                                              value: t, child: Text(t)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _typePanne = v),
                                      validator: (v) =>
                                          v == null ? 'Champ requis' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                        controller: _descriptionCtrl,
                                        maxLines: 4,
                                        maxLength: 250,
                                        style: const TextStyle(
                                            color: _DS.textMain, fontSize: 14),
                                        decoration: _inputDecoration(
                                            'Description',
                                            Icons.description_outlined,
                                            hint:
                                                'Decrivez le probleme rencontre...'),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Champ requis'
                                                : null),
                                    const SizedBox(height: 20),
                                    _GradientBtn(
                                        label: 'Declarer la panne',
                                        icon: Icons.warning_amber_rounded,
                                        onTap: _enviando ? null : _envoyer,
                                        loading: _enviando,
                                        colors: const [
                                          _DS.error,
                                          Color(0xFFDC2626)
                                        ]),
                                  ]))),
                      const SizedBox(height: 32),
                      Row(children: [
                        const Expanded(child: Divider(color: _DS.border)),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(children: [
                              const Icon(Icons.build,
                                  color: _DS.textDim, size: 14),
                              const SizedBox(width: 6),
                              Text('Pannes en cours (${_pannesEnCours.length})',
                                  style: TextStyle(
                                      color: _DS.textDim,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))
                            ])),
                        const Expanded(child: Divider(color: _DS.border)),
                      ]),
                      const SizedBox(height: 16),
                      if (_chargementPannes)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                    color: _DS.error)))
                      else if (_pannesEnCours.isEmpty)
                        Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                                color: _DS.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _DS.border)),
                            child: const Center(
                                child: Column(children: [
                              Icon(Icons.check_circle_outline,
                                  size: 48, color: _DS.success),
                              SizedBox(height: 12),
                              Text('Aucune panne en cours',
                                  style: TextStyle(
                                      color: _DS.textMuted, fontSize: 14)),
                            ])))
                      else
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pannesEnCours.length,
                            itemBuilder: (context, index) =>
                                _buildPanneCard(_pannesEnCours[index])),
                      const SizedBox(height: 24),
                    ]),
              ))),
    );
  }

  Widget _buildPanneCard(dynamic panne) {
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(panne['created_at'].toString());
    } catch (_) {
      createdAt = DateTime.now();
    }
    final String dateStr =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} a ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _DS.error.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _DS.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.build, color: _DS.error, size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(panne['type_panne'] ?? 'Panne',
                      style: const TextStyle(
                          color: _DS.textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Declaree le $dateStr',
                      style:
                          const TextStyle(color: _DS.textMuted, fontSize: 12)),
                ])),
            const _Badge(label: 'EN COURS', color: _DS.warning),
          ]),
          const SizedBox(height: 12),
          if (panne['description'] != null &&
              panne['description'].toString().isNotEmpty)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _DS.bg, borderRadius: BorderRadius.circular(10)),
                child: Text(panne['description'],
                    style:
                        const TextStyle(color: _DS.textMuted, fontSize: 13))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: ElevatedButton.icon(
              onPressed: _enviando ? null : () => _resoudrePanne(panne['id']),
              icon:
                  const Icon(Icons.check_circle, size: 18, color: Colors.white),
              label: const Text('Resoudre',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.success,
                  disabledBackgroundColor: _DS.success.withOpacity(0.3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: ElevatedButton.icon(
              onPressed: () => _demanderAssistance(panne['id']),
              icon: const Icon(Icons.support_agent,
                  size: 18, color: Colors.white),
              label: const Text('Assistance',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
          ]),
        ]));
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROFIL
// ═══════════════════════════════════════════════════════════════
class _ProfilPage extends StatefulWidget {
  final String token;
  const _ProfilPage({required this.token});
  @override
  State<_ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<_ProfilPage> {
  Map<String, dynamic> _profil = {};
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    if (mounted)
      setState(() {
        _loading = true;
        _errorMsg = null;
      });
    try {
      final r = await http.get(
          Uri.parse('${ApiConstants.conducteurs}/mon-profil'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() {
          _profil = jsonDecode(r.body);
          _loading = false;
        });
      } else {
        String msg = 'Erreur ${r.statusCode}';
        try {
          msg = jsonDecode(r.body)['message'] ?? msg;
        } catch (_) {}
        setState(() {
          _loading = false;
          _errorMsg = msg;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _errorMsg = 'Connexion impossible';
        });
    }
  }

  Future<void> _showModifierDialog() async {
    final nomCtrl = TextEditingController(text: _profil['nom'] ?? '');
    final prenomCtrl = TextEditingController(text: _profil['prenom'] ?? '');
    final ageCtrl =
        TextEditingController(text: _profil['age']?.toString() ?? '');
    final telCtrl = TextEditingController(text: _profil['telephone'] ?? '');
    final adresseCtrl = TextEditingController(text: _profil['adresse'] ?? '');
    bool loading = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _DS.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.edit, color: _DS.primary),
            SizedBox(width: 10),
            Text('Modifier le profil',
                style: TextStyle(color: _DS.textMain, fontSize: 16))
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (errorText != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _DS.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _DS.error.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: _DS.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(errorText!,
                          style:
                              const TextStyle(color: _DS.error, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              _profilField(nomCtrl, 'Nom', Icons.person_outline),
              const SizedBox(height: 10),
              _profilField(prenomCtrl, 'Prenom', Icons.person_outline),
              const SizedBox(height: 10),
              _profilField(ageCtrl, 'Age', Icons.cake_outlined,
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _profilField(telCtrl, 'Telephone', Icons.phone_outlined,
                  type: TextInputType.phone),
              const SizedBox(height: 10),
              _profilField(adresseCtrl, 'Adresse', Icons.location_on_outlined),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Annuler', style: TextStyle(color: _DS.textMuted)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (nomCtrl.text.trim().isEmpty ||
                          prenomCtrl.text.trim().isEmpty) {
                        setS(() =>
                            errorText = 'Le nom et prénom sont obligatoires');
                        return;
                      }

                      setS(() {
                        loading = true;
                        errorText = null;
                      });

                      try {
                        final Map<String, dynamic> body = {
                          'nom': nomCtrl.text.trim(),
                          'prenom': prenomCtrl.text.trim(),
                          'telephone': telCtrl.text.trim(),
                          'adresse': adresseCtrl.text.trim(),
                        };

                        final ageValue = int.tryParse(ageCtrl.text.trim());
                        if (ageValue != null) {
                          body['age'] = ageValue;
                        }

                        final r = await http.put(
                          Uri.parse('${ApiConstants.conducteurs}/mon-compte'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}'
                          },
                          body: jsonEncode(body),
                        );

                        debugPrint('STATUS: ${r.statusCode}');
                        debugPrint('BODY: ${r.body}');

                        if (!mounted) return;

                        String message;
                        bool success = r.statusCode == 200;

                        if (success) {
                          message = 'Profil modifie avec succes !';
                        } else {
                          try {
                            message = jsonDecode(r.body)['message'] ??
                                'Erreur ${r.statusCode}';
                          } catch (_) {
                            message = 'Erreur serveur (${r.statusCode})';
                          }
                        }

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message,
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: success ? _DS.success : _DS.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );

                        if (success) _chargerProfil();
                      } catch (e) {
                        debugPrint('Erreur modification: $e');
                        setS(() {
                          loading = false;
                          errorText =
                              'Erreur reseau. Verifiez votre connexion.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Modifier',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangerMotDePasseDialog() async {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureAncien = true;
    bool obscureNouveau = true;
    bool obscureConfirm = true;
    bool loading = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _DS.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.lock_outline, color: _DS.warning),
            SizedBox(width: 10),
            Text('Changer le mot de passe',
                style: TextStyle(color: _DS.textMain, fontSize: 16))
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (errorText != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _DS.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _DS.error.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: _DS.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(errorText!,
                          style:
                              const TextStyle(color: _DS.error, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              _passwordField(ancienCtrl, 'Ancien mot de passe', obscureAncien,
                  () => setS(() => obscureAncien = !obscureAncien)),
              const SizedBox(height: 10),
              _passwordField(
                  nouveauCtrl,
                  'Nouveau mot de passe',
                  obscureNouveau,
                  () => setS(() => obscureNouveau = !obscureNouveau)),
              const SizedBox(height: 10),
              _passwordField(
                  confirmCtrl,
                  'Confirmer le mot de passe',
                  obscureConfirm,
                  () => setS(() => obscureConfirm = !obscureConfirm)),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Annuler', style: TextStyle(color: _DS.textMuted)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final ancien = ancienCtrl.text.trim();
                      final nouveau = nouveauCtrl.text.trim();
                      final confirm = confirmCtrl.text.trim();

                      if (ancien.isEmpty ||
                          nouveau.isEmpty ||
                          confirm.isEmpty) {
                        setS(() =>
                            errorText = 'Tous les champs sont obligatoires');
                        return;
                      }
                      if (nouveau.length < 6) {
                        setS(() => errorText =
                            'Le mot de passe doit contenir au moins 6 caracteres');
                        return;
                      }
                      if (nouveau != confirm) {
                        setS(() => errorText =
                            'Les nouveaux mots de passe ne correspondent pas');
                        return;
                      }

                      setS(() {
                        loading = true;
                        errorText = null;
                      });

                      try {
                        final r = await http.post(
                          Uri.parse(
                              '${ApiConstants.conducteurs}/changer-mot-de-passe'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}'
                          },
                          body: jsonEncode({
                            'ancien_mot_de_passe': ancien,
                            'nouveau_mot_de_passe': nouveau,
                          }),
                        );

                        debugPrint('STATUS MDP: ${r.statusCode}');
                        debugPrint('BODY MDP: ${r.body}');

                        if (!mounted) return;

                        String message;
                        bool success = r.statusCode == 200;

                        if (success) {
                          message = 'Mot de passe modifie avec succes !';
                        } else {
                          try {
                            message = jsonDecode(r.body)['message'] ??
                                'Erreur ${r.statusCode}';
                          } catch (_) {
                            message = 'Erreur serveur (${r.statusCode})';
                          }
                        }

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message,
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: success ? _DS.success : _DS.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Erreur changement MDP: $e');
                        setS(() {
                          loading = false;
                          errorText =
                              'Erreur reseau. Verifiez votre connexion.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.warning,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Modifier',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String hint, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: _DS.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _DS.textDim),
        prefixIcon: const Icon(Icons.lock_outline, color: _DS.textDim),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: _DS.textDim),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: _DS.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _supprimerCompte() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: _DS.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Supprimer le compte ?',
                  style: TextStyle(color: _DS.textMain)),
              content: const Text('Cette action est irreversible.',
                  style: TextStyle(color: _DS.textMuted)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler',
                        style: TextStyle(color: _DS.textMuted))),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: _DS.error),
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
    if (confirmed != true) return;
    final r = await http.delete(
        Uri.parse('${ApiConstants.conducteurs}/mon-compte'),
        headers: {'Authorization': 'Bearer ${widget.token}'});
    if (!mounted) return;
    if (r.statusCode == 200) {
      await context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(jsonDecode(r.body)['message'] ?? 'Erreur'),
          backgroundColor: _DS.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _DS.primary))
              : _errorMsg != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: _DS.error, size: 48),
                                const SizedBox(height: 16),
                                Text(_errorMsg!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: _DS.textMuted, fontSize: 14)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                    onPressed: _chargerProfil,
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    label: const Text('Reessayer',
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _DS.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                              ])))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 40),
                              const Text('Profil',
                                  style: TextStyle(
                                      color: _DS.textMain,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 40),
                            ]),
                        const SizedBox(height: 20),
                        Stack(alignment: Alignment.bottomRight, children: [
                          Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                      colors: [_DS.primary, _DS.primary2]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _DS.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 2)
                                  ]),
                              child: const Center(
                                  child: Icon(Icons.person,
                                      size: 50, color: Colors.white))),
                          Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: _DS.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _DS.bg, width: 3)),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14)),
                        ]),
                        const SizedBox(height: 16),
                        Text(
                            '${_profil['prenom'] ?? ''} ${_profil['nom'] ?? ''}',
                            style: const TextStyle(
                                color: _DS.textMain,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                                color: _DS.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _DS.primary.withOpacity(0.3))),
                            child: const Text('CONDUCTEUR',
                                style: TextStyle(
                                    color: _DS.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8))),
                        const SizedBox(height: 32),
                        _Card(
                            child: Column(children: [
                          _infoTile(Icons.phone_outlined, 'Telephone',
                              _profil['telephone'] ?? 'Non renseigne'),
                          const Divider(color: _DS.border, height: 1),
                          _infoTile(Icons.email_outlined, 'Email',
                              _profil['email'] ?? 'Non renseigne'),
                          const Divider(color: _DS.border, height: 1),
                          _infoTile(
                              Icons.badge_outlined,
                              'ID Conducteur',
                              _profil['num_permis'] ??
                                  _profil['id_conducteur'] ??
                                  'N/A'),
                          const Divider(color: _DS.border, height: 1),
                          _infoTile(
                              Icons.calendar_today_outlined,
                              'Membre depuis',
                              _profil['created_at'] != null
                                  ? '${DateTime.parse(_profil['created_at']).day.toString().padLeft(2, '0')}/${DateTime.parse(_profil['created_at']).month.toString().padLeft(2, '0')}/${DateTime.parse(_profil['created_at']).year}'
                                  : 'N/A'),
                        ])),
                        const SizedBox(height: 24),
                        _actionTile(
                            icon: Icons.edit_outlined,
                            label: 'Modifier le profil',
                            color: _DS.primary,
                            onTap: _showModifierDialog),
                        const SizedBox(height: 10),
                        _actionTile(
                            icon: Icons.lock_outline,
                            label: 'Changer le mot de passe',
                            color: _DS.warning,
                            onTap: _showChangerMotDePasseDialog),
                        const SizedBox(height: 10),
                        _actionTile(
                            icon: Icons.delete_outline,
                            label: 'Supprimer le compte',
                            color: _DS.error,
                            onTap: _supprimerCompte),
                        const SizedBox(height: 32),
                        SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await context.read<AuthProvider>().logout();
                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const WelcomeScreen()),
                                    (_) => false);
                              },
                              icon:
                                  const Icon(Icons.logout, color: Colors.white),
                              label: const Text('Deconnexion',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _DS.error.withOpacity(0.85),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                            )),
                        const SizedBox(height: 24),
                      ])),
        ),
      );

  Widget _infoTile(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(children: [
          Icon(icon, color: _DS.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: _DS.textDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _DS.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      );

  Widget _actionTile(
          {required IconData icon,
          required String label,
          required Color color,
          required VoidCallback onTap}) =>
      Material(
        color: _DS.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.15))),
              child: Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: _DS.textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w600))),
                const Icon(Icons.arrow_forward_ios,
                    color: _DS.textDim, size: 14),
              ]),
            )),
      );

  Widget _profilField(TextEditingController c, String hint, IconData icon,
          {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: c,
        keyboardType: type,
        style: const TextStyle(color: _DS.textMain),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _DS.textDim),
            prefixIcon: Icon(icon, color: _DS.textDim),
            filled: true,
            fillColor: _DS.bg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none)),
      );
}
