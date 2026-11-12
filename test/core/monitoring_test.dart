import 'package:app_frontend/core/monitoring/monitoring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  test('scrubBreadcrumb cleans both URL keys (sentry_flutter 9 and 10)', () {
    final crumb = Breadcrumb.http(
      url: Uri.parse('https://staging.goawaygo.com/verify-email?token=t1'),
      method: 'GET',
    );
    crumb.data = {
      ...?crumb.data,
      'url.full': 'https://staging.goawaygo.com/reset-password?token=t2',
    };

    final data = scrubBreadcrumb(crumb)!.data!;

    for (final key in ['url', 'url.full']) {
      final value = data[key];
      if (value is String) expect(value, isNot(contains('token=t')));
    }
    expect(data['url.full'], contains('token=[Filtered]'));
    expect(scrubBreadcrumb(null), isNull);
  });
}
