import 'package:app_frontend/core/i18n/i18n.dart';

/// A failed API call. [message] is safe to show to the user, in the app's language: the backend's messages arrive
/// translated; the app's own (English sentences) are translated here.
///
/// [statusCode] is 0 when the server could not be reached. [code] is the backend's machine-readable `error`
/// value (e.g. `invalid_credentials`) when it sent one.
class ApiException implements Exception {
  const ApiException(this._message, this.statusCode, [this.code]);

  static const unreachable = ApiException('Unable to connect to server.', 0);

  final String _message;
  final int statusCode;

  String get message => tr(_message);

  final String? code;

  @override
  String toString() => message;
}
