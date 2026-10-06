import 'dart:convert';
import 'package:app_frontend/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  static const _prefsKey = 'user';
  static final String baseUrl = dotenv.env['BASE_URL']!;

  /// Save user locally
  static Future<void> saveUserToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(user.toJson()));
  }

  /// Load user from SharedPreferences
  static Future<UserModel?> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_prefsKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  /// Remove user from prefs
  static Future<void> clearUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Verify user with backend
  static Future<bool> verifyUserFromBackend(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/users/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data != null && data['id'] == userId;
      }
    } catch (e) {
      // Log error
    }
    return false;
  }
}
