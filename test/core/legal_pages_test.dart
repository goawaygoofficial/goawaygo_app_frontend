import 'package:app_frontend/core/legal/legal_pages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legal pages point at the website routes', () {
    expect(
      LegalPage.privacy.uri('https://staging.goawaygo.com/').toString(),
      'https://staging.goawaygo.com/privacy',
    );
    expect(
      LegalPage.terms.uri('https://goawaygo.com').toString(),
      'https://goawaygo.com/terms',
    );
    expect(
      LegalPage.deleteMyData.uri('https://goawaygo.com').toString(),
      'https://goawaygo.com/delete-my-data',
    );
  });

  test('no website configured gives no address', () {
    expect(LegalPage.privacy.uri('  '), isNull);
  });
}
