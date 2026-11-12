import 'package:app_frontend/core/account/account_service.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/features/01_auth_register/screens/auth_screen.dart';
import 'package:app_frontend/features/01_auth_register/screens/forgot_password_screen.dart';
import 'package:app_frontend/features/01_auth_register/screens/register_screen.dart';
import 'package:app_frontend/features/03_flights/screens/flight_results_screen.dart';
import 'package:app_frontend/features/03_flights/screens/flight_search_screen.dart';
import 'package:app_frontend/features/04_hotels/screens/hotels_search_screen.dart';
import 'package:app_frontend/features/05_rentals/screens/rentals_search_screen.dart';
import 'package:app_frontend/features/09_profile/screens/my_profile.dart';
import 'package:app_frontend/features/09_profile/screens/user_profile.dart';
import 'package:app_frontend/features/11_notifications/screens/notifications_screen.dart';
import 'package:app_frontend/providers/language_provider.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/account_test.dart' show accountJson;
import '../core/book_test.dart' show delhi, fareJson, mumbai;
import '../helpers/fake_backend.dart';
import 'book_results_test.dart' show pumpOnPhone;

/// WCAG 2.2 AA in the app (4.7): text contrast (1.4.3), tap targets of 48 x 48 (2.5.8, Android's own size), and a
/// label on everything that can be tapped (4.1.2), on the main screens.
Future<void> expectAccessible(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    AccountService.resetCache();
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'BASE_URL=http://localhost:8080');
  });

  /// Signed out, inside a Scaffold like Home's overlays (the search screens open over Home).
  Widget signedOut(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: Scaffold(backgroundColor: const Color(0xFF004AAD), body: child),
  );

  final screens = <String, Widget Function()>{
    'Sign in': () => signedOut(const AuthScreen()),
    'Profile tab, signed out': () =>
        signedOut(MyProfile(toggleBottomBar: (_) {}, onOpenTrips: () {})),
    'Register': () => signedOut(RegisterScreen(onBack: () {})),
    'Forgot Password': () => signedOut(ForgotPasswordScreen(onBack: () {})),
    'Flights search': () => signedOut(FlightSearchScreen(onClose: () {})),
    'Stays search': () => signedOut(HotelsSearchScreen(onClose: () {})),
    'Car rentals search': () => signedOut(RentalsSearchScreen(onClose: () {})),
    'Notifications, signed out': () => signedOut(const NotificationsScreen()),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} meets WCAG 2.2 AA', (tester) async {
      await pumpOnPhone(tester, entry.value());
      await expectAccessible(tester);
    });
  }

  testWidgets('Flight results meet WCAG 2.2 AA', (tester) async {
    backend.on('GET', '/api/book/flights', (_) async {
      return FakeBackend.json({
        'priceKind': 'recent',
        'currency': 'INR',
        'onDate': [fareJson()],
        'nearby': [fareJson(price: 6630, day: '2026-12-01')],
        'searchLink': 'https://tp.media/r?u=search',
      });
    });
    await pumpOnPhone(
      tester,
      const FlightResultsScreen(
        search: FlightSearch(from: delhi, to: mumbai, depart: '2026-12-07'),
      ),
    );
    await expectAccessible(tester);
  });

  testWidgets('User Profile, signed in, meets WCAG 2.2 AA', (tester) async {
    backend.on('GET', '/api/regions', (_) async {
      return FakeBackend.json({
        'countries': [
          {'code': 'IN', 'name': 'India', 'currency': 'INR'},
        ],
        'currencies': [
          {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
        ],
      });
    });
    backend.store.token = 'refresh-1';
    backend.on('POST', '/api/auth/refresh', (_) async {
      return FakeBackend.json({
        'user': accountJson(),
        'accessToken': 'a',
        'tokenType': 'Bearer',
        'expiresIn': 1200,
        'refreshToken': 'refresh-2',
      });
    });
    final user = UserProvider();
    await tester.runAsync(user.restoreSession);
    await pumpOnPhone(
      tester,
      ChangeNotifierProvider.value(
        value: user,
        child: Builder(
          builder: (context) => UserProfilePage(
            user: context.watch<UserProvider>().user,
            onClose: () {},
          ),
        ),
      ),
    );
    await expectAccessible(tester);
  });
}
