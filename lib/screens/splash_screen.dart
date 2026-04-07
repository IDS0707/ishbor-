import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/role_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Status bar — oq ikonkalar to'q fonda
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();

    // Ruxsatlarni so'rash (splash ko'rinayotganida)
    _requestPermissions();

    // 2.2 soniyadan keyin navigatsiya
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  /// Bildirishnoma va joylashuv ruxsatlarini so'rash (Android 13+)
  Future<void> _requestPermissions() async {
    await [
      Permission.notification,
      Permission.location,
    ].request();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    if (AuthService.isLoggedIn) {
      // Save/refresh FCM token so this device can receive push notifications
      unawaited(NotificationService.saveToken());
      final role = await RoleService.getRole();
      if (!mounted) return;
      if (role == 'employer') {
        Navigator.pushReplacementNamed(context, '/employer-home');
      } else if (role == 'worker') {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/role-select');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final isWeb = w >= 720;

        // Web: katta logo, yon panel, keng layout
        // Mobile: oddiy markazlashgan layout
        final logoSize = isWeb ? 130.0 : 100.0;
        final logoRadius = isWeb ? 36.0 : 28.0;
        final logoIconSize = isWeb ? 68.0 : 52.0;
        final titleSize = isWeb ? 52.0 : 38.0;
        final subtitleSize = isWeb ? 18.0 : 15.0;
        final bottomOffset = isWeb ? 48.0 : 60.0;

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B4B),
          body: Stack(
            children: [
              // ── Dekorativ doiralar (o'lchamga moslashadi) ────────────────
              Positioned(
                top: -h * 0.1,
                right: -w * 0.15,
                child: Container(
                  width: w * (isWeb ? 0.35 : 0.7),
                  height: w * (isWeb ? 0.35 : 0.7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.45),
                  ),
                ),
              ),
              Positioned(
                bottom: -h * 0.1,
                left: -w * 0.1,
                child: Container(
                  width: w * (isWeb ? 0.3 : 0.65),
                  height: w * (isWeb ? 0.3 : 0.65),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                  ),
                ),
              ),
              Positioned(
                top: h * 0.5,
                right: -w * 0.05,
                child: Container(
                  width: w * (isWeb ? 0.18 : 0.35),
                  height: w * (isWeb ? 0.18 : 0.35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  ),
                ),
              ),

              // ── Web: ikkita ustun ────────────────────────────────────────
              if (isWeb)
                Row(
                  children: [
                    // Chap: branding
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D1B4B), Color(0xFF162670)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: FadeTransition(
                            opacity: _fade,
                            child: ScaleTransition(
                              scale: _scale,
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _logo(logoSize, logoRadius, logoIconSize),
                                    const SizedBox(height: 40),
                                    Text(
                                      'IshTopchi',
                                      style: TextStyle(
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Ishni tez top, ishchi tez top',
                                      style: TextStyle(
                                        fontSize: subtitleSize,
                                        color: const Color(0xFF93C5FD),
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // O'ng: statistika / features panel
                    Expanded(
                      flex: 4,
                      child: Container(
                        color: const Color(0xFF0A1540),
                        child: Center(
                          child: FadeTransition(
                            opacity: _fade,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _featureRow(
                                    Icons.search_rounded,
                                    "Minglab ish o'rinlari",
                                    "Barcha sohalarda vakansiyalar",
                                  ),
                                  const SizedBox(height: 28),
                                  _featureRow(
                                    Icons.location_on_rounded,
                                    "Hududingizda",
                                    "Yaqin atrofdagi ishlar",
                                  ),
                                  const SizedBox(height: 28),
                                  _featureRow(
                                    Icons.chat_bubble_outline_rounded,
                                    "Bevosita muloqot",
                                    "Ish beruvchi bilan chat",
                                  ),
                                  const SizedBox(height: 48),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF60A5FA),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        'Yuklanmoqda...',
                                        style: TextStyle(
                                          fontSize: subtitleSize - 2,
                                          color: const Color(0xFF60A5FA),
                                          fontWeight: FontWeight.w500,
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
                    ),
                  ],
                ),

              // ── Mobile: markazlashgan ─────────────────────────────────────
              if (!isWeb)
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _logo(logoSize, logoRadius, logoIconSize),
                          const SizedBox(height: 28),
                          Text(
                            'IshTopchi',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Ishni tez top, ishchi tez top',
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: const Color(0xFF93C5FD),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Pastdagi loading (faqat mobile) ──────────────────────────
              if (!isWeb)
                Positioned(
                  bottom: bottomOffset,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _fade,
                    child: const Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'ishbor.uz',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B7BBA),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
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

  Widget _logo(double size, double radius, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.manage_search_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF60A5FA), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
