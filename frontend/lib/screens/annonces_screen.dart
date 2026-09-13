import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  static const Color _amber = Color(0xFFFBBF24);
  static const Color _amber2 = Color(0xFFF59E0B);
  static const Color _card = Color(0xFF131324);
  static const Color _fieldFill = Color(0xFF191931);
  static const Color _fieldBorder = Color(0xFF2E2E52);

  List<dynamic> _annonces = [];
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
        Uri.parse(ApiConstants.annonces),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (r.statusCode == 200 && mounted) {
        setState(() => _annonces = jsonDecode(r.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Dialog Envoyer (style maquette) ──
  Future<void> _showEnvoyerDialog() async {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _fieldBorder, width: 1.2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Titre + fermeture
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_amber, _amber2],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Color(0xFF1A1A2E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Envoyer une annonce',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Titre
                  const _SheetLabel('Titre'),
                  const SizedBox(height: 10),
                  _sheetField(
                    controller: titreCtrl,
                    hint: 'Saisissez le titre',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 20),

                  // Contenu
                  const _SheetLabel("Contenu de l'annonce"),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _fieldBorder),
                    ),
                    child: TextField(
                      controller: contenuCtrl,
                      maxLines: 5,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Écrivez le contenu de votre annonce...',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(
                            Icons.edit_outlined,
                            color: _amber,
                            size: 20,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _amber.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: _amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Information',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Votre annonce sera visible par tous les conducteurs de votre flotte.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: _fieldBorder,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [_amber, _amber2],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _amber.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: loading
                                  ? null
                                  : () async {
                                      if (titreCtrl.text.trim().isEmpty ||
                                          contenuCtrl.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Titre et contenu obligatoires',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      setS(() => loading = true);
                                      final r = await http.post(
                                        Uri.parse(ApiConstants.annonces),
                                        headers: {
                                          'Content-Type': 'application/json',
                                          'Authorization': 'Bearer $_token',
                                        },
                                        body: jsonEncode({
                                          'titre': titreCtrl.text.trim(),
                                          'contenu': contenuCtrl.text.trim(),
                                        }),
                                      );
                                      if (!mounted) return;
                                      setS(() => loading = false);

                                      final body = jsonDecode(r.body);
                                      final message =
                                          body['message']?.toString() ??
                                              'Erreur inconnue';

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: r.statusCode == 201
                                              ? Colors.green
                                              : Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(12),
                                        ),
                                      );
                                      if (r.statusCode == 201) {
                                        Navigator.pop(ctx);
                                        _load();
                                      }
                                    },
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF1A1A2E),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send_rounded,
                                              color: Color(0xFF1A1A2E),
                                              size: 19,
                                            ),
                                            SizedBox(width: 9),
                                            Text(
                                              'Envoyer',
                                              style: TextStyle(
                                                color: Color(0xFF1A1A2E),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _fieldBorder),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(icon, color: _amber, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ── Header moderne ──
  PreferredSizeWidget _modernHeader({
    required String title,
    required String subtitle,
    VoidCallback? onRefresh,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        color: AppTheme.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
            child: Row(
              children: [
                _headerIconBtn(
                  Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _headerIconBtn(
                  Icons.add_rounded,
                  color: _amber,
                  onTap: _showEnvoyerDialog,
                ),
                const SizedBox(width: 6),
                if (onRefresh != null)
                  _headerIconBtn(
                    Icons.refresh_rounded,
                    onTap: onRefresh,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerIconBtn(
    IconData icon, {
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B16),
      appBar: _modernHeader(
        title: 'Annonces',
        subtitle: ' ${_annonces.length} annonce(s)',
        onRefresh: _load,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_annonce_fab',
        onPressed: _showEnvoyerDialog,
        backgroundColor: _amber,
        icon: const Icon(Icons.campaign_rounded, color: Color(0xFF1A1A2E)),
        label: const Text(
          'Ajouter annonce',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _amber),
            )
          : _annonces.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _amber,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _annonces.length,
                    itemBuilder: (_, i) {
                      final a = _annonces[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _amber.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _amber.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: _amber,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    a['titre']?.toString() ?? 'Sans titre',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFFBBF24),
                                    size: 19,
                                  ),
                                  onPressed: () async {
                                    final r = await http.delete(
                                      Uri.parse(
                                        '${ApiConstants.annonces}/${a['id']}',
                                      ),
                                      headers: {
                                        'Authorization': 'Bearer $_token',
                                      },
                                    );
                                    if (!mounted) return;
                                    final body = jsonDecode(r.body);
                                    final message =
                                        body['message']?.toString() ??
                                            'Erreur inconnue';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor: r.statusCode == 200
                                            ? Colors.green
                                            : Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(12),
                                      ),
                                    );
                                    if (r.statusCode == 200) _load();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              a['contenu']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              a['created_at']?.toString().substring(0, 10) ??
                                  '',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // ── État vide style maquette ──
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 150,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _fieldBorder),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 16,
                    left: 20,
                    child: Icon(
                      Icons.cloud_rounded,
                      color: Colors.white.withOpacity(0.08),
                      size: 40,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 24,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Colors.white.withOpacity(0.06),
                      size: 60,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 22,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Colors.white.withOpacity(0.06),
                      size: 48,
                    ),
                  ),
                  const Icon(
                    Icons.campaign_rounded,
                    color: _amber,
                    size: 80,
                  ),
                  const Positioned(
                    top: 14,
                    right: 24,
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white24,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Aucune annonce pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Envoyez votre première annonce\npour informer votre équipe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _showEnvoyerDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_amber, _amber2],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _amber.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFF1A1A2E),
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Envoyer une annonce',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
