import 'dart:convert';

import 'package:app_frontend/core/auth/refresh_token_store.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Keeps the refresh token in memory instead of the platform's secure storage.
class InMemoryRefreshTokenStore implements RefreshTokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

/// A scriptable stand-in for the Goaway backend that records every request.
class FakeBackend {
  FakeBackend() {
    Backend.configure(
      client: MockClient(_handle),
      store: store,
      baseUrl: 'http://backend.test',
    );
  }

  final store = InMemoryRefreshTokenStore();
  final requests = <http.Request>[];
  final _routes = <String, Future<http.Response> Function(http.Request)>{};

  /// Responds to `METHOD /path`.
  void on(
    String method,
    String path,
    Future<http.Response> Function(http.Request request) handler,
  ) {
    _routes['$method $path'] = handler;
  }

  int count(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == path).length;

  Future<http.Response> _handle(http.Request request) {
    requests.add(request);
    final handler = _routes['${request.method} ${request.url.path}'];
    if (handler == null) {
      return Future.value(http.Response('{"error":"not_found"}', 404));
    }
    return handler(request);
  }

  static Map<String, Object?> userJson({int id = 7}) => {
    'id': id,
    'name': 'Asha',
    'email': 'asha@example.com',
    'profile_picture': null,
    'phone': null,
    'email_verified': true,
  };

  /// A sign-in / refresh body as the backend sends it to mobile clients.
  static http.Response session({
    required String accessToken,
    required String refreshToken,
  }) => json({
    'user': userJson(),
    'accessToken': accessToken,
    'tokenType': 'Bearer',
    'expiresIn': 1200,
    'refreshToken': refreshToken,
  });

  static http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  static http.Response error(int status, String code, String message) =>
      json({'status': status, 'error': code, 'message': message}, status);
}
