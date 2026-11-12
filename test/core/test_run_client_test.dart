import 'package:app_frontend/core/api/test_run_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('adds the test header to backend requests only', () async {
    final seen = <String, String?>{};
    final inner = MockClient((request) async {
      seen[request.url.host] = request.headers[TestRunClient.header];
      return http.Response('{}', 200);
    });
    final client = TestRunClient(
      inner,
      'test-token',
      'https://api-dev.goawaygo.com',
    );

    await client.get(Uri.parse('https://api-dev.goawaygo.com/api/users/me'));
    await client.get(Uri.parse('https://example.com/image.jpg'));

    expect(seen['api-dev.goawaygo.com'], 'test-token');
    expect(seen['example.com'], isNull);
  });
}
