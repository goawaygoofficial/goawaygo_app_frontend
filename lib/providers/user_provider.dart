import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/services/user_service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  /// Set user and persist locally
  void setUser(UserModel user) {
    _user = user;
    UserService.saveUserToPrefs(user);
    notifyListeners();
  }

  /// Clear user both locally and from state
  Future<void> clearUser() async {
    _user = null;
    await UserService.clearUserFromPrefs();
    notifyListeners();
  }

  /// Load user from prefs and validate with backend
  Future<void> loadUserFromPrefs() async {
    final localUser = await UserService.loadUserFromPrefs();
    if (localUser != null) {
      final isValid = await UserService.verifyUserFromBackend(localUser.id);
      if (isValid) {
        _user = localUser;
      } else {
        await UserService.clearUserFromPrefs();
        _user = null;
      }
    }
    notifyListeners();
  }
}
