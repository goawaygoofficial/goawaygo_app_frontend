import 'dart:async';
import 'dart:convert';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/auth/refresh_token_store.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:http/http.dart' as http;

/// Header that makes the backend return the refresh token in the response body (web gets an HttpOnly cookie).
const clientTypeHeader = {'X-Client-Type': 'mobile'};

/// Requests to the backend give up after this long, so a dead network never hangs the app.
const requestTimeout = Duration(seconds: 15);

/// The signed-in session.
///
/// - The **access token** (20 min) lives only in memory.
/// - The **refresh token** (30 days) lives in the platform's encrypted store ([RefreshTokenStore]).
/// - Refresh tokens rotate on every use and the backend treats reuse of an old one as theft (it signs the user
///   out). So refreshes never overlap: concurrent callers share one request.
class AuthSession {
  AuthSession({
    required this._client,
    required this._store,
    required this._baseUrl,
  });

  final http.Client _client;
  final RefreshTokenStore _store;
  final String _baseUrl;
  final _listeners = <void Function(UserModel? user)>[];

  String? _accessToken;
  Future<UserModel?>? _inFlightRefresh;

  String? get accessToken => _accessToken;

  /// Called with the user on sign-in or refresh, and with `null` when the session ends.
  void Function() addListener(void Function(UserModel? user) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  /// Validates a sign-in / refresh response body, stores its tokens and returns the user.
  Future<UserModel> start(Object? body) async {
    if (body is! Map<String, dynamic> ||
        body['user'] is! Map<String, dynamic> ||
        body['accessToken'] is! String ||
        body['refreshToken'] is! String) {
      throw const ApiException('Unexpected response from the server.', 200);
    }
    final user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
    await _store.write(body['refreshToken'] as String);
    _accessToken = body['accessToken'] as String;
    _notify(user);
    return user;
  }

  /// Ends the session on this device. Does not call the server; see `AuthService.signOut`.
  Future<void> end() async {
    _accessToken = null;
    await _store.clear();
    _notify(null);
  }

  /// The stored refresh token, for revoking it on sign-out.
  Future<String?> storedRefreshToken() => _store.read();

  /// Exchanges the stored refresh token for new tokens.
  ///
  /// Resolves `null` when there is no valid session (nothing stored, or the backend rejected it: signed out).
  /// Throws [ApiException.unreachable] when offline, so a network blip does not sign anyone out.
  Future<UserModel?> refresh() {
    return _inFlightRefresh ??= _doRefresh().whenComplete(
      () => _inFlightRefresh = null,
    );
  }

  Future<UserModel?> _doRefresh() async {
    final refreshToken = await _store.read();
    if (refreshToken == null) return null;

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/api/auth/refresh'),
            headers: {'Content-Type': 'application/json', ...clientTypeHeader},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(requestTimeout);
    } on Exception {
      throw ApiException.unreachable;
    }

    if (response.statusCode == 401) {
      await end();
      return null;
    }
    if (response.statusCode != 200) {
      throw ApiException(
        'Could not restore your session.',
        response.statusCode,
      );
    }
    return start(jsonDecode(response.body));
  }

  void _notify(UserModel? user) {
    for (final listener in List.of(_listeners)) {
      listener(user);
    }
  }
}
