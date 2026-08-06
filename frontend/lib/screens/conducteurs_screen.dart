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

  // ══════════════════════════════════════
  // ✅ التحقق من رقم الهاتف الجزائري (10 أرقام)
  // ══════════════════════════════════════
  bool _isValidAlgerianPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s'), '');
    final regex = RegExp(r'^(0[5-7]\d{8})$');
    return regex.hasMatch(clean);
  }

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'\s'), '');

  // ══════════════════════════════════════
  // ✅ InputFormatter للهاتف الجزائري (تنسيق تلقائي)
  // ══════════════════════════════════════
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

  // ══════════════════════════════════════
  // ✅ التحقق من رقم رخصة السياقة الجزائرية
  // ══════════════════════════════════════
  bool _isValidAlgerianPermis(String permis) {
    final clean = permis.trim().toUpperCase().replaceAll(' ', '');
    final regex = RegExp(r'^\d{8}[/-]\d{2}$');
    return regex.hasMatch(clean);
  }

  // ══════════════════════════════════════
  // ➕ AJOUTER
  // ══════════════════════════════════════
  Future<void> _showAjouterDialog() async {
    final token = context.read<AuthProvider>().user!.token;
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final permisCtrl = TextEditingController();
    final adresseCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Ajouter conducteur',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nomCtrl, 'Nom *', Icons.person_outline),
                const SizedBox(height: 10),
                _dialogField(prenomCtrl, 'Prénom *', Icons.person_outline),
                const SizedBox(height: 10),
                _dialogField(
                  ageCtrl,
                  'Âge * (19-70)',
                  Icons.cake_outlined,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // ✅ حقل الهاتف الجزائري — تنسيق تلقائي
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: _phoneFormatters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Téléphone *',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ حقل رخصة السياقة الجزائرية
                TextField(
                  controller: permisCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'N° Permis * (12345678/16)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                _dialogField(
                  adresseCtrl,
                  'Adresse',
                  Icons.location_on_outlined,
                ),
                const Divider(color: Colors.white24, height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Accès à l\'application',
                    style: TextStyle(color: AppTheme.primary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                _dialogField(
                  emailCtrl,
                  'Email (optionnel)',
                  Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Mot de passe temporaire *',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white38,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38,
                      ),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (nomCtrl.text.trim().isEmpty ||
                          prenomCtrl.text.trim().isEmpty ||
                          ageCtrl.text.trim().isEmpty ||
                          telCtrl.text.trim().isEmpty ||
                          permisCtrl.text.trim().isEmpty ||
                          passCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Remplissez les champs obligatoires (*)',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final age = int.tryParse(ageCtrl.text.trim());
                      if (age == null || age < 19 || age > 70) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Âge invalide (19-70)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (!_isValidAlgerianPhone(telCtrl.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Numéro de téléphone invalide\nFormat: 05XXXXXXXX (10 chiffres)',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      if (!_isValidAlgerianPermis(permisCtrl.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'N° permis invalide !\nFormat: 12345678/16 ou 12345678-16\n(8 chiffres + / ou - + 2 chiffres)',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                      if (passCtrl.text.trim().length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mot de passe : min 6 caractères'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setS(() => loading = true);
                      final cleanPhone = _cleanPhone(telCtrl.text.trim());
                      final result = await _service.ajouterConducteur(
                        token: token,
                        nom: nomCtrl.text.trim(),
                        prenom: prenomCtrl.text.trim(),
                        age: age,
                        tel: cleanPhone,
                        numPermis: permisCtrl.text.trim().toUpperCase(),
                        adresse: adresseCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        motDePasse: passCtrl.text.trim(),
                      );
                      setS(() => loading = false);
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success']
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                      if (result['success']) _load();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Ajouter',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // ✏️ MODIFIER
  // ══════════════════════════════════════
  Future<void> _showEditDialog(Map c) async {
    final token = context.read<AuthProvider>().user!.token;
    final nomCtrl = TextEditingController(text: c['nom'] ?? '');
    final prenomCtrl = TextEditingController(text: c['prenom'] ?? '');
    final ageCtrl = TextEditingController(
      text: c['age'] != null ? c['age'].toString() : '',
    );
    final telCtrl = TextEditingController(text: c['telephone'] ?? '');
    final permisCtrl = TextEditingController(text: c['num_permis'] ?? '');
    final adresseCtrl = TextEditingController(text: c['adresse'] ?? '');
    final emailCtrl = TextEditingController(text: c['email'] ?? '');
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppTheme.warning),
              SizedBox(width: 8),
              Text(
                'Modifier conducteur',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nomCtrl, 'Nom *', Icons.person_outline),
                const SizedBox(height: 10),
                _dialogField(prenomCtrl, 'Prénom *', Icons.person_outline),
                const SizedBox(height: 10),
                _dialogField(
                  ageCtrl,
                  'Âge (19-70)',
                  Icons.cake_outlined,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // ✅ حقل الهاتف الجزائري — تعديل
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: _phoneFormatters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Téléphone *',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ حقل رخصة السياقة الجزائرية — تعديل
                TextField(
                  controller: permisCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'N° Permis * (12345678/16)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                _dialogField(
                  adresseCtrl,
                  'Adresse',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                _dialogField(
                  emailCtrl,
                  'Email (optionnel)',
                  Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (nomCtrl.text.trim().isEmpty ||
                          prenomCtrl.text.trim().isEmpty ||
                          telCtrl.text.trim().isEmpty ||
                          permisCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Remplissez les champs obligatoires (*)',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (ageCtrl.text.trim().isNotEmpty) {
                        final age = int.tryParse(ageCtrl.text.trim());
                        if (age == null || age < 19 || age > 70) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Âge invalide (19-70)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }
                      if (!_isValidAlgerianPhone(telCtrl.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Numéro de téléphone invalide\nFormat: 05XXXXXXXX (10 chiffres)',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      if (!_isValidAlgerianPermis(permisCtrl.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'N° permis invalide !\nFormat: 12345678/16 ou 12345678-16\n(8 chiffres + / ou - + 2 chiffres)',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                      setS(() => loading = true);
                      final cleanPhone = _cleanPhone(telCtrl.text.trim());
                      final result = await _service.modifierConducteur(
                        token: token,
                        id: c['id'],
                        nom: nomCtrl.text.trim(),
                        prenom: prenomCtrl.text.trim(),
                        age: int.tryParse(ageCtrl.text.trim()),
                        tel: cleanPhone,
                        numPermis: permisCtrl.text.trim().toUpperCase(),
                        adresse: adresseCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                      );
                      setS(() => loading = false);
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success']
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                      if (result['success']) _load();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Modifier',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 🗑️ SUPPRIMER
  // ══════════════════════════════════════
  Future<void> _supprimer(int id, String nom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer', style: TextStyle(color: Colors.white)),
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
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
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );
    if (result['success']) _load();
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
            const Text(
              'Mes Conducteurs',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '${_conducteurs.length} conducteur(s)',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
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
        heroTag: 'add_conducteur',
        onPressed: _showAjouterDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _conducteurs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 70, color: Colors.white24),
                      SizedBox(height: 16),
                      Text(
                        'Aucun conducteur',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conducteurs.length,
                  itemBuilder: (_, i) {
                    final c = _conducteurs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c['prenom'] ?? ''} ${c['nom']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (c['age'] != null)
                                  Text(
                                    '${c['age']} ans',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (c['telephone'] != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 12,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        c['telephone'],
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (c['num_permis'] != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.badge_outlined,
                                        size: 12,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Permis: ${c['num_permis']}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (c['email'] != null &&
                                    c['email'].toString().isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 12,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        c['email'],
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.orange,
                            ),
                            onPressed: () => _showEditDialog(c),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _supprimer(c['id'], c['nom']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _dialogField(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}