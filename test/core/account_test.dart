import 'dart:convert';

import 'package:app_frontend/core/account/account_models.dart';
import 'package:app_frontend/core/account/account_service.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> accountJson({
  String name = 'Asha',
  String? country = 'IN',
  String? currency = 'INR',
  bool hasPassword = true,
  String? pendingEmail,
}) => {
  ...FakeBackend.userJson(),
  'name': name,
  'country': country,
  'currency': currency,
  'has_password': hasPassword,
  'google_linked': !hasPassword,
  'pending_email': pendingEmail,
};

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  test(
    'the user carries the account settings; older backends mean a password',
    () {
      final user = UserModel.fromJson(
        accountJson(hasPassword: false, pendingEmail: 'new@example.com'),
      );
      expect(user.country, 'IN');
      expect(user.currency, 'INR');
      expect(user.hasPassword, isFalse);
      expect(user.googleLinked, isTrue);
      expect(user.pendingEmail, 'new@example.com');

      final old = UserModel.fromJson(FakeBackend.userJson());
      expect(old.hasPassword, isTrue);
      expect(old.country, isNull);
    },
  );

  test(
    'details and the email change go to the backend with the proof',
    () async {
      Object? details;
      Object? email;
      backend.on('PUT', '/api/users/me', (request) async {
        details = jsonDecode(request.body);
        return FakeBackend.json(accountJson(name: 'Asha Rao', country: 'JP'));
      });
      backend.on('POST', '/api/auth/change-email', (request) async {
        email = jsonDecode(request.body);
        return FakeBackend.json(
          accountJson(pendingEmail: 'asha.new@example.com'),
        );
      });

      final saved = await AccountService.updateDetails(
        name: 'Asha Rao',
        country: 'JP',
        currency: 'INR',
      );
      final changed = await AccountService.changeEmail(
        const Proof.google('google-token'),
        'asha.new@example.com',
      );

      expect(details, {'name': 'Asha Rao', 'country': 'JP', 'currency': 'INR'});
      expect(saved.country, 'JP');
      expect(email, {
        'googleIdToken': 'google-token',
        'newEmail': 'asha.new@example.com',
      });
      expect(changed.pendingEmail, 'asha.new@example.com');
    },
  );

  test('a new password comes with a new session for this phone', () async {
    backend.store.token = 'old-refresh';
    Object? sent;
    backend.on('POST', '/api/auth/change-password', (request) async {
      sent = jsonDecode(request.body);
      return FakeBackend.session(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );
    });

    await AccountService.changePassword(
      const Proof.password('old secret'),
      'a new secret',
    );

    expect(sent, {'password': 'old secret', 'newPassword': 'a new secret'});
    expect(backend.store.token, 'new-refresh');
    expect(Backend.session.accessToken, 'new-access');
  });

  test('a wrong password is the backend message', () async {
    backend.on('POST', '/api/auth/change-password', (_) async {
      return FakeBackend.error(
        400,
        'wrong_password',
        "That password isn't right.",
      );
    });

    expect(
      () => AccountService.changePassword(
        const Proof.password('nope'),
        'a new secret',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          "That password isn't right.",
        ),
      ),
    );
  });

  test('deleting ends the session on this phone and gives the date', () async {
    backend.store.token = 'refresh-1';
    backend.on('POST', '/api/auth/delete-account', (_) async {
      return FakeBackend.json({'deleteOn': '2026-12-09T10:00:00Z'});
    });

    final deleteOn = await AccountService.deleteAccount(
      const Proof.password('secret'),
    );

    expect(deleteOn, DateTime.utc(2026, 12, 9, 10));
    expect(backend.store.token, isNull);
  });

  test('signing in again within 30 days says the account was kept', () async {
    await Backend.session.start({
      'user': FakeBackend.userJson(),
      'accessToken': 'a',
      'refreshToken': 'r',
      'accountRestored': true,
    });
    expect(Backend.session.restoredOnLastStart, isTrue);

    await Backend.session.start({
      'user': FakeBackend.userJson(),
      'accessToken': 'a',
      'refreshToken': 'r',
    });
    expect(Backend.session.restoredOnLastStart, isFalse);
  });

  test('regions and recently viewed are read safely', () async {
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
            'viewedAt': '2026-11-09T10:00:00Z',
          },
          {'place': 'broken'},
        ],
        'plans': [
          {
            'id': 'abc123def456',
            'title': 'Goa in 3 days',
            'placeName': 'Goa',
            'country': 'India',
            'mine': true,
          },
          {'id': 1},
        ],
      });
    });

    final viewed = await AccountService.recentlyViewed();
    final regions = Regions.fromJson({
      'countries': [
        {'code': 'IN', 'name': 'India', 'currency': 'INR'},
        {'code': 'AQ', 'name': 'Antarctica', 'currency': null},
      ],
      'currencies': [
        {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
        {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
      ],
    });

    expect(viewed.places.single.place.name, 'Jaipur');
    expect(viewed.places.single.viewedAt, DateTime.utc(2026, 11, 9, 10));
    expect(viewed.plans.single.mine, isTrue);
    expect(regions.countryName('IN'), 'India');
    expect(regions.countries.last.currency, isNull);
    expect(regions.currencies.first.label, 'INR · Indian Rupee (₹)');
    expect(regions.currencies.last.label, 'CHF · Swiss Franc');
  });
}
