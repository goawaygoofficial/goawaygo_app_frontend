import 'dart:convert';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/auth/auth_session.dart';
import 'package:http/http.dart' as http;

/// The one place the app talks to the backend.
///
/// Sends the access token when signed in. If the server answers 401 to an authenticated request (the 20-minute
/// token expired), it refreshes the session once and retries; if that fails, the session ends.
class ApiClient {
  ApiClient({
    required this._client,
    required this._session,
    required this._baseUrl,
  });

  final http.Client _client;
  final AuthSession _session;
  final String _baseUrl;

  /// Sends a JSON request and returns the decoded body (`null` for an empty body).
  ///
  /// Throws [ApiException] with the backend's message on failure, or [ApiException.unreachable] when offline.
  /// [timeout] is for the rare slow call (a destination page waits for the AI); the default suits the rest.
  Future<Object?> request(
    String method,
    String path, {
    Object? body,
    int? expectedStatus,
    required String fallbackError,
    Duration timeout = requestTimeout,
  }) async {
    final token = _session.accessToken;
    var response = await _send(method, path, body, token, timeout);

    if (response.statusCode == 401 && token != null) {
      final refreshed = await _session.refresh().catchError((Object _) => null);
      if (refreshed != null) {
        response = await _send(
          method,
          path,
          body,
          _session.accessToken,
          timeout,
        );
      } else {
        await _session.end();
      }
    }

    final data = _decode(response.body);
    final ok = expectedStatus == null
        ? response.statusCode >= 200 && response.statusCode < 300
        : response.statusCode == expectedStatus;
    if (!ok) {
      throw ApiException(
        _errorMessage(data, fallbackError),
        response.statusCode,
        _errorCode(data),
      );
    }
    return data;
  }

  Future<http.Response> _send(
    String method,
    String path,
    Object? body,
    String? token,
    Duration timeout,
  ) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll({
        ...clientTypeHeader,
        if (body != null) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);
    try {
      return await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
    } on Exception {
      throw ApiException.unreachable;
    }
  }

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  /// The single place error messages are read from a response body: message → error → fallback.
  static String _errorMessage(Object? data, String fallback) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return fallback;
  }

  static String? _errorCode(Object? data) =>
      data is Map<String, dynamic> && data['error'] is String
      ? data['error'] as String
      : null;
}
