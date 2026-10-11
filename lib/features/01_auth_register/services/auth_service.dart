import 'dart:io' show Platform;

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// What to tell the user when Google Sign-In fails on the device (before anything reaches our backend).
@visibleForTesting
String googleSignInErrorMessage(
  GoogleSignInExceptionCode code,
  String? description,
) {
  // Android's Credential Manager reports "no credential" when the device has no Google account, or when
  // Google Play services is too old to offer Sign in with Google.
  if (description != null &&
      description.toLowerCase().contains('no credential')) {
    return 'No Google account is available on this device. Add one in Settings (and update Google Play '
        'services), or sign in with email.';
  }
  return switch (code) {
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError => 'Google sign-in is not set up for this version of the app. Please sign in with email.',
    GoogleSignInExceptionCode.uiUnavailable =>
      'Google sign-in could not open. Please try again.',
    _ => 'Google sign-in failed. Please try again.',
  };
}

/// Sign-up, sign-in (email and Google), session restore, sign-out and password reset.
class AuthService {
  AuthService._();

  static Future<void>? _googleInit;

  /// Creates an account (201). The user signs in afterwards.
  static Future<void> signup(String name, String email, String password) async {
    await Backend.api.request(
      'POST',
      '/api/auth/signup',
      body: {'name': name, 'email': email, 'password': password},
      expectedStatus: 201,
      fallbackError: 'Signup failed',
    );
  }

  static Future<UserModel> signin(String email, String password) async {
    final data = await Backend.api.request(
      'POST',
      '/api/auth/signin',
      body: {'email': email, 'password': password},
      expectedStatus: 200,
      fallbackError: 'Signin failed',
    );
    return Backend.session.start(data);
  }

  /// Google Sign-In. Returns `null` if the user cancelled.
  ///
  /// Google issues the ID token for our **Web** client (`serverClientId`), which is the audience the backend
  /// accepts. The backend verifies it with Google's keys; nothing else from Google is sent or trusted.
  static Future<UserModel?> googleSignin() async {
    await (_googleInit ??= _initializeGoogle());
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google Sign-In failed: ${e.code} ${e.description}');
      throw ApiException(
        googleSignInErrorMessage(e.code, e.description),
        0,
        'google_sign_in_failed',
      );
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const ApiException(
        'Google sign-in failed. Please try again.',
        0,
        'google_sign_in_failed',
      );
    }
    final data = await Backend.api.request(
      'POST',
      '/api/auth/google-signin',
      body: {'idToken': idToken},
      expectedStatus: 200,
      fallbackError: 'Google Signin failed',
    );
    return Backend.session.start(data);
  }

  static Future<void> _initializeGoogle() {
    return GoogleSignIn.instance.initialize(
      // iOS identifies the app with its own client; Android uses the package name + signing certificate.
      clientId: !kIsWeb && Platform.isIOS
          ? dotenv.env['GOOGLE_IOS_CLIENT_ID']
          : null,
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
  }

  /// Restores the session at startup from the stored refresh token.
  /// Returns `null` when signed out or when the server can't be reached.
  static Future<UserModel?> restoreSession() async {
    try {
      return await Backend.session.refresh();
    } on ApiException {
      return null;
    }
  }

  /// Revokes the session on the server, then ends it on this device, even if the server can't be reached.
  static Future<void> signOut() async {
    try {
      final refreshToken = await Backend.session.storedRefreshToken();
      if (refreshToken != null) {
        await Backend.api.request(
          'POST',
          '/api/auth/logout',
          body: {'refreshToken': refreshToken},
          expectedStatus: 204,
          fallbackError: 'Sign out failed',
        );
      }
    } on ApiException {
      // Still sign out locally; the server-side token expires on its own.
    } finally {
      await Backend.session.end();
    }
    if (_googleInit != null) {
      // So the account chooser appears next time instead of silently reusing the last Google account.
      await GoogleSignIn.instance.signOut().catchError((Object _) {});
    }
  }

  /// Asks for a password-reset link by email. The answer never reveals whether the account exists.
  static Future<void> requestPasswordReset(String email) async {
    await Backend.api.request(
      'POST',
      '/api/auth/forgot-password',
      body: {'email': email},
      fallbackError: 'Failed to request password reset',
    );
  }

  /// Emails the signed-in user a new link to verify their email. The link opens the website.
  static Future<void> resendVerificationEmail() async {
    await Backend.api.request(
      'POST',
      '/api/auth/resend-verification',
      expectedStatus: 202,
      fallbackError: 'Failed to send verification email',
    );
  }

  /// The signed-in user, fresh from the server (e.g. after the email was verified on the website).
  static Future<UserModel> fetchCurrentUser() async {
    final data = await Backend.api.request(
      'GET',
      '/api/users/me',
      fallbackError: 'Failed to load profile',
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from server.', 200);
    }
    return UserModel.fromJson(data);
  }
}
