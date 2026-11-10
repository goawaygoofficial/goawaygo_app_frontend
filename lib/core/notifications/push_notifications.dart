import 'package:app_frontend/core/i18n/i18n.dart';

import 'dart:io' show Platform;

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/notifications/notification_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When the app asks for permission to send push notifications (decided for 4.5): once right after sign-in; if
/// that was dismissed, once more at a useful moment (after following someone, posting or saving a trip plan); and
/// always from the switch in Notification settings.
class PushPrompts {
  PushPrompts._();

  static const _askedKey = 'push_asked_after_sign_in';
  static const _askedAgainKey = 'push_asked_again';

  static Future<bool> shouldAskAfterSignIn() async =>
      !((await SharedPreferences.getInstance()).getBool(_askedKey) ?? false);

  static Future<void> markAsked() async =>
      (await SharedPreferences.getInstance()).setBool(_askedKey, true);

  /// True once: after the first ask, when push is still off.
  static Future<bool> shouldAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_askedKey) ?? false) &&
        !(prefs.getBool(_askedAgainKey) ?? false);
  }

  static Future<void> markAskedAgain() async =>
      (await SharedPreferences.getInstance()).setBool(_askedAgainKey, true);
}

/// Push notifications through Firebase Cloud Messaging (Android). Firebase starts from the public IDs in the env
/// file and the API key the release script passes (`FIREBASE_ANDROID_API_KEY`); builds without it (local runs, CI,
/// tests) simply have no push, and everything else works. The backend sends the pushes; this registers the phone's
/// token for the signed-in user and tells Home which notification was tapped.
class PushNotifications {
  PushNotifications._();

  static const _apiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const _settings = MethodChannel('goawaygo/notifications');

  static bool _started = false;
  static bool _signedIn = false;
  static String? _token;

  /// The data of the push the user tapped (type, postId, profileId, planId); Home opens it and clears this.
  static final opened = ValueNotifier<Map<String, dynamic>?>(null);

  /// Whether this build can receive pushes at all.
  static bool get available => _started;

  static Future<void> init() async {
    final appId = dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final senderId = dotenv.env['FIREBASE_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    if (kIsWeb ||
        !Platform.isAndroid ||
        _apiKey.isEmpty ||
        appId.isEmpty ||
        senderId.isEmpty) {
      return;
    }
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: _apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
        ),
      );
    } on Exception catch (error) {
      debugPrint('Push notifications off: $error');
      return;
    }
    _started = true;
    final messaging = FirebaseMessaging.instance;
    // In the foreground Android shows nothing: update the badge instead.
    FirebaseMessaging.onMessage.listen(
      (_) => NotificationService.refreshUnread(),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => opened.value = message.data,
    );
    final initial = await messaging.getInitialMessage();
    if (initial != null) opened.value = initial.data;
    // The registration token is what the backend sends to (FCM HTTP v1 `message.token`). firebase_messaging 17
    // marks it deprecated in favour of installation IDs (register/onRegistered); switch both sides together.
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((token) {
      _token = token;
      if (_signedIn) _register();
    });
  }

  /// After sign-in (or a restored session): asks for permission the first time, and registers this phone.
  static Future<void> onSignedIn() async {
    _signedIn = true;
    if (!_started) return;
    if (await PushPrompts.shouldAskAfterSignIn()) {
      await PushPrompts.markAsked();
      await requestPermission();
    }
    await _register();
  }

  /// Before signing out, while still signed in: this phone stops getting the account's pushes.
  static Future<void> onSigningOut() async {
    _signedIn = false;
    final token = _token;
    if (!_started || token == null) return;
    try {
      await NotificationService.removeDevice(token);
    } on ApiException {
      // Offline: the backend forgets the token when Firebase reports it gone, or the next sign-in takes it over.
    }
  }

  static Future<void> _register() async {
    try {
      // ignore: deprecated_member_use
      _token ??= await FirebaseMessaging.instance.getToken();
      final token = _token;
      if (token != null) await NotificationService.registerDevice(token);
    } on Exception catch (error) {
      debugPrint('Push token not registered: $error');
    }
  }

  /// Whether the phone lets the app show notifications.
  static Future<bool> allowed() async {
    if (!_started) return false;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Shows Android's permission prompt (Android 13+; older phones allow by default). After two refusals Android
  /// stops showing it: then only [openSettings] helps.
  static Future<bool> requestPermission() async {
    if (!_started) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Opens this app's page in the phone's notification settings.
  static Future<void> openSettings() async {
    try {
      await _settings.invokeMethod<void>('openSettings');
    } on PlatformException catch (error) {
      debugPrint('Could not open notification settings: $error');
    }
  }

  /// The second ask, once, after something push is useful for ([reason]: what the user would hear about).
  static Future<void> askAtUsefulMoment(
    BuildContext context,
    String reason,
  ) async {
    if (!_started || await allowed() || !await PushPrompts.shouldAskAgain()) {
      return;
    }
    await PushPrompts.markAskedAgain();
    if (!context.mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsUtil.primary,
        title: Text(
          tr('Turn on notifications?'),
          style: TextStyle(color: ColorsUtil.whiteColor),
        ),
        content: Text(
          reason,
          style: const TextStyle(color: ColorsUtil.whiteColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              tr('Not now'),
              style: TextStyle(color: ColorsUtil.whiteColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              tr('Allow'),
              style: TextStyle(
                color: ColorsUtil.secondaryLighter,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (yes == true) await requestPermission();
  }
}
