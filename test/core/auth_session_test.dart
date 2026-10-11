import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
  });

  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  group('sign-in', () {
    test(
      'stores the refresh token securely and keeps the access token in memory',
      () async {
        backend.on(
          'POST',
          '/api/auth/signin',
          (_) async => FakeBackend.session(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
          ),
        );

        final user = await AuthService.signin('asha@example.com', 'secret!1A');

        expect(user.email, 'asha@example.com');
        expect(backend.store.token, 'refresh-1');
        expect(Backend.session.accessToken, 'access-1');
        final request = backend.requests.single;
        expect(
          request.headers['X-Client-Type'],
          'mobile',
          reason: 'mobile gets the refresh token in the body',
        );
        expect(bodyOf(request), {
          'email': 'asha@example.com',
          'password': 'secret!1A',
        });
      },
    );

    test('shows the backend message and keeps its error code', () async {
      backend.on(
        'POST',
        '/api/auth/signin',
        (_) async => FakeBackend.error(
          401,
          'invalid_credentials',
          'Incorrect email or password.',
        ),
      );

      expect(
        () => AuthService.signin('asha@example.com', 'wrong'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'Incorrect email or password.',
              )
              .having((e) => e.code, 'code', 'invalid_credentials')
              .having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('an unreachable server is reported, not crashed on', () async {
      backend.on(
        'POST',
        '/api/auth/signin',
        (_) async => throw const SocketException('no route to host'),
      );

      expect(
        () => AuthService.signin('asha@example.com', 'x'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 0)),
      );
    });
  });

  group('restore and refresh', () {
    test(
      'with nothing stored, restore makes no request and returns null',
      () async {
        expect(await AuthService.restoreSession(), isNull);
        expect(backend.requests, isEmpty);
      },
    );

    test(
      'restores the user from the stored refresh token and rotates it',
      () async {
        backend.store.token = 'refresh-1';
        backend.on('POST', '/api/auth/refresh', (request) async {
          expect(bodyOf(request), {'refreshToken': 'refresh-1'});
          return FakeBackend.session(
            accessToken: 'access-2',
            refreshToken: 'refresh-2',
          );
        });

        final user = await AuthService.restoreSession();

        expect(user?.email, 'asha@example.com');
        expect(backend.store.token, 'refresh-2');
        expect(Backend.session.accessToken, 'access-2');
      },
    );

    test(
      'an expired access token is refreshed once and the request retried',
      () async {
        backend.on(
          'POST',
          '/api/auth/signin',
          (_) async => FakeBackend.session(
            accessToken: 'expired',
            refreshToken: 'refresh-1',
          ),
        );
        backend.on(
          'POST',
          '/api/auth/refresh',
          (_) async => FakeBackend.session(
            accessToken: 'fresh',
            refreshToken: 'refresh-2',
          ),
        );
        backend.on('GET', '/api/users/me', (request) async {
          return request.headers['Authorization'] == 'Bearer fresh'
              ? FakeBackend.json(FakeBackend.userJson())
              : FakeBackend.error(
                  401,
                  'unauthorized',
                  'You need to sign in to do this.',
                );
        });
        await AuthService.signin('asha@example.com', 'x');

        final me = await Backend.api.request(
          'GET',
          '/api/users/me',
          fallbackError: 'failed',
        );

        expect((me as Map)['email'], 'asha@example.com');
        expect(backend.count('GET', '/api/users/me'), 2);
        expect(backend.count('POST', '/api/auth/refresh'), 1);
      },
    );

    test(
      'concurrent refreshes share one request (no rotated-token reuse)',
      () async {
        backend.store.token = 'refresh-1';
        final release = Completer<void>();
        backend.on('POST', '/api/auth/refresh', (_) async {
          await release.future;
          return FakeBackend.session(
            accessToken: 'access-2',
            refreshToken: 'refresh-2',
          );
        });

        final results = [for (var i = 0; i < 5; i++) Backend.session.refresh()];
        release.complete();
        final users = await Future.wait(results);

        expect(backend.count('POST', '/api/auth/refresh'), 1);
        expect(users.every((u) => u?.email == 'asha@example.com'), isTrue);
      },
    );

    test(
      'a rejected refresh ends the session and clears the stored token',
      () async {
        backend.store.token = 'revoked';
        backend.on(
          'POST',
          '/api/auth/refresh',
          (_) async => FakeBackend.error(
            401,
            'invalid_refresh_token',
            'Your session has expired.',
          ),
        );
        final notified = <Object?>[];
        Backend.session.addListener(notified.add);

        expect(await AuthService.restoreSession(), isNull);
        expect(backend.store.token, isNull);
        expect(notified, [null]);
      },
    );

    test(
      'being offline at startup keeps the stored token for next time',
      () async {
        backend.store.token = 'refresh-1';
        backend.on(
          'POST',
          '/api/auth/refresh',
          (_) async => throw const SocketException('offline'),
        );

        expect(await AuthService.restoreSession(), isNull);
        expect(
          backend.store.token,
          'refresh-1',
          reason: 'a network blip must not sign anyone out',
        );
      },
    );
  });

  group('sign-out and password reset', () {
    test(
      'sign-out revokes the token on the server and clears it locally',
      () async {
        backend.store.token = 'refresh-1';
        backend.on('POST', '/api/auth/logout', (request) async {
          expect(bodyOf(request), {'refreshToken': 'refresh-1'});
          return http.Response('', 204);
        });

        await AuthService.signOut();

        expect(backend.count('POST', '/api/auth/logout'), 1);
        expect(backend.store.token, isNull);
        expect(Backend.session.accessToken, isNull);
      },
    );

    test(
      'sign-out still clears the device when the server is unreachable',
      () async {
        backend.store.token = 'refresh-1';
        backend.on(
          'POST',
          '/api/auth/logout',
          (_) async => throw const SocketException('offline'),
        );

        await AuthService.signOut();

        expect(backend.store.token, isNull);
      },
    );

    test('password reset sends only the email', () async {
      backend.on(
        'POST',
        '/api/auth/forgot-password',
        (_) async => http.Response('', 202),
      );

      await AuthService.requestPasswordReset('asha@example.com');

      expect(bodyOf(backend.requests.single), {'email': 'asha@example.com'});
    });
  });
}
