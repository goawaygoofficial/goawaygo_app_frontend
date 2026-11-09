import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/notifications/push_notifications.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the signed-in user. Nothing about the user is stored on the device: at startup the session is
/// restored from the refresh token in secure storage, which also proves the user is still allowed in.
class UserProvider extends ChangeNotifier {
  UserProvider() {
    // Follow background refreshes, and sign out if the session expires.
    _removeSessionListener = Backend.session.addListener((user) {
      // After signing in on a phone set to another language, the account follows the app.
      if (user?.language != null &&
          user!.language != I18n.code &&
          _user?.id != user.id) {
        LanguageProvider.tellAccount();
      }
      _user = user;
      notifyListeners();
    });
  }

  /// Key used by older versions, which stored the user object in SharedPreferences.
  static const _legacyUserKey = 'user';

  late final void Function() _removeSessionListener;
  UserModel? _user;

  UserModel? get user => _user;

  @override
  void notifyListeners() {
    // Prices follow the account's currency while signed in.
    I18n.accountCurrency = _user?.currency;
    super.notifyListeners();
  }

  /// Restores the session at startup. Leaves the user signed out if there is no session or the server is
  /// unreachable.
  Future<void> restoreSession() async {
    await _removeLegacyStoredUser();
    _user = await AuthService.restoreSession();
    notifyListeners();
  }

  /// Call after a successful sign-in (the session itself is already stored by [AuthService]).
  void signIn(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Revokes the session on the server and signs out on this device.
  Future<void> signOut() async {
    // While still signed in: this phone stops getting the account's pushes.
    await PushNotifications.onSigningOut();
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }

  /// Re-reads the signed-in user from the server, e.g. when the app comes back to the foreground after the
  /// email was verified in the browser. Does nothing when signed out; keeps the current user if it fails.
  Future<void> reloadUser() async {
    if (_user == null) return;
    try {
      final fresh = await AuthService.fetchCurrentUser();
      // Ignore the answer if the user signed out while it was loading.
      if (_user == null) return;
      _user = fresh;
      notifyListeners();
    } on ApiException {
      // Offline or session ended (the session listener handles sign-out).
    }
  }

  static Future<void> _removeLegacyStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyUserKey);
  }

  @override
  void dispose() {
    _removeSessionListener();
    super.dispose();
  }
}
