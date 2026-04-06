import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/app_locale.dart';
import '../../../core/l10n.dart';
import '../../../services/auth_service.dart';
import '../../../services/role_service.dart';
import '../../../services/user_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED AUTH SCREEN  — Sign In / Sign Up  (phone + password, NO Google)
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _primary = Color(0xFF60A5FA);
  static const _textMain = Color(0xFFF1F5F9);
  static const _textSub = Color(0xFF94A3B8);
  static const _inputFill = Color(0xFF152059);
  static const _inputBorder = Color(0xFF2D3F7A);

  // ── Tab ────────────────────────────────────────────────────────────────────
  bool _isLogin = true;

  // ── Sign-in form ───────────────────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _loginPhoneCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginLoading = false;
  bool _loginObscure = true;

  // ── Register form ──────────────────────────────────────────────────────────
  final _regFormKey = GlobalKey<FormState>();
  final _regNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  bool _regLoading = false;
  bool _regObscure = true;
  bool _regConfirmObs = true;
  bool _agreeTerms = false;

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  late final AnimationController _tabCtrl;
  late final Animation<double> _tabFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);
    _tabCtrl.value = 1.0;

    appLocale.addListener(_onLocaleChange);
    if (AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final role = await RoleService.getRole();
        if (!mounted) return;
        if (role == 'employer') {
          Navigator.pushReplacementNamed(context, '/employer-home');
        } else if (role == 'worker') {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/role-select');
        }
      });
    }
  }

  @override
  void dispose() {
    appLocale.removeListener(_onLocaleChange);
    _entryCtrl.dispose();
    _tabCtrl.dispose();
    _loginPhoneCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _onLocaleChange() {
    setState(() {});
    _tabCtrl.forward(from: 0.0);
  }

  String _t(String k) => L10n.t(k, appLocale.value);

  void _switchTab(bool login) {
    _tabCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _isLogin = login);
      _tabCtrl.forward();
    });
  }

  /// Converts phone digits to a fake email for Firebase Auth.
  String _phoneToEmail(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$digits@ishbor.app';
  }

  /// Navigate to the correct panel based on saved role, or role-select if none.
  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    final role = await RoleService.getRole();
    if (!mounted) return;
    if (role == 'employer') {
      Navigator.pushReplacementNamed(context, '/employer-home');
    } else if (role == 'worker') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  // ── Sign in ────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    try {
      final email = _phoneToEmail(_loginPhoneCtrl.text.trim());
      final cred =
          await AuthService.signInWithEmail(email, _loginPassCtrl.text);
      if (!mounted) return;
      await UserService.saveUser(cred.user!);
      if (!mounted) return;
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(authErrorSnack(_firebaseErrorMsg(e.code)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(authErrorSnack(_t('auth_generic')));
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() => _regLoading = true);
    try {
      final email = _phoneToEmail(_regPhoneCtrl.text.trim());
      final cred =
          await AuthService.registerWithEmail(email, _regPassCtrl.text);
      await cred.user!.updateDisplayName(_regNameCtrl.text.trim());
      await cred.user!.reload();
      if (!mounted) return;
      await UserService.saveUser(
        AuthService.currentUser!,
        displayName: _regNameCtrl.text.trim(),
      );
      if (!mounted) return;
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(authErrorSnack(_firebaseErrorMsg(e.code)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(authErrorSnack(_t('auth_generic')));
      }
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  // ── Firebase error code → localized message ───────────────────────────────
  String _firebaseErrorMsg(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-mismatch':
        return _t('auth_invalid_credential');
      case 'wrong-password':
        return _t('auth_wrong_password');
      case 'user-not-found':
        return _t('auth_user_not_found');
      case 'email-already-in-use':
        return _t('auth_email_in_use');
      case 'weak-password':
        return _t('auth_weak_password');
      case 'too-many-requests':
        return _t('auth_too_many');
      case 'network-request-failed':
        return _t('auth_network');
      case 'user-disabled':
        return _t('auth_disabled');
      default:
        return _t('auth_generic');
    }
  }

  // ── Validators ─────────────────────────────────────────────────────────────
  String? _phoneVal(String? v) {
    if (v == null || v.trim().isEmpty) return _t('required');
    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 7) return _t('valid_phone');
    return null;
  }

  String? _passVal(String? v) {
    if (v == null || v.length < 6) return _t('pass_error');
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Til tanlash
                      const Align(
                        alignment: Alignment.centerRight,
                        child: AuthLanguageBar(),
                      ),
                      const SizedBox(height: 16),

                      // Logo
                      const _AppLogo(),
                      const SizedBox(height: 24),

                      // Sarlavha + tavsif
                      FadeTransition(
                        opacity: _tabFade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLogin ? _t('login') : _t('register'),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? _t('signin_subtitle')
                                  : _t('signup_subtitle'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textSub,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Illustration
                      FadeTransition(
                        opacity: _tabFade,
                        child: _Illustration(isLogin: _isLogin),
                      ),
                      const SizedBox(height: 28),

                      // Form
                      FadeTransition(
                        opacity: _tabFade,
                        child: _isLogin
                            ? _buildLoginContent()
                            : _buildRegisterContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign-in content ────────────────────────────────────────────────────────
  Widget _buildLoginContent() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(_t('phone_number')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _loginPhoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: _textMain, fontSize: 15),
            decoration: _inputDec(
              hint: _t('phone_hint'),
              icon: Icons.phone_outlined,
            ),
            validator: _phoneVal,
          ),
          const SizedBox(height: 16),
          _fieldLabel(_t('password')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: _loginObscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            style: const TextStyle(color: _textMain, fontSize: 15),
            decoration: _inputDec(
              hint: _t('password_hint'),
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textSub,
                  size: 20,
                ),
                onPressed: () => setState(() => _loginObscure = !_loginObscure),
              ),
            ),
            validator: _passVal,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _t('forgot_password'),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryBtn(
            label: _t('login'),
            loading: _loginLoading,
            onTap: _loginLoading ? null : _login,
          ),
          const SizedBox(height: 28),
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: _textSub),
                children: [
                  TextSpan(text: '${_t('no_account_q')} '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => _switchTab(false),
                      child: Text(
                        _t('register'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Register content ───────────────────────────────────────────────────────
  Widget _buildRegisterContent() {
    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(_t('full_name')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regNameCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: _textMain, fontSize: 15),
            decoration: _inputDec(
              hint: _t('full_name_hint'),
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? _t('name_error') : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel(_t('phone_number')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regPhoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: _textMain, fontSize: 15),
            decoration: _inputDec(
              hint: _t('phone_hint'),
              icon: Icons.phone_outlined,
            ),
            validator: _phoneVal,
          ),
          const SizedBox(height: 16),
          _fieldLabel(_t('password')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regPassCtrl,
            obscureText: _regObscure,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: _textMain, fontSize: 15),
            decoration: _inputDec(
              hint: _t('create_password_hint'),
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _regObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textSub,
                  size: 20,
                ),
                onPressed: () => setState(() => _regObscure = !_regObscure),
              ),
            ),
            validator: _passVal,
          ),
          const SizedBox(height: 16),
          _fieldLabel(_t('confirm_password')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regConfirmCtrl,
            obscureText: _regConfirmObs,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
            style: const TextStyle(color: _textMain, fontSize: 15),
            decoration: _inputDec(
              hint: _t('confirm_hint'),
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _regConfirmObs
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textSub,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _regConfirmObs = !_regConfirmObs),
              ),
            ),
            validator: (v) {
              if (v != _regPassCtrl.text) return _t('confirm_error');
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  activeColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Color(0xFF4B5E99), width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: _textSub, height: 1.5),
                      children: [
                        TextSpan(text: _t('agree_terms_1')),
                        TextSpan(
                          text: _t('terms_of_service'),
                          style: const TextStyle(
                              color: _primary, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: _t('agree_terms_2')),
                        TextSpan(
                          text: _t('privacy_policy'),
                          style: const TextStyle(
                              color: _primary, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: _t('agree_terms_3')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PrimaryBtn(
            label: _t('register'),
            loading: _regLoading,
            onTap: _regLoading ? null : _register,
          ),
          const SizedBox(height: 28),
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: _textSub),
                children: [
                  TextSpan(text: '${_t('have_account_q')} '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => _switchTab(true),
                      child: Text(
                        _t('login'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textMain,
          ),
        ),
      );

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B7E9F),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, size: 20, color: _textSub),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder, width: 1.5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _inputBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED AUTH WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Unused — kept for export compatibility.
class AuthGradientBg extends StatelessWidget {
  const AuthGradientBg({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Row of language picker chips.
class AuthLanguageBar extends StatelessWidget {
  const AuthLanguageBar({super.key});

  static const _langs = [
    ('uz', "O'z"),
    ('uz_kr', 'Ўз'),
    ('ru', 'Рус'),
    ('en', 'En'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLocale,
      builder: (_, lang, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: _langs
            .map((e) =>
                _LangChip(code: e.$1, label: e.$2, selected: lang == e.$1))
            .toList(),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip(
      {required this.code, required this.label, required this.selected});
  final String code;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => appLocale.value = code,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFF162155),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFFCBD5E1),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ── App logo ──────────────────────────────────────────────────────────────────
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.manage_search_rounded,
              size: 26, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text(
          'IshTopchi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ── Illustration ──────────────────────────────────────────────────────────────
class _Illustration extends StatelessWidget {
  const _Illustration({required this.isLogin});
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: const Color(0xFF152059),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -12,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLogin
                        ? Icons.laptop_mac_rounded
                        : Icons.assignment_ind_rounded,
                    size: 36,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLogin ? Icons.lock_rounded : Icons.person_add_rounded,
                        size: 26,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLogin
                            ? Icons.work_rounded
                            : Icons.check_circle_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.label, required this.loading, required this.onTap});
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(label),
        ),
      ),
    );
  }
}

// ── Shared error snack ────────────────────────────────────────────────────────
SnackBar authErrorSnack(String msg) => SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
