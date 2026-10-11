import 'dart:convert';

import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    // A user object stored by the old version of the app.
    SharedPreferences.setMockInitialValues({
      'user': jsonEncode({'id': 1, 'name': 'Old', 'email': 'old@example.com'}),
    });
  });

  group('UserProvider', () {
    test('starts with no user', () {
      expect(UserProvider().user, isNull);
    });

    test('restoreSession signs in from the stored refresh token and removes the old stored user', () async {
      backend.store.token = 'refresh-1';
      backend.on(
        'POST',
        '/api/auth/refresh',
        (_) async =>
            FakeBackend.session(accessToken: 'a', refreshToken: 'refresh-2'),
      );
      final provider = UserProvider();

      await provider.restoreSession();

      expect(provider.user?.email, 'asha@example.com');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user'), isNull);
    });

    test(
      'restoreSession without a stored token leaves the user signed out',
      () async {
        final provider = UserProvider();

        await provider.restoreSession();

        expect(provider.user, isNull);
      },
    );

    test('signIn sets the user and notifies listeners', () {
      final provider = UserProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.signIn(
        UserModel(id: 42, name: 'Test', email: 'test@example.com'),
      );

      expect(provider.user?.id, 42);
      expect(notified, isTrue);
    });

    test('signOut clears the user and the session', () async {
      backend.store.token = 'refresh-1';
      backend.on(
        'POST',
        '/api/auth/logout',
        (_) async => http.Response('', 204),
      );
      final provider = UserProvider()
        ..signIn(UserModel(id: 42, name: 'Test', email: 'test@example.com'));

      await provider.signOut();

      expect(provider.user, isNull);
      expect(backend.store.token, isNull);
    });

    test('an expired session signs the user out in the background', () async {
      final provider = UserProvider()
        ..signIn(UserModel(id: 42, name: 'Test', email: 'test@example.com'));

      await Backend.session.end();

      expect(provider.user, isNull);
    });

    test('reloadUser replaces the user with the server copy', () async {
      backend.on(
        'GET',
        '/api/users/me',
        (_) async => FakeBackend.json(FakeBackend.userJson()),
      );
      final provider = UserProvider()
        ..signIn(UserModel(id: 7, name: 'Asha', email: 'asha@example.com'));
      expect(provider.user?.emailVerified, isFalse);

      await provider.reloadUser();

      expect(provider.user?.emailVerified, isTrue);
    });

    test('reloadUser does nothing when signed out', () async {
      final provider = UserProvider();

      await provider.reloadUser();

      expect(provider.user, isNull);
      expect(backend.count('GET', '/api/users/me'), 0);
    });

    test(
      'reloadUser keeps the current user when the server cannot be reached',
      () async {
        backend.on(
          'GET',
          '/api/users/me',
          (_) async => FakeBackend.error(503, 'unavailable', 'Down'),
        );
        final provider = UserProvider()
          ..signIn(UserModel(id: 7, name: 'Asha', email: 'asha@example.com'));

        await provider.reloadUser();

        expect(provider.user?.email, 'asha@example.com');
      },
    );
  });
}
