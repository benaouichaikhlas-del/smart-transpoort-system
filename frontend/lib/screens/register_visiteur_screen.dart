import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../widgets/email_verification_dialog.dart';
import 'login_screen.dart';

// ══════════════════════════════════════════════════
// COULEURS NÉON — VISITEUR (Cyan/Bleu)
// ══════════════════════════════════════════════════
const _bg = Color(0xFF0A0612);
const _surface = Color(0xFF13091F);
const _neonCyan = Color(0xFF06B6D4);
const _neonBlue = Color(0xFF2563EB);
const _white = Colors.white;
const _white60 = Color(0x99FFFFFF);
const _white30 = Color(0x4DFFFFFF);

class RegisterVisiteurScreen extends StatefulWidget {
  const RegisterVisiteurScreen({super.key});

  @override
  State<RegisterVisiteurScreen> createState() => _RegisterVisiteurScreenState();
}

class _RegisterVisiteurScreenState extends State<RegisterVisiteurScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _fnNom = FocusNode();
  final _fnPrenom = FocusNode();
  final _fnAge = FocusNode();
  final _fnEmail = FocusNode();
  final _fnTel = FocusNode();
  final _fnPass = FocusNode();
  final _fnConfirm = FocusNode();

  final Set<String> _touched = {};

  bool _obscure = true;
  bool _isLoading = false;
  bool _emailVerifie = false;

  @override
  void initState() {
    super.initState();
    _addTouchListener(_fnPrenom, 'prenom');
    _addTouchListener(_fnNom, 'nom');
    _addTouchListener(_fnAge, 'age');
    _addTouchListener(_fnEmail, 'email');
    _addTouchListener(_fnTel, 'tel');
    _addTouchListener(_fnPass, 'pass');
    _addTouchListener(_fnConfirm, 'confirm');
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
      _passCtrl,
      _confirmCtrl,
    ]) c.dispose();
    for (final fn in [
      _fnNom,
      _fnPrenom,
      _fnAge,
      _fnEmail,
      _fnTel,
      _fnPass,
      _fnConfirm,
    ]) fn.dispose();
    super.dispose();
  }

  String? _formatAlgerianPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s'), '');
    if (RegExp(r'^0[5-7]\d{8}$').hasMatch(clean)) return clean;
    return null;
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _register() async {
    if (!_emailVerifie) {
      _showSnack('Veuillez vérifier votre email avant de vous inscrire',
          Colors.orange);
      return;
    }
    setState(() => _touched
        .addAll(['prenom', 'nom', 'age', 'email', 'tel', 'pass', 'confirm']));
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.inscrireVisiteur),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nom': _nomCtrl.text.trim(),
              'prenom': _prenomCtrl.text.trim(),
              'age': int.parse(_ageCtrl.text.trim()),
              'email': _emailCtrl.text.trim(),
              'tel': _formatAlgerianPhone(_telCtrl.text.trim())!,
              'adresse': '',
              'mot_de_passe': _passCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);
      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnack('✅ Compte créé !', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              savedEmail: _emailCtrl.text.trim(),
              savedPassword: _passCtrl.text.trim(),
            ),
          ),
        );
      } else {
        _showSnack(data['message'] ?? 'Erreur', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnack('Erreur de connexion au serveur', Colors.red);
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
          // 1) خلفية الصورة + تدرج
          // ═══════════════════════════════════════════════
          Image.asset(
            'assets/images/vis.png',
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
          // 2) تدرج داكن قوي من الأسفل
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

                    // ── Icône néon cyan ──
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _neonCyan.withOpacity(0.1),
                          border: Border.all(
                            color: _neonCyan.withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _neonCyan.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: _neonCyan,
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
                              text: 'Visiteur',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [_neonCyan, _neonBlue],
                                  ).createShader(
                                      const Rect.fromLTWH(0, 0, 150, 40)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Créez votre compte pour accéder\nà toutes les fonctionnalités',
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
                                      iconColor: _neonCyan,
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
                                      iconColor: _neonCyan,
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
                                iconColor: _neonCyan,
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
                                      iconColor: _neonCyan,
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
                                            : _neonCyan.withOpacity(0.2),
                                        foregroundColor: _neonCyan,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: _emailVerifie
                                                ? Colors.green
                                                : _neonCyan.withOpacity(0.5),
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
                                iconColor: _neonCyan,
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

                              // ── Mot de passe ──
                              _neonField(
                                ctrl: _passCtrl,
                                fn: _fnPass,
                                label: 'Mot de passe',
                                icon: Icons.lock_outline,
                                touchKey: 'pass',
                                iconColor: _neonCyan,
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
                                iconColor: _neonCyan,
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

                              // ── Sécurité info ──
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _neonCyan.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _neonCyan.withOpacity(0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      color: _neonCyan.withOpacity(0.8),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vos données sont sécurisées',
                                            style: TextStyle(
                                              color: _neonCyan,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Nous protégeons vos informations personnelles et ne les partageons jamais.',
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

                              // ── Bouton S'inscrire ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_neonCyan, _neonBlue],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _neonCyan.withOpacity(0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
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
                                              Icon(Icons.person_add_outlined,
                                                  color: Colors.white,
                                                  size: 20),
                                              SizedBox(width: 10),
                                              Text(
                                                "S'inscrire",
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

                    // ── Déjà un compte ──
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14),
                            children: [
                              const TextSpan(
                                text: 'Vous avez déjà un compte ? ',
                                style: TextStyle(color: _white60),
                              ),
                              TextSpan(
                                text: 'Se connecter',
                                style: TextStyle(
                                  color: _neonCyan,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: _neonCyan.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
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
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: fn,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
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
          border: Border.all(color: _neonCyan.withOpacity(0.4)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
