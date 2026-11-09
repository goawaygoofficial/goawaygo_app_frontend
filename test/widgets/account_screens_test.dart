import 'dart:convert';

import 'package:app_frontend/features/09_profile/screens/recently_viewed_screen.dart';
import 'package:app_frontend/features/09_profile/screens/user_profile.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/account_test.dart' show accountJson;
import '../helpers/fake_backend.dart';
import 'book_results_test.dart' show pumpOnPhone;

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    SharedPreferences.setMockInitialValues({});
    backend.on('GET', '/api/regions', (_) async {
      return FakeBackend.json({
        'countries': [
          {'code': 'IN', 'name': 'India', 'currency': 'INR'},
          {'code': 'JP', 'name': 'Japan', 'currency': 'JPY'},
        ],
        'currencies': [
          {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
          {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
        ],
      });
    });
  });

  /// A signed-in user, restored from a fake refresh token.
  Future<UserProvider> signedIn(WidgetTester tester) async {
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
    return user;
  }

  Future<void> pumpProfile(WidgetTester tester, UserProvider user) {
    return pumpOnPhone(
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
  }

  testWidgets(
    'the account rows show the settings and the name is changed in a sheet',
    (tester) async {
      Object? saved;
      backend.on('PUT', '/api/users/me', (request) async {
        saved = jsonDecode(request.body);
        return FakeBackend.json(accountJson(name: 'Asha Rao'));
      });
      final user = await signedIn(tester);
      await pumpProfile(tester, user);

      expect(find.text('India'), findsOneWidget);
      expect(find.text('INR'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Delete account'), 200);
      expect(find.text('Delete account'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Display Name'), -200);

      await tester.tap(find.byKey(const ValueKey('edit-Display Name')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Asha Rao');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, {'name': 'Asha Rao', 'country': 'IN', 'currency': 'INR'});
      expect(find.text('Name saved. Wanderbook shows it too.'), findsOneWidget);
      expect(find.text('Asha Rao'), findsOneWidget);
    },
  );

  testWidgets('picking a country saves it and shows its name', (tester) async {
    Object? saved;
    backend.on('PUT', '/api/users/me', (request) async {
      saved = jsonDecode(request.body);
      return FakeBackend.json(accountJson(country: 'JP'));
    });
    final user = await signedIn(tester);
    await pumpProfile(tester, user);

    await tester.tap(find.byKey(const ValueKey('edit-Country / Region')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japan'));
    await tester.pumpAndSettle();

    expect(saved, {'name': 'Asha', 'country': 'JP', 'currency': 'INR'});
    expect(find.text('Country saved.'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
  });

  testWidgets('a new email needs the password and waits for its link', (
    tester,
  ) async {
    backend.on('POST', '/api/auth/change-email', (request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['password'] != 'secret123') {
        return FakeBackend.error(
          400,
          'wrong_password',
          "That password isn't right.",
        );
      }
      return FakeBackend.json(
        accountJson(pendingEmail: body['newEmail'] as String),
      );
    });
    final user = await signedIn(tester);
    await pumpProfile(tester, user);

    await tester.tap(find.byKey(const ValueKey('edit-Email')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'asha.new@example.com');
    await tester.enterText(fields.at(1), 'wrong');
    await tester.tap(find.text('Send confirmation link'));
    await tester.pumpAndSettle();
    expect(find.text("⚠ That password isn't right."), findsOneWidget);

    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Send confirmation link'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'We sent a link to asha.new@example.com. Your email changes when you open it.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Waiting for you to open the link sent to asha.new@example.com.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting asks to confirm, then signs out with the date', (
    tester,
  ) async {
    Object? sent;
    backend.on('POST', '/api/auth/delete-account', (request) async {
      sent = jsonDecode(request.body);
      return FakeBackend.json({'deleteOn': '2026-12-09T10:00:00Z'});
    });
    final user = await signedIn(tester);
    await pumpProfile(tester, user);

    await tester.scrollUntilVisible(find.text('Delete account'), 200);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Delete my account'));
    // The button's spinner turns while the dialog asks, so pump rather than settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.textContaining('You can still keep it by signing in within 30 days'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(sent, {'password': 'secret123'});
    expect(backend.store.token, isNull);
    expect(user.user, isNull);
    expect(
      find.text(
        'Your account will be deleted on 9 December 2026. Sign in before then to keep it.',
      ),
      findsOneWidget,
    );
    // Let the success dialog close itself.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('recently viewed lists places and plans, and clears them', (
    tester,
  ) async {
    backend.on('GET', '/api/me/recently-viewed', (_) async {
      return FakeBackend.json({
        'places': [
          {
            'place': {
              'id': 'p1',
              'name': 'Jaipur',
              'type': 'city',
              'country': 'India',
              'lat': 26.9,
              'lon': 75.8,
              'label': 'Jaipur, Rajasthan, India',
            },
            'viewedAt': DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toUtc()
                .toIso8601String(),
          },
        ],
        'plans': [
          {
            'id': 'abc123def456',
            'title': 'Goa in 3 days',
            'placeName': 'Goa',
            'country': 'India',
            'mine': true,
          },
          {
            'id': 'fff123def456',
            'title': 'Paris for food lovers',
            'placeName': 'Paris',
            'country': 'France',
            'mine': false,
          },
        ],
      });
    });
    backend.on(
      'DELETE',
      '/api/me/recently-viewed',
      (_) async => FakeBackend.json('', 204),
    );

    await pumpOnPhone(tester, const RecentlyViewedScreen());

    expect(find.text('Jaipur, Rajasthan, India'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Goa in 3 days'), findsOneWidget);
    expect(find.text('Your plan'), findsOneWidget);
    expect(find.text('Shared with you'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear list'));
    await tester.tap(find.text('Clear list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(backend.count('DELETE', '/api/me/recently-viewed'), 1);
    expect(find.text('Nothing yet'), findsOneWidget);
  });
}
