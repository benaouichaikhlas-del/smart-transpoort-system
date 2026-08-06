import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/home_screen.dart';
import '../screens/register_choice_screen.dart';
import '../screens/conducteur_home_screen.dart';
import '../screens/proprietaire_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? savedEmail;
  final String? savedPassword;

  const LoginScreen({super.key, this.savedEmail, this.savedPassword});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFn = FocusNode();
  final _passFn = FocusNode();
  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    if (widget.savedEmail != null) {
      _emailCtrl.text = widget.savedEmail!;
      _passwordCtrl.text = widget.savedPassword ?? '';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFn.dispose();
    _passFn.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // ✅ إخفاء الكيبورد قبل التحقق
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (auth.premierConnexion && auth.user?.role == 'conducteur') {
        await _showChangerMotDePasseDialog();
        return;
      }
      _naviguerVersHome(auth.user!.role);
    } else {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? l.erreur),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showChangerMotDePasseDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            final l = AppLocalizations.of(context)!;
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.lock_reset,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.bienvenue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.securiteMotDePasse,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                // ✅ حل overflow في الديالوغ
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passCtrl,
                      obscureText: obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l.nouveauMotDePasse,
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
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l.confirmerMotDePasse,
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final l = AppLocalizations.of(context)!;
                              if (passCtrl.text.trim().length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.min6Caracteres),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (passCtrl.text != confirmCtrl.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.motsDePasseDifferents),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setS(() => loading = true);
                              final token =
                                  context.read<AuthProvider>().user!.token;

                              final r = await http.put(
                                Uri.parse(
                                  '${ApiConstants.baseUrl}/auth/changer-mot-de-passe',
                                ),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer $token',
                                },
                                body: jsonEncode({
                                  'nouveau_mot_de_passe': passCtrl.text.trim(),
                                }),
                              );
                              setS(() => loading = false);

                              if (r.statusCode == 200) {
                                context
                                    .read<AuthProvider>()
                                    .clearPremierConnexion();
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                _naviguerVersHome('conducteur');
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.erreurReessayez),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l.confirmer,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;
    bool codeEnvoye = false;
    String? erreur;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l = AppLocalizations.of(context)!;

          Future<void> envoyerCode() async {
            final l = AppLocalizations.of(context)!;
            final email = emailCtrl.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              setS(() => erreur = l.emailInvalide);
              return;
            }
            setS(() {
              loading = true;
              erreur = null;
            });
            try {
              final r = await http.post(
                Uri.parse('${ApiConstants.baseUrl}/auth/forgot-password'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'email': email}),
              );
              setS(() => loading = false);
              if (r.statusCode == 200) {
                setS(() => codeEnvoye = true);
              } else {
                setS(() => erreur = l.erreurReessayez);
              }
            } catch (_) {
              setS(() {
                loading = false;
                erreur = l.erreurReessayez;
              });
            }
          }

          Future<void> confirmerReset() async {
            final l = AppLocalizations.of(context)!;
            if (codeCtrl.text.trim().isEmpty) {
              setS(() => erreur = l.champObligatoire);
              return;
            }
            if (passCtrl.text.trim().length < 6) {
              setS(() => erreur = l.min6Caracteres);
              return;
            }
            if (passCtrl.text != confirmCtrl.text) {
              setS(() => erreur = l.motsDePasseDifferents);
              return;
            }

            setS(() {
              loading = true;
              erreur = null;
            });
            try {
              final r = await http.post(
                Uri.parse('${ApiConstants.baseUrl}/auth/reset-password'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'email': emailCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'nouveau_mot_de_passe': passCtrl.text.trim(),
                }),
              );
              setS(() => loading = false);
              if (r.statusCode == 200) {
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.motDePasseReinitialise),
                    backgroundColor: AppTheme.secondary,
                  ),
                );
              } else {
                final body = jsonDecode(r.body);
                setS(() => erreur = body['message'] ?? l.erreurReessayez);
              }
            } catch (_) {
              setS(() {
                loading = false;
                erreur = l.erreurReessayez;
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.mail_lock_outlined,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  l.motDePasseOublie,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  codeEnvoye ? l.entrerCodeRecu : l.entrerEmailPourCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            content: SingleChildScrollView(
              // ✅ حل overflow في الديالوغ
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!codeEnvoye) ...[
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l.emailOuTelephone,
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Colors.white38),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: Colors.white, letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.pin_outlined,
                            color: Colors.white38),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l.nouveauMotDePasse,
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.white38),
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
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l.confirmerMotDePasse,
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.white38),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  if (erreur != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      erreur!,
                      style:
                          const TextStyle(color: AppTheme.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : (codeEnvoye ? confirmerReset : envoyerCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            codeEnvoye ? l.confirmer : l.envoyerCode,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                  ),
                ),
              ),
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: Text(
                  l.annuler,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _naviguerVersHome(String role) {
    Widget screen;
    switch (role) {
      case 'proprietaire':
        screen = const ProprietaireHomeScreen();
        break;
      case 'conducteur':
        screen = const ConducteurHomeScreen();
        break;
      default:
        screen = const HomeScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // ✅ حساب ارتفاع الكيبورد لضبط المسافات
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardHeight = viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final l = AppLocalizations.of(context)!;
        return Scaffold(
          // ✅ الحل الرئيسي: يسمح للشاشة بالتكيف مع الكيبورد
          resizeToAvoidBottomInset: true,
          extendBodyBehindAppBar: true,
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: _GlassIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _LanguageBadge(localeProvider: localeProvider),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ═══════════════════════════════════════════════
              // 1) صورة الخلفية
              // ═══════════════════════════════════════════════
              Image.asset(
                'assets/images/transport_algerien_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
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
                  );
                },
              ),

              // ═══════════════════════════════════════════════
              // 2) تدرج داكن
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
                      AppTheme.background.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.35, 0.65, 0.92],
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════
              // 3) المحتوى — قابل للتمرير ويتكيف مع الكيبورد
              // ═══════════════════════════════════════════════
              SafeArea(
                child: SingleChildScrollView(
                  // ✅ يضيف مسافة أسفل تساوي ارتفاع الكيبورد
                  padding: EdgeInsets.only(bottom: keyboardHeight + 20),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: isKeyboardOpen
                            ? 20
                            : MediaQuery.of(context).size.height * 0.06,
                      ),
                      const _BrandBadge(),
                      const SizedBox(height: 16),
                      Text(
                        l.bienvenue,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: Text(
                          l.connexionAccesEspace,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            height: 1.4,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // ✅ المسافة تتقلص تلقائياً لما يطلع الكيبورد
                      SizedBox(
                        height: isKeyboardOpen
                            ? 24
                            : MediaQuery.of(context).size.height * 0.18,
                      ),

                      // ═══════════════════════════════════════════════
                      // 4) بطاقة النموذج الزجاجية
                      // ═══════════════════════════════════════════════
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.2,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // ✅ scrollPadding يمنع الحقل من الاختفاء تحت الكيبورد
                                  TextFormField(
                                    controller: _emailCtrl,
                                    focusNode: _emailFn,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.next,
                                    scrollPadding:
                                        const EdgeInsets.only(bottom: 120),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _glassInputDecoration(
                                      hint: l.emailOuTelephone,
                                      icon: Icons.person_outline,
                                    ),
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_passFn);
                                    },
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return l.champObligatoire;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: _passwordCtrl,
                                    focusNode: _passFn,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    scrollPadding:
                                        const EdgeInsets.only(bottom: 120),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _glassInputDecoration(
                                      hint: l.motDePasse,
                                      icon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white54,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                      ),
                                    ),
                                    onFieldSubmitted: (_) => _onLogin(),
                                    validator: (v) => v == null || v.length < 6
                                        ? l.min6Caracteres
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // تذكرني + نسيت كلمة المرور
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _RememberMeCheckbox(
                                          value: _rememberMe,
                                          label: l.seSouvenirDeMoi,
                                          onChanged: (v) =>
                                              setState(() => _rememberMe = v),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: GestureDetector(
                                          onTap: _showForgotPasswordDialog,
                                          child: Text(
                                            l.motDePasseOublie,
                                            textAlign: TextAlign.end,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // زر تسجيل الدخول
                                  _GradientButton(
                                    loading: auth.isLoading,
                                    label: l.seConnecter,
                                    icon: Icons.login,
                                    onPressed: auth.isLoading ? null : _onLogin,
                                  ),
                                  const SizedBox(height: 24),

                                  // فاصل "ou"
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                            color:
                                                Colors.white.withOpacity(0.15)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          l.ou.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                            color:
                                                Colors.white.withOpacity(0.15)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // سجل الآن
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterChoiceScreen(),
                                      ),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(text: '${l.pasDeCompte} '),
                                          TextSpan(
                                            text: l.sinscrire,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _glassInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.85)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// عناصر واجهة مستخدم قابلة لإعادة الاستخدام
/// ═══════════════════════════════════════════════════════════════════════

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.50),
            blurRadius: 28,
            spreadRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.background,
        ),
        child: const Icon(
          Icons.directions_bus_filled_outlined,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final LocaleProvider localeProvider;

  const _LanguageBadge({required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: ربط بمنطق تبديل اللغة
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇩🇿', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              localeProvider.locale.languageCode == 'ar'
                  ? 'العربية'
                  : localeProvider.locale.languageCode == 'en'
                      ? 'English'
                      : 'Français',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _RememberMeCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: value
                  ? const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    )
                  : null,
              color: value ? null : Colors.transparent,
              border: Border.all(
                color: value ? Colors.transparent : Colors.white38,
                width: 1.4,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.loading,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
