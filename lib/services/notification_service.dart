import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler — must be a top-level function (not a class method)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App is in background or terminated — FCM shows the notification automatically
  // on Android if the notification payload is set. Nothing extra needed here.
}

// ─────────────────────────────────────────────────────────────────────────────
// Android notification channel + local notifications plugin
// ─────────────────────────────────────────────────────────────────────────────

const _kChannelId = 'ishbor_messages';
const _kChannelName = 'Ishbor xabarlari';
const _kChannelDesc = 'Chat xabarlari va bildirishnomalar';

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

// Published so main.dart can call it before runApp.
const AndroidNotificationChannel kMessagingChannel = AndroidNotificationChannel(
  _kChannelId,
  _kChannelName,
  description: _kChannelDesc,
  importance: Importance.high,
);

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  static final _fm = FirebaseMessaging.instance;

  // Callback set by main.dart / NavigatorState — called when notification tapped.
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Call once from main() after Firebase.initializeApp.
  static Future<void> init() async {
    // Register background handler before anything else
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Web: FCM is handled differently — tokens via getToken(vapidKey)
    if (!kIsWeb) {
      // Create Android notification channel
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(kMessagingChannel);
    }

    // Initialise local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );

    // Android 13+ uchun POST_NOTIFICATIONS ruxsatini so'rash
    if (!kIsWeb) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Request permission (iOS / Web — Android 13+ also needs this at runtime)
    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages: show a local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Notification tapped while app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data.isNotEmpty) {
        onNotificationTap?.call(message.data);
      }
    });
  }

  /// Save the FCM token to Firestore so Cloud Functions can send push to this device.
  static Future<void> saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String? token;
    if (kIsWeb) {
      // Web FCM requires the VAPID public key.
      // Steps to get it:
      //   1. Firebase Console → Project Settings → Cloud Messaging tab
      //   2. Scroll to "Web configuration" → "Web Push certificates"
      //   3. Click "Generate key pair" (or use existing) → copy the public key
      //   4. Replace 'YOUR_WEB_VAPID_KEY' below with that value.
      //
      // WARNING: without a real VAPID key, web push notifications will NOT work.
      const vapidKey = 'YOUR_WEB_VAPID_KEY';
      if (vapidKey == 'YOUR_WEB_VAPID_KEY') {
        // ignore: avoid_print
        assert(
            false,
            '[NotificationService] Web VAPID key is not configured. '
            'Go to Firebase Console → Project Settings → Cloud Messaging → Web Push certificates '
            'and replace YOUR_WEB_VAPID_KEY in notification_service.dart.');
        return;
      }
      try {
        token = await _fm.getToken(vapidKey: vapidKey);
      } catch (_) {
        return; // VAPID key invalid or web push not supported — skip silently
      }
    } else {
      token = await _fm.getToken();
    }

    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );

    // Refresh token listener
    _fm.onTokenRefresh.listen((newToken) async {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }

  /// Remove FCM token on logout so the device no longer receives pushes.
  static Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
    await _fm.deleteToken();
  }

  /// Check if the app was launched by tapping a terminated-state notification.
  static Future<Map<String, dynamic>?> getInitialNotificationData() async {
    final msg = await _fm.getInitialMessage();
    if (msg != null && msg.data.isNotEmpty) return msg.data;
    return null;
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static void _showLocalNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    final payload = jsonEncode(message.data);

    _localNotif.show(
      message.hashCode,
      n.title ?? 'Ishbor',
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription: _kChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }
}
