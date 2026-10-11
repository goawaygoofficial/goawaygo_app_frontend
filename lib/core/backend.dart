import 'package:app_frontend/core/api/api_client.dart';
import 'package:app_frontend/core/auth/auth_session.dart';
import 'package:app_frontend/core/auth/refresh_token_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Wires the session and API client together. [configure] runs once at startup (after `.env` is loaded);
/// tests call it with a fake HTTP client and an in-memory token store.
class Backend {
  Backend._();

  static AuthSession? _session;
  static ApiClient? _api;

  static AuthSession get session =>
      _session ?? (throw StateError('Backend.configure() was not called.'));
  static ApiClient get api =>
      _api ?? (throw StateError('Backend.configure() was not called.'));

  static void configure({
    http.Client? client,
    RefreshTokenStore? store,
    String? baseUrl,
  }) {
    final httpClient = client ?? http.Client();
    final url = (baseUrl ?? dotenv.env['BASE_URL'] ?? '').replaceAll(
      RegExp(r'/+$'),
      '',
    );
    _session = AuthSession(
      client: httpClient,
      store: store ?? const SecureRefreshTokenStore(),
      baseUrl: url,
    );
    _api = ApiClient(client: httpClient, session: _session!, baseUrl: url);
  }
}
