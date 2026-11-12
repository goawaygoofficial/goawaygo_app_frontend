import 'package:http/http.dart' as http;

/// Automated test builds only (MVP 2, 5.5): adds the test header to requests to our own backend, so dev and test answer
/// with fake outside services (AI, places, photos, flights) and test runs use no free quota. The token comes from the
/// test build's `.env` (`TEST_FAKES_TOKEN`); release builds never have one, and the header is never sent to any other
/// host.
class TestRunClient extends http.BaseClient {
  TestRunClient(this._inner, this._token, String baseUrl)
    : _backendHost = Uri.tryParse(baseUrl)?.host ?? '';

  static const header = 'X-GoAwayGo-Test';

  final http.Client _inner;
  final String _token;
  final String _backendHost;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_backendHost.isNotEmpty && request.url.host == _backendHost) {
      request.headers[header] = _token;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
