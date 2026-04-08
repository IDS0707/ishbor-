import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_locale.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/employer_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_job_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/questions_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/worker_profile_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

/// Global navigator key — used by NotificationService to navigate from outside
/// the widget tree when a push notification is tapped.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Catch all uncaught async Dart errors — prevents app from closing
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch all uncaught Flutter framework errors — show red error box instead of crashing
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // ── Firestore offline persistence (disk cache) ────────────────────────────
    // Ishlar, chatlar, bildirishnomalar — internet bo'lmasa ham ko'rinadi.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // ─────────────────────────────────────────────────────────────────────────
    // App Check is disabled until the app is published to Play Store.
    // playIntegrity only works for Play Store installs and blocks sideloaded APKs.
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_V3_SITE_KEY'),
      );
    } catch (_) {}
    // ─────────────────────────────────────────────────────────────────────────

    await loadSavedTheme();
    await NotificationService.init();

    // Wire up push-notification tap → navigate to chat
    NotificationService.onNotificationTap = _handleNotificationTap;

    runApp(const JobFinderApp());

    // Check if app was opened from a terminated-state notification
    final initialData = await NotificationService.getInitialNotificationData();
    if (initialData != null) {
      // Small delay to let the widget tree mount
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationTap(initialData);
    }
  }, (error, stack) {
    // Catch all uncaught async errors — log them but don't crash the app
    debugPrint('Uncaught error: $error\n$stack');
  });
}

/// Routes to the relevant ChatScreen when a push notification is tapped.
/// Expects payload keys: jobId, seekerUid, jobTitle, posterUid, opponentName.
void _handleNotificationTap(Map<String, dynamic> data) {
  final jobId = data['jobId'] as String? ?? '';
  final seekerUid = data['seekerUid'] as String? ?? '';
  if (jobId.isEmpty || seekerUid.isEmpty) return;

  final myUid = AuthService.currentUser?.uid ?? '';
  final posterUid = data['posterUid'] as String? ?? '';
  final jobTitle = data['jobTitle'] as String? ?? '';
  final opponentName = data['opponentName'] as String? ?? '';

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        jobId: jobId,
        jobTitle: jobTitle,
        seekerUid: seekerUid,
        posterUid: posterUid,
        opponentName: opponentName.isNotEmpty
            ? opponentName
            : (myUid == seekerUid ? 'Ish beruvchi' : 'Ish izlovchi'),
      ),
    ),
  );
}

class JobFinderApp extends StatelessWidget {
  const JobFinderApp({super.key});

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData _buildTheme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1B4B),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData _buildDarkTheme() => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          floatingLabelStyle: const TextStyle(color: Color(0xFF60A5FA)),
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF60A5FA),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, themeMode, __) => ValueListenableBuilder<String>(
        valueListenable: appLocale,
        builder: (_, __, ___) => MaterialApp(
          title: 'Ishbor',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: _buildTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/role-select': (_) => const RoleSelectionScreen(),
            '/home': (_) => const HomeScreen(),
            '/employer-home': (_) => const EmployerHomeScreen(),
            '/post-job': (_) => const PostJobScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/questions': (_) => const QuestionsScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/worker-profile': (_) => const WorkerProfileSetupScreen(),
          },
        ),
      ),
    );
  }
}
