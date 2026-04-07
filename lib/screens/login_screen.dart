import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';

// ── Hokimyat color palette ───────────────────────────────────────────────────
const _kNavy = Color(0xFF003580);
const _kGold = Color(0xFFD4A017);
const _kGreen = Color(0xFF009A44);
const _kLightBg = Color(0xFFF4F6FA);
const _kBorder = Color(0xFFCDD5E0);

/// Two-step phone OTP login screen — hokimyat (government) design.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _verificationId;
  String? _error;

  // Entry animations
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  // Step-switch animation
  late final AnimationController _stepCtrl;
  late final Animation<Offset> _stepSlide;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();

    // ── Entry animation (runs once on screen open) ─────────────────────────
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // ── Step-switch animation ──────────────────────────────────────────────
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _stepSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic));
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);

    _stepCtrl.value = 1.0;

    if (AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _navigateAfterAuth();
      });
    } else {
      _entryCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _stepCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Telefon raqamingizni kiriting.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vId = await AuthService.sendOtp(
        phone,
        onError: (msg) {
          if (mounted) setState(() => _error = msg);
        },
      );
      if (!mounted) return;
      if (vId == 'auto') {
        await _navigateAfterAuth();
      } else {
        _stepCtrl.reset();
        setState(() {
          _codeSent = true;
          _verificationId = vId;
        });
        _stepCtrl.forward();
      }
    } catch (_) {
      // Error shown via onError callback.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 raqamli kodni kiriting.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.verifyOtp(_verificationId!, code);
      if (mounted) await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Noto\'g\'ri kod.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Login muvaffaqiyatli bo'lgandan keyin rolga qarab yo'naltirish
  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    final role = await RoleService.getRole();
    if (!mounted) return;
    if (role == 'employer') {
      Navigator.pushReplacementNamed(context, '/employer-home');
    } else if (role == 'worker') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Yangi foydalanuvchi — rol tanlash ekraniga
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  void _backToPhone() {
    _stepCtrl.reset();
    setState(() {
      _codeSent = false;
      _verificationId = null;
      _error = null;
      _otpCtrl.clear();
    });
    _stepCtrl.forward();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLightBg,
      body: Column(
        children: [
          // ── Government top header ────────────────────────────────────────
          FadeTransition(
            opacity: _logoFade,
            child: SlideTransition(
              position: _logoSlide,
              child: const _GovHeader(),
            ),
          ),

          // ── Flag accent lines ────────────────────────────────────────────
          Container(height: 4, color: _kNavy),
          Container(height: 2, color: _kGold),
          Container(height: 2, color: _kGreen),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Emblem + system name
                  FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: const _SystemBranding(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Form card
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _GovFormCard(
                        child: FadeTransition(
                          opacity: _stepFade,
                          child: SlideTransition(
                            position: _stepSlide,
                            child: _codeSent
                                ? _OtpStep(
                                    phone: _phoneCtrl.text,
                                    controller: _otpCtrl,
                                    loading: _loading,
                                    error: _error,
                                    onVerify: _verifyOtp,
                                    onBack: _backToPhone,
                                  )
                                : _PhoneStep(
                                    controller: _phoneCtrl,
                                    loading: _loading,
                                    error: _error,
                                    onSend: _sendOtp,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _cardFade,
                    child: const _GovFooter(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Government top header ────────────────────────────────────────────────────

class _GovHeader extends StatelessWidget {
  const _GovHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Coat of arms placeholder — shield icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kGold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "O'ZBEKISTON RESPUBLIKASI",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ishbor Tizimi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── System branding (emblem + title under header) ─────────────────────────────

class _SystemBranding extends StatelessWidget {
  const _SystemBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _kNavy,
            shape: BoxShape.circle,
            border: Border.all(color: _kGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kNavy.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.work_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text(
          'ISHBOR',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kNavy,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Mehnat bozori axborot tizimi',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Government form card ──────────────────────────────────────────────────────

class _GovFormCard extends StatelessWidget {
  final Widget child;
  const _GovFormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outlined, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  'TIZIMGA KIRISH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Government footer ────────────────────────────────────────────────────────

class _GovFooter extends StatelessWidget {
  const _GovFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: _kBorder),
        const SizedBox(height: 12),
        const Text(
          '© 2026 O\'zbekiston Respublikasi Mehnat vazirligi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.black38),
        ),
        const SizedBox(height: 4),
        const Text(
          'Barcha huquqlar himoyalangan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ],
    );
  }
}

// ── Step 1 — Phone ───────────────────────────────────────────────────────────

class _PhoneStep extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSend;

  const _PhoneStep({
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Telefon raqamingizni kiriting',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        _GovField(
          controller: controller,
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          enabled: !loading,
          autofocus: true,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: error!),
        ],
        const SizedBox(height: 24),
        _GradientButton(
          label: 'Kod yuborish',
          loading: loading,
          onPressed: onSend,
        ),
      ],
    );
  }
}

// ── Step 2 — OTP ─────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String phone;
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const _OtpStep({
    required this.phone,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onVerify,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            children: [
              const TextSpan(text: 'Kod yuborildi: '),
              TextSpan(
                text: phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kNavy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _OtpField(controller: controller, enabled: !loading),
        if (error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: error!),
        ],
        const SizedBox(height: 24),
        _GradientButton(
          label: 'Tasdiqlash',
          loading: loading,
          onPressed: onVerify,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: loading ? null : onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
          label: const Text('Raqamni o\'zgartirish'),
          style: TextButton.styleFrom(
            foregroundColor: _kNavy,
          ),
        ),
      ],
    );
  }
}

// ── OTP big-letter field ─────────────────────────────────────────────────────

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _OtpField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      autofocus: true,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 14,
        color: _kNavy,
      ),
      decoration: InputDecoration(
        hintText: '······',
        hintStyle: TextStyle(
          fontSize: 30,
          letterSpacing: 14,
          color: Colors.grey.shade300,
          fontWeight: FontWeight.w700,
        ),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kNavy, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      enabled: enabled,
    );
  }
}

// ── Government-style form field ──────────────────────────────────────────────

class _GovField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool enabled;
  final bool autofocus;

  const _GovField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: _kNavy, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kNavy, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Gradient button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: loading ? 0.7 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: loading ? const Color(0xFF7090BB) : _kNavy,
            borderRadius: BorderRadius.circular(6),
            border: loading
                ? null
                : Border.all(color: _kGold.withOpacity(0.6), width: 1),
            boxShadow: loading
                ? []
                : [
                    BoxShadow(
                      color: _kNavy.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
