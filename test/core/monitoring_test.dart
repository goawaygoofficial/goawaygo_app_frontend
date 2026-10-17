import 'package:app_frontend/core/monitoring/monitoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scrubUrl removes tokens and OAuth values from URLs', () {
    expect(
      scrubUrl('https://staging.goawaygo.com/reset-password?token=abc123&x=1'),
      'https://staging.goawaygo.com/reset-password?token=[Filtered]&x=1',
    );
    expect(
      scrubUrl('https://x.test/cb?state=s1&code=c2'),
      'https://x.test/cb?state=[Filtered]&code=[Filtered]',
    );
    expect(
      scrubUrl('https://api.goawaygo.com/api/users/me'),
      'https://api.goawaygo.com/api/users/me',
    );
  });
}
