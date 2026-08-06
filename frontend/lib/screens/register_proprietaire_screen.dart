import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../models/demande_model.dart';
import '../services/proprietaire_service.dart';
import '../widgets/email_verification_dialog.dart';
import 'attente_screen.dart';

// ══════════════════════════════════════════════════
// COULEURS NÉON — PROPRIÉTAIRE (Violet/Rose)
// ══════════════════════════════════════════════════
const _bg = Color(0xFF0A0612);
const _surface = Color(0xFF13091F);
const _neonPurple = Color.fromARGB(255, 115, 68, 224); // Violet néon
const _neonPink = Color(0xFFEC4899); // Rose néon
const _white = Colors.white;
const _white60 = Color(0x99FFFFFF);
const _white30 = Color(0x4DFFFFFF);

class RegisterProprietaireScreen extends StatefulWidget {
  const RegisterProprietaireScreen({super.key});

  @override
  State<RegisterProprietaireScreen> createState() =>
      _RegisterProprietaireScreenState();
}

class _RegisterProprietaireScreenState
    extends State<RegisterProprietaireScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();

  final _fnPrenom = FocusNode();
  final _fnNom = FocusNode();
  final _fnAge = FocusNode();
  final _fnEmail = FocusNode();
  final _fnTel = FocusNode();
  final _fnAdresse = FocusNode();
  final _fnPass = FocusNode();
  final _fnConfirm = FocusNode();
  final _fnNumero = FocusNode();

  final Set<String> _touched = {};

  bool _obscure = true;
  bool _isLoading = false;
  bool _emailVerifie = false;
  final _service = ProprietaireService();

  @override
  void initState() {
    super.initState();
    _addTouchListener(_fnPrenom, 'prenom');
    _addTouchListener(_fnNom, 'nom');
    _addTouchListener(_fnAge, 'age');
    _addTouchListener(_fnEmail, 'email');
    _addTouchListener(_fnTel, 'tel');
    _addTouchListener(_fnAdresse, 'adresse');
    _addTouchListener(_fnPass, 'pass');
    _addTouchListener(_fnConfirm, 'confirm');
    _addTouchListener(_fnNumero, 'numero');
  }

  void _addTouchListener(FocusNode fn, String key) {
    fn.addListener(() {
      if (!fn.hasFocus && !_touched.contains(key)) {
        setState(() => _touched.add(key));
        _formKey.currentState?.validate();
      }
    });
  }

  AutovalidateMode _mode(String key) => _touched.contains(key)
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  @override
  void dispose() {
    for (final c in [
      _nomCtrl,
      _prenomCtrl,
      _ageCtrl,
      _emailCtrl,
      _telCtrl,
      _adresseCtrl,
      _passCtrl,
      _confirmCtrl,
      _numeroCtrl,
    ]) c.dispose();
    for (final fn in [
      _fnNom,
      _fnPrenom,
      _fnAge,
      _fnEmail,
      _fnTel,
      _fnAdresse,
      _fnPass,
      _fnConfirm,
      _fnNumero,
    ]) fn.dispose();
    super.dispose();
  }

  void _resetForm() {
    for (final c in [
      _nomCtrl,
      _prenomCtrl,
      _ageCtrl,
      _emailCtrl,
      _telCtrl,
      _adresseCtrl,
      _passCtrl,
      _confirmCtrl,
      _numeroCtrl,
    ]) c.clear();
    _touched.clear();
    _emailVerifie = false;
    _formKey.currentState?.reset();
  }

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'\s'), '');

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _verifierEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Veuillez entrer un email valide', Colors.orange);
      return;
    }
    final verifie = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmailVerificationDialog(email: email),
    );
    if (verifie == true) {
      setState(() => _emailVerifie = true);
      _showSnack('✅ Email vérifié !', Colors.green);
    }
  }

  Future<void> _submit() async {
    if (!_emailVerifie) {
      _showSnack('Veuillez vérifier votre email avant de vous inscrire',
          Colors.orange);
      return;
    }
    setState(() => _touched.addAll([
          'prenom',
          'nom',
          'age',
          'email',
          'tel',
          'adresse',
          'pass',
          'confirm',
          'numero'
        ]));
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _service.demanderInscription(
      DemandeModel(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        email: _emailCtrl.text.trim(),
        tel: _cleanPhone(_telCtrl.text.trim()),
        adresse: _adresseCtrl.text.trim(),
        motDePasse: _passCtrl.text.trim(),
        numeroProprietaire: _numeroCtrl.text.trim().toUpperCase(),
      ),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success']) {
      _resetForm();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttenteScreen()),
      );
    } else {
      _showSnack(result['message'], AppTheme.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ═══════════════════════════════════════════════
          // 1) خلفية الصورة + تدرج بنفسجي
          // ═══════════════════════════════════════════════
          Image.asset(
            'assets/images/pro.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0F2E),
                    Color(0xFF2D1B4E),
                    Color(0xFF4A1C40),
                    Color(0xFF0D0D0D),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════
          // 2) تدرج داكن قوي
          // ═══════════════════════════════════════════════
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.75),
                  _bg.withOpacity(0.95),
                ],
                stops: const [0.0, 0.35, 0.65, 0.92],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════
          // 3) المحتوى
          // ═══════════════════════════════════════════════
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back button ──
                    _GlassButton(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: _white, size: 18),
                    ),
                    const SizedBox(height: 20),

                    // ── Icône néon violet ──
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 100, 54, 206).withOpacity(0.1),
                          border: Border.all(
                            color: const Color.fromARGB(255, 100, 54, 206).withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 100, 54, 206).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_outlined,
                          color: const Color.fromARGB(255, 100, 54, 206),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Titre ──
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Inscription ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _white,
                              ),
                            ),
                            TextSpan(
                              text: 'Propriétaire',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [_neonPurple, _neonPink],
                                  ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 40)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Votre demande sera examinée\npar un administrateur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _white60,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════
                    // 4) بطاقة النموذج الزجاجية
                    // ═══════════════════════════════════════════════
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // ── Prénom / Nom ──
                              Row(
                                children: [
                                  Expanded(
                                    child: _neonField(
                                      ctrl: _prenomCtrl,
                                      fn: _fnPrenom,
                                      label: 'Prénom',
                                      icon: Icons.person_outline,
                                      touchKey: 'prenom',
                                      iconColor: _neonPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _neonField(
                                      ctrl: _nomCtrl,
                                      fn: _fnNom,
                                      label: 'Nom',
                                      icon: Icons.person_outline,
                                      touchKey: 'nom',
                                      iconColor: _neonPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Âge ──
                              _neonField(
                                ctrl: _ageCtrl,
                                fn: _fnAge,
                                label: 'Âge',
                                icon: Icons.calendar_today_outlined,
                                touchKey: 'age',
                                iconColor: _neonPurple,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Champ obligatoire';
                                  final n = int.tryParse(v);
                                  if (n == null || n < 18 || n > 99)
                                    return 'Âge invalide (18-99)';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── Email + Vérifier ──
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _neonField(
                                      ctrl: _emailCtrl,
                                      fn: _fnEmail,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      touchKey: 'email',
                                      iconColor: _neonPurple,
                                      keyboardType: TextInputType.emailAddress,
                                      suffixIcon: _emailVerifie
                                          ? const Icon(Icons.verified,
                                              color: Colors.green, size: 20)
                                          : null,
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Champ obligatoire';
                                        final emailRegex = RegExp(
                                            r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                                        if (!emailRegex.hasMatch(v.trim()))
                                          return 'Email invalide';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 56,
                                    width: 90,
                                    child: ElevatedButton(
                                      onPressed:
                                          _emailVerifie ? null : _verifierEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _emailVerifie
                                            ? Colors.green.withOpacity(0.3)
                                            : _neonPurple.withOpacity(0.2),
                                        foregroundColor: _neonPurple,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: _emailVerifie
                                                ? Colors.green
                                                : _neonPurple.withOpacity(0.5),
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        _emailVerifie ? '✓' : 'Vérifier',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Téléphone ──
                              _neonField(
                                ctrl: _telCtrl,
                                fn: _fnTel,
                                label: 'Téléphone (05XXXXXXXX)',
                                icon: Icons.phone_outlined,
                                touchKey: 'tel',
                                iconColor: _neonPurple,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Champ obligatoire';
                                  if (v.length != 10)
                                    return '10 chiffres obligatoires';
                                  if (!v.startsWith('0'))
                                    return 'Doit commencer par 0';
                                  final prefix = v.substring(0, 2);
                                  if (!['05', '06', '07'].contains(prefix)) {
                                    return 'Doit commencer par 05, 06 ou 07';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── Adresse ──
                              _neonField(
                                ctrl: _adresseCtrl,
                                fn: _fnAdresse,
                                label: 'Adresse',
                                icon: Icons.location_on_outlined,
                                touchKey: 'adresse',
                                iconColor: _neonPurple,
                              ),
                              const SizedBox(height: 12),

                              // ── Numéro d'immatriculation ──
                              _neonField(
                                ctrl: _numeroCtrl,
                                fn: _fnNumero,
                                label: 'N° immatriculation (PRO-16-0000X)',
                                icon: Icons.badge_outlined,
                                touchKey: 'numero',
                                iconColor: _neonPurple,
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Za-z0-9\-]')),
                                  LengthLimitingTextInputFormatter(13),
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Champ obligatoire';
                                  final regex = RegExp(r'^PRO-\d{2}-\d{5}$');
                                  if (!regex.hasMatch(v.trim().toUpperCase()))
                                    return 'Format invalide (ex: PRO-16-00001)';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── Mot de passe ──
                              _neonField(
                                ctrl: _passCtrl,
                                fn: _fnPass,
                                label: 'Mot de passe',
                                icon: Icons.lock_outline,
                                touchKey: 'pass',
                                iconColor: _neonPurple,
                                obscure: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: _white60,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'Min 6 caractères'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // ── Confirmer mot de passe ──
                              _neonField(
                                ctrl: _confirmCtrl,
                                fn: _fnConfirm,
                                label: 'Confirmer mot de passe',
                                icon: Icons.lock_outline,
                                touchKey: 'confirm',
                                iconColor: _neonPurple,
                                obscure: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: _white60,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) => v != _passCtrl.text
                                    ? 'Mots de passe différents'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ── Info traitement ──
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _neonPurple.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _neonPurple.withOpacity(0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      color: _neonPurple.withOpacity(0.8),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Votre demande sera traitée rapidement',
                                            style: TextStyle(
                                              color: _neonPurple,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Vous serez notifié par email une fois votre compte approuvé.',
                                            style: TextStyle(
                                              color: _white60,
                                              fontSize: 11,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Bouton Envoyer ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_neonPurple, _neonPink],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _neonPurple.withOpacity(0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.send_outlined,
                                                  color: Colors.white,
                                                  size: 20),
                                              SizedBox(width: 10),
                                              Text(
                                                "Envoyer la demande",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _neonField({
    required TextEditingController ctrl,
    required FocusNode fn,
    required String label,
    required IconData icon,
    required String touchKey,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: fn,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      buildCounter: maxLength != null
          ? (context,
                  {required currentLength, required isFocused, maxLength}) =>
              null
          : null,
      style: const TextStyle(color: _white, fontSize: 14),
      autovalidateMode: _mode(touchKey),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: _white.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: iconColor.withOpacity(0.8), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: iconColor.withOpacity(0.6), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator ??
          (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
    );
  }
}

// ══════════════════════════════════════════════════
// GLASS BUTTON
// ══════════════════════════════════════════════════
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _white.withOpacity(0.08),
          border: Border.all(color: _neonPurple.withOpacity(0.4)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
