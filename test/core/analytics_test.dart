import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('events carry only fixed, non-personal properties', () {
    expect(const SignUpCompleted().name, 'sign_up_completed');
    expect(SignInCompleted(google: true).properties, {'method': 'google'});
    expect(SignInCompleted(google: false).properties, {'method': 'email'});
    expect(TravelCategoryOpened(TravelCategory.stays).properties, {
      'category': 'stays',
    });
    expect(const DestinationSearched().properties, isEmpty);
  });

  test(
    'builds without a PostHog key have no analytics and never ask',
    () async {
      dotenv.loadFromString(envString: 'BASE_URL=http://localhost:8080');
      expect(Analytics.available, isFalse);
      await Analytics.init();
      expect(Analytics.consent.value, isNull);
      // Tracking without consent is a no-op (and must not throw).
      Analytics.track(const DestinationSearched());
    },
  );
}
