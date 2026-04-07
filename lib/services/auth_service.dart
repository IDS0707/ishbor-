import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Handles Phone OTP and Email/Password authentication.
///
/// Platform branching:
///   Web    → signInWithPhoneNumber  (reCAPTCHA handled automatically)
///   Mobile → verifyPhoneNumber
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stored on web after [sendOtp], used by [verifyOtp].
  static ConfirmationResult? _webConfirmation;

  // ── Getters ───────────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ══════════════════════════════════════════════════════════════════════════
  // PHONE OTP
  // ══════════════════════════════════════════════════════════════════════════

  /// Sends an OTP to [phoneNumber] (international format: +998901234567).
  ///
  /// Returns:
  ///  • `'web_otp_sent'`   — web, SMS dispatched
  ///  • `'auto'`           — Android instant-verified, user already signed in
  ///  • a verificationId   — mobile, await [verifyOtp]
  ///
  /// Calls [onError] and throws [FirebaseAuthException] on failure.
  static Future<String> sendOtp(
    String phoneNumber, {
    required void Function(String message) onError,
  }) {
    return kIsWeb
        ? _sendOtpWeb(phoneNumber, onError: onError)
        : _sendOtpMobile(phoneNumber, onError: onError);
  }

  static Future<String> _sendOtpWeb(
    String phoneNumber, {
    required void Function(String) onError,
  }) async {
    try {
      // Passing no verifier → Firebase uses an invisible reCAPTCHA automatically.
      _webConfirmation = await _auth.signInWithPhoneNumber(phoneNumber);
      return 'web_otp_sent';
    } on FirebaseAuthException catch (e) {
      onError(_friendlyAuthError(e));
      rethrow;
    }
  }

  static Future<String> _sendOtpMobile(
    String phoneNumber, {
    required void Function(String) onError,
  }) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete('auto');
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_friendlyAuthError(e));
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  /// Verifies the 6-digit [smsCode].
  ///
  /// On web  → uses stored [ConfirmationResult.confirm].
  /// On mobile → builds [PhoneAuthCredential] then calls signInWithCredential.
  static Future<UserCredential> verifyOtp(
    String verificationId,
    String smsCode,
  ) async {
    if (kIsWeb) {
      if (_webConfirmation == null) {
        throw StateError('Call sendOtp() before verifyOtp() on web.');
      }
      return _webConfirmation!.confirm(smsCode);
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMAIL / PASSWORD
  // ══════════════════════════════════════════════════════════════════════════

  /// Create a new account.
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in to an existing account.
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCOUNT MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the set of provider IDs linked to the current user.
  /// e.g. {'phone', 'password'}
  static Set<String> get linkedProviders =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toSet() ?? {};

  /// Changes the password for the current email/password user.
  static Future<void> changePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════════════════

  /// Re-authenticates an email/password user before sensitive operations.
  /// Throws [FirebaseAuthException] on failure (e.g. wrong-password).
  static Future<void> reauthenticateWithEmail(
      String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No user signed in.');
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  static Future<void> signOut() async {
    _webConfirmation = null;
    await _auth.signOut();
  }

  // ── Error helper ──────────────────────────────────────────────────────────

  static String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use international format (+998…).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'invalid-verification-code':
        return 'Wrong code. Please check the SMS and try again.';
      case 'session-expired':
        return 'Code expired. Please request a new one.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
