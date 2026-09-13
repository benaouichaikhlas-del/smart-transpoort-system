import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/conducteur_service.dart';

class ConducteursScreen extends StatefulWidget {
  const ConducteursScreen({super.key});

  @override
  State<ConducteursScreen> createState() => _ConducteursScreenState();
}

class _ConducteursScreenState extends State<ConducteursScreen> {
  final _service = ConducteurService();
  List<dynamic> _conducteurs = [];
  bool _isLoading = true;

  static const Color _bg = Color(0xFF0B0B16);
  static const Color _card = Color(0xFF131324);
  static const Color _greenPrimary = Color(0xFF10B981);
  static const Color _greenDark = Color(0xFF047857);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().user!.token;
    final data = await _service.getConducteurs(token);
    setState(() {
      _conducteurs = data;
      _isLoading = false;
    });
  }

  Future<void> showAjouterDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConducteurFormPage(
          service: _service,
          token: context.read<AuthProvider>().user!.token,
          onSaved: _load,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> showEditDialog(Map c) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConducteurFormPage(
          conducteur: c,
          service: _service,
          token: context.read<AuthProvider>().user!.token,
          onSaved: _load,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> supprimer(int id, String nom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2A48)),
        ),
        title: const Text(
          'Supprimer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Supprimer le conducteur "$nom" ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = context.read<AuthProvider>().user!.token;
    final result = await _service.supprimerConducteur(token, id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor:
            result['success'] ? _greenPrimary : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
    if (result['success']) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C38),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Conducteurs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_conducteurs.length} conducteur(s)',
              style: const TextStyle(
                color: _greenPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: _greenPrimary, size: 20),
              onPressed: _load,
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_greenPrimary, _greenDark],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _greenPrimary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'add_conducteur',
          onPressed: showAjouterDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            'Ajouter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _greenPrimary),
      );
    }
    if (_conducteurs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 70,
              color: _greenPrimary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text('Aucun conducteur',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur + pour en ajouter',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _conducteurs.length,
      itemBuilder: (_, i) {
        final c = _conducteurs[i];
        final nomComplet = '${c['prenom'] ?? ''} ${c['nom']}'.trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _greenPrimary.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _greenPrimary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header Card ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _greenPrimary.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    bottom: BorderSide(
                      color: _greenPrimary.withOpacity(0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_greenPrimary, _greenDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _greenPrimary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomComplet,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (c['telephone'] != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _greenPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _greenPrimary.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                c['telephone'],
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _actionBtn(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFFF59E0B),
                          onTap: () => showEditDialog(c),
                        ),
                        const SizedBox(width: 8),
                        _actionBtn(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFEF4444),
                          onTap: () => supprimer(c['id'], c['nom']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Details ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (c['age'] != null) ...[
                          _infoChip(
                            Icons.cake_outlined,
                            '${c['age']} ans',
                            const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (c['num_permis'] != null)
                          _infoChip(
                            Icons.badge_outlined,
                            'Permis: ${c['num_permis']}',
                            const Color(0xFF94A3B8),
                          ),
                      ],
                    ),
                    if (c['email'] != null &&
                        c['email'].toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _infoChip(
                            Icons.email_outlined,
                            c['email'],
                            const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _greenPrimary, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════
// PAGE FORMULAIRE CONDUCTEUR — Dark Green
// ══════════════════════════════════════════════════════

class ConducteurFormPage extends StatefulWidget {
  final Map? conducteur;
  final ConducteurService service;
  final String token;
  final VoidCallback onSaved;

  const ConducteurFormPage({
    super.key,
    this.conducteur,
    required this.service,
    required this.token,
    required this.onSaved,
  });

  @override
  State<ConducteurFormPage> createState() => _ConducteurFormPageState();
}

class _ConducteurFormPageState extends State<ConducteurFormPage> {
  static const Color _bg = Color(0xFF0B0B16);
  static const Color _card = Color(0xFF131324);
  static const Color _fieldFill = Color(0xFF191931);
  static const Color _fieldBorder = Color(0xFF2A2A48);
  static const Color _greenPrimary = Color(0xFF10B981);
  static const Color _greenDark = Color(0xFF047857);
  static const Color _textSecondary = Color(0xFF94A3B8);

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _permisCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.conducteur;
    _nomCtrl.text = c?['nom'] ?? '';
    _prenomCtrl.text = c?['prenom'] ?? '';
    _ageCtrl.text = c?['age'] != null ? c!['age'].toString() : '';
    _telCtrl.text = c?['telephone'] ?? '';
    _permisCtrl.text = c?['num_permis'] ?? '';
    _adresseCtrl.text = c?['adresse'] ?? '';
    _emailCtrl.text = c?['email'] ?? '';
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _ageCtrl.dispose();
    _telCtrl.dispose();
    _permisCtrl.dispose();
    _adresseCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.conducteur != null;

  bool _isValidAlgerianPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s'), '');
    final regex = RegExp(r'^(0[1-3]\d{8})$');
    return regex.hasMatch(clean);
  }

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'\s'), '');

  List<TextInputFormatter> get _phoneFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) return newValue;
          if (newValue.text.length == 1 && newValue.text != '0') {
            return oldValue;
          }
          if (newValue.text.length == 2) {
            final prefix = newValue.text;
            if (!['05', '06', '07'].contains(prefix)) {
              return oldValue;
            }
          }
          if (newValue.text.length > 10) return oldValue;
          return newValue;
        }),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          if (text.isEmpty) return newValue;
          final buffer = StringBuffer();
          for (int i = 0; i < text.length; i++) {
            if (i == 2 || i == 4 || i == 6 || i == 8) {
              buffer.write(' ');
            }
            buffer.write(text[i]);
          }
          final formatted = buffer.toString();
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ];

  bool _isValidAlgerianPermis(String permis) {
    final clean = permis.trim().toUpperCase().replaceAll(' ', '');
    final regex = RegExp(r'^\d{8}[/-]\d{2}$');
    return regex.hasMatch(clean);
  }

  void _showError(String msg, {int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty ||
        _prenomCtrl.text.trim().isEmpty ||
        _ageCtrl.text.trim().isEmpty ||
        _telCtrl.text.trim().isEmpty ||
        _permisCtrl.text.trim().isEmpty ||
        (!_isEdit && _passCtrl.text.trim().isEmpty)) {
      _showError('Remplissez les champs obligatoires (*)');
      return;
    }
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 19 || age > 70) {
      _showError('Âge invalide (19-70)');
      return;
    }
    if (!_isValidAlgerianPhone(_telCtrl.text.trim())) {
      _showError(
          'Numéro de téléphone invalide\nFormat: 05XXXXXXXX (10 chiffres)');
      return;
    }
    if (!_isValidAlgerianPermis(_permisCtrl.text.trim())) {
      _showError(
          'N° permis invalide !\nFormat: 12345678/16 ou 12345678-16\n(8 chiffres + / ou - + 2 chiffres)',
          seconds: 4);
      return;
    }
    if (!_isEdit && _passCtrl.text.trim().length < 6) {
      _showError('Mot de passe : min 6 caractères');
      return;
    }

    setState(() => _loading = true);

    Map<String, dynamic> result;
    if (_isEdit) {
      result = await widget.service.modifierConducteur(
        token: widget.token,
        id: widget.conducteur!['id'],
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        age: age,
        tel: _cleanPhone(_telCtrl.text.trim()),
        numPermis: _permisCtrl.text.trim().toUpperCase(),
        adresse: _adresseCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
    } else {
      result = await widget.service.ajouterConducteur(
        token: widget.token,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        age: age,
        tel: _cleanPhone(_telCtrl.text.trim()),
        numPermis: _permisCtrl.text.trim().toUpperCase(),
        adresse: _adresseCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        motDePasse: _passCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor:
            result['success'] ? _greenPrimary : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );

    if (result['success']) {
      widget.onSaved();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _greenPrimary.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ En-tête ═══
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_greenPrimary, _greenDark],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: _greenPrimary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
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
                            _isEdit
                                ? 'Modifier conducteur'
                                : 'Ajouter conducteur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isEdit
                                ? 'Modifiez les informations du conducteur'
                                : 'Remplissez les informations du conducteur',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ═══ Champs conducteur ═══
                _buildField(
                  controller: _nomCtrl,
                  label: 'Nom *',
                  hint: 'Entrez le nom',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _prenomCtrl,
                  label: 'Prénom *',
                  hint: 'Entrez le prénom',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _ageCtrl,
                  label: 'Âge * (19-70)',
                  hint: "Entrez l'âge",
                  icon: Icons.cake_outlined,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _telCtrl,
                  label: 'Téléphone *',
                  hint: 'Numéro de téléphone',
                  icon: Icons.phone_outlined,
                  type: TextInputType.number,
                  inputFormatters: _phoneFormatters,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _permisCtrl,
                  label: 'N° Permis *',
                  hint: '1234567890',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _adresseCtrl,
                  label: 'Adresse',
                  hint: "Entrez l'adresse",
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 26),

                // ═══ Section Accès à l'application ═══
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _greenPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: _greenPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Accès à l'application",
                      style: TextStyle(
                        color: _greenPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Divider(color: _fieldBorder, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                _buildField(
                  controller: _emailCtrl,
                  label: 'Email (optionnel)',
                  hint: 'exemple@email.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _passCtrl,
                  label: 'Mot de passe temporaire',
                  hint: 'Minimum 6 caractères',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  enabled: !_isEdit,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),

                const SizedBox(height: 28),

                // ═══ Boutons ═══
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: _fieldBorder, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: _textSecondary,
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
                            colors: [_greenPrimary, _greenDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _greenPrimary.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _loading ? null : _submit,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isEdit ? 'Modifier' : 'Ajouter',
                                            style: const TextStyle(
                                              color: Colors.white,
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
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fieldBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        enabled: enabled,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _greenPrimary, size: 22),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF5A5A78), fontSize: 14),
          labelText: label,
          labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
      ),
    );
  }
}
