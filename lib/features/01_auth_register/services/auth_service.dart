import 'dart:convert';

import 'package:app_frontend/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  /// Manual Signup with Email Verification
  static Future<String?> signup(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return null; // success
    } else {
      throw Exception(data['message'] ?? 'Signup failed');
    }
  }

  /// Manual Signin
  static Future<Map<String, dynamic>> signin(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      return {'user': user, 'token': data['token']};
    } else {
      throw Exception(data['message'] ?? 'Signin failed');
    }
  }

  /// Google Signin
  static Future<Map<String, dynamic>> googleSignin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google-signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      return {'user': user, 'token': data['token']};
    } else {
      throw Exception(data['message'] ?? 'Google Signin failed');
    }
  }

  /// Forgot Password
  static Future<String?> forgotPassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return null;
      } else {
        return data['message'] ??
            data['error'] ??
            'Failed to request password reset';
      }
    } catch (e) {
      return 'Unable to connect to server.';
    }
  }
}
