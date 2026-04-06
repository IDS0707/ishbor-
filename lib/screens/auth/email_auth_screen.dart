import "package:flutter/material.dart";
import "../../../core/app_locale.dart";
import "../../../core/l10n.dart";
import "../../../services/auth_service.dart";
import "../../../services/user_service.dart";
import "login_screen.dart" show AuthGradientBg, AuthLanguageBar, authErrorSnack;

// =============================================================================
// EMAIL AUTH SCREEN  — animated Login / Register toggle
// =============================================================================

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});
  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen>
    with TickerProviderStateMixin {
  bool _isLogin = true;

  // Login
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginLoading = false;
  bool _loginObscure = true;

  // Register
  final _regFormKey = GlobalKey<FormState>();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  bool _regLoading = false;
  bool _regObscure = true;
  bool _regConfirmObs = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    appLocale.addListener(_rebuild);
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    _animCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});
  String _t(String k) => L10n.t(k, appLocale.value);

  void _switchTab(bool login) {
    setState(() => _isLogin = login);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    try {
      final cred = await AuthService.signInWithEmail(
          _loginEmailCtrl.text.trim(), _loginPassCtrl.text);
      if (!mounted) return;
      await UserService.saveUser(cred.user!);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() => _regLoading = true);
    try {
      final cred = await AuthService.registerWithEmail(
          _regEmailCtrl.text.trim(), _regPassCtrl.text);
      await cred.user!.updateDisplayName(_regNameCtrl.text.trim());
      await cred.user!.reload();
      if (!mounted) {
        return;
      }
      await UserService.saveUser(AuthService.currentUser!,
          displayName: _regNameCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(authErrorSnack(msg));

  // ── Validators ─────────────────────────────────────────────────────────────
  String? _emailVal(String? v) {
    if (v == null || v.trim().isEmpty) return _t("email_error");
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+").hasMatch(v.trim())) {
      return _t("email_error");
    }
    return null;
  }

  String? _passVal(String? v) {
    if (v == null || v.length < 6) return _t("pass_error");
    return null;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuthGradientBg(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── top bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const AuthLanguageBar(),
                  ]),
                ),

                // ── header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                  child: Column(children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.email_rounded,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _t("email_signin_title"),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5),
                    ),
                  ]),
                ),

                // ── white form card ────────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 24,
                            offset: Offset(0, -4))
                      ],
                    ),
                    child: Column(children: [
                      // ── toggle slider ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            _TabBtn(
                                label: _t("login"),
                                active: _isLogin,
                                onTap: () => _switchTab(true)),
                            _TabBtn(
                                label: _t("register"),
                                active: !_isLogin,
                                onTap: () => _switchTab(false)),
                          ]),
                        ),
                      ),

                      // ── animated form ─────────────────────────────────────
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                            child: _isLogin ? _buildLogin() : _buildRegister(),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Login form ─────────────────────────────────────────────────────────────
  Widget _buildLogin() {
    return Form(
      key: _loginFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          _t("welcome_back"),
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _t("email"),
            hintText: _t("email_hint"),
            prefixIcon: const Icon(Icons.email_rounded),
          ),
          validator: _emailVal,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _loginPassCtrl,
          obscureText: _loginObscure,
          decoration: InputDecoration(
            labelText: _t("password"),
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(_loginObscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
          validator: _passVal,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _loginLoading ? null : _login,
          child: _loginLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(_t("login")),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _switchTab(false),
          child: Text(_t("no_account")),
        ),
      ]),
    );
  }

  // ── Register form ──────────────────────────────────────────────────────────
  Widget _buildRegister() {
    return Form(
      key: _regFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          _t("create_account"),
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _regNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _t("full_name"),
            hintText: _t("full_name_hint"),
            prefixIcon: const Icon(Icons.person_rounded),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? _t("name_error") : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _t("email"),
            hintText: _t("email_hint"),
            prefixIcon: const Icon(Icons.email_rounded),
          ),
          validator: _emailVal,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _regPassCtrl,
          obscureText: _regObscure,
          decoration: InputDecoration(
            labelText: _t("password"),
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(_regObscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () => setState(() => _regObscure = !_regObscure),
            ),
          ),
          validator: _passVal,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _regConfirmCtrl,
          obscureText: _regConfirmObs,
          decoration: InputDecoration(
            labelText: _t("confirm_password"),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_regConfirmObs
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () => setState(() => _regConfirmObs = !_regConfirmObs),
            ),
          ),
          validator: (v) {
            if (v != _regPassCtrl.text) return _t("confirm_error");
            return null;
          },
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _regLoading ? null : _register,
          child: _regLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(_t("register")),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _switchTab(true),
          child: Text(_t("have_account")),
        ),
      ]),
    );
  }
}

// ── Toggle tab button ─────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    const BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}
