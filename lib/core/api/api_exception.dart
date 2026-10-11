/// A failed API call. [message] is safe to show to the user.
///
/// [statusCode] is 0 when the server could not be reached. [code] is the backend's machine-readable `error`
/// value (e.g. `invalid_credentials`) when it sent one.
class ApiException implements Exception {
  const ApiException(this.message, this.statusCode, [this.code]);

  static const unreachable = ApiException('Unable to connect to server.', 0);

  final String message;
  final int statusCode;
  final String? code;

  @override
  String toString() => message;
}
