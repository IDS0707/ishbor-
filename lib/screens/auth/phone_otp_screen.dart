import "dart:async";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../../core/app_locale.dart";
import "../../../core/l10n.dart";
import "../../../services/auth_service.dart";
import "../../../services/user_service.dart";
import "login_screen.dart" show AuthGradientBg, AuthLanguageBar, authErrorSnack;

// =============================================================================
// PHONE OTP SCREEN  — step1: phone → step2: 6-digit code
// =============================================================================

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});
  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _codeSent = false;
  bool _loading = false;
  String _verificationId = "";
  int _countdown = 0;
  Timer? _timer;

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
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});
  String _t(String k) => L10n.t(k, appLocale.value);

  // ── countdown ──────────────────────────────────────────────────────────────
  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  // ── send OTP ───────────────────────────────────────────────────────────────
  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await AuthService.sendOtp(
        _phoneCtrl.text.trim(),
        onError: (msg) {
          if (mounted) _showError(msg);
        },
      );
      if (!mounted) return;
      if (result == "auto") {
        await _saveAndNavigate();
      } else {
        _verificationId = result;
        _startCountdown();
        setState(() => _codeSent = true);
        // animate transition
        _animCtrl.reset();
        _animCtrl.forward();
      }
    } catch (_) {
      // error shown via onError
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── verify OTP ─────────────────────────────────────────────────────────────
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred =
          await AuthService.verifyOtp(_verificationId, _otpCtrl.text.trim());
      if (!mounted) return;
      await UserService.saveUser(cred.user!);
      if (!mounted) return;
      await _saveAndNavigate();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? _t("otp_error"));
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAndNavigate() async {
    final user = AuthService.currentUser;
    if (user != null) await UserService.saveUser(user);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/home");
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(authErrorSnack(msg));

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

                // ── header (icon + title) ─────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
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
                        child: Icon(
                          _codeSent
                              ? Icons.lock_open_rounded
                              : Icons.phone_android_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _codeSent ? _t("step2_title") : _t("step1_title"),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _codeSent
                            ? "${_t("code_sent_to")} ${_phoneCtrl.text.trim()}"
                            : _t("sms_hint"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                    ]),
                  ),
                ),

                // ── white form card ────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: const EdgeInsets.only(top: 28),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Form(
                          key: _formKey,
                          child: _codeSent ? _buildStep2() : _buildStep1(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── step 1: phone input ────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
        controller: _phoneCtrl,
        autofocus: true,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[+\d\s]"))
        ],
        decoration: InputDecoration(
          labelText: _t("enter_phone"),
          hintText: _t("phone_hint"),
          prefixIcon: const Icon(Icons.phone_rounded),
        ),
        validator: (v) {
          if (v == null || v.trim().replaceAll(RegExp(r"\D"), "").length < 7) {
            return _t("phone_error");
          }
          return null;
        },
      ),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: _loading ? null : _sendCode,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(_t("send_code")),
      ),
    ]);
  }

  // ── step 2: OTP input ─────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 6-digit OTP field
      TextFormField(
        controller: _otpCtrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: 14,
          color: Color(0xFF111827),
        ),
        decoration: const InputDecoration(
          counterText: "",
          hintText: "------",
          hintStyle: TextStyle(
            fontSize: 28,
            letterSpacing: 12,
            color: Color(0xFFD1D5DB),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        validator: (v) => (v == null || v.length != 6) ? _t("otp_error") : null,
        onChanged: (v) {
          if (v.length == 6) _verifyCode();
        },
      ),
      const SizedBox(height: 28),

      ElevatedButton(
        onPressed: _loading ? null : _verifyCode,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(_t("verify")),
      ),
      const SizedBox(height: 16),

      // Resend / countdown
      Center(
        child: _countdown > 0
            ? Text(
                _t("resend_in").replaceAll("{s}", "$_countdown"),
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              )
            : TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        _otpCtrl.clear();
                        setState(() => _codeSent = false);
                      },
                child: Text(_t("resend_code")),
              ),
      ),

      const SizedBox(height: 4),
      Center(
        child: TextButton(
          onPressed: _loading
              ? null
              : () {
                  _timer?.cancel();
                  _otpCtrl.clear();
                  _animCtrl.reset();
                  _animCtrl.forward();
                  setState(() {
                    _codeSent = false;
                    _countdown = 0;
                  });
                },
          child: Text(_t("change_phone")),
        ),
      ),
    ]);
  }
}
