import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the signed-in user. Nothing about the user is stored on the device: at startup the session is
/// restored from the refresh token in secure storage, which also proves the user is still allowed in.
class UserProvider extends ChangeNotifier {
  UserProvider() {
    // Follow background refreshes, and sign out if the session expires.
    _removeSessionListener = Backend.session.addListener((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Key used by older versions, which stored the user object in SharedPreferences.
  static const _legacyUserKey = 'user';

  late final void Function() _removeSessionListener;
  UserModel? _user;

  UserModel? get user => _user;

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
    await AuthService.signOut();
    _user = null;
    notifyListeners();
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
