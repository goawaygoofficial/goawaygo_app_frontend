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
  }) {
    return _call(
      () {
        final request = http.Request(method, Uri.parse('$_baseUrl$path'));
        if (body != null) {
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode(body);
        }
        return request;
      },
      expectedStatus: expectedStatus,
      fallbackError: fallbackError,
      timeout: timeout,
    );
  }

  /// Uploads one file as multipart form field [field] (Wanderbook photos) and returns the decoded answer.
  Future<Object?> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    required String fallbackError,
  }) {
    return _call(
      () => http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
        ..files.add(
          http.MultipartFile.fromBytes(field, bytes, filename: filename),
        ),
      fallbackError: fallbackError,
      // Original photos can be large.
      timeout: const Duration(seconds: 120),
    );
  }

  /// Sends a request made by [build] (built again for the retry: a request can only be sent once).
  Future<Object?> _call(
    http.BaseRequest Function() build, {
    int? expectedStatus,
    required String fallbackError,
    required Duration timeout,
  }) async {
    final token = _session.accessToken;
    var response = await _send(build(), token, timeout);

    if (response.statusCode == 401 && token != null) {
      final refreshed = await _session.refresh().catchError((Object _) => null);
      if (refreshed != null) {
        response = await _send(build(), _session.accessToken, timeout);
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
    http.BaseRequest request,
    String? token,
    Duration timeout,
  ) async {
    request.headers.addAll({
      ...clientTypeHeader,
      if (token != null) 'Authorization': 'Bearer $token',
    });
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
