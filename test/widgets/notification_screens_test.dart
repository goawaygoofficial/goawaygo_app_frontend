import 'dart:convert';

import 'package:app_frontend/core/notifications/notification_service.dart';
import 'package:app_frontend/features/11_notifications/screens/notification_settings_screen.dart';
import 'package:app_frontend/features/11_notifications/screens/notifications_screen.dart';
import 'package:app_frontend/features/11_notifications/widgets/notification_bell.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications_test.dart' show notificationJson;
import '../helpers/fake_backend.dart';
import 'book_results_test.dart' show pumpOnPhone;

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    SharedPreferences.setMockInitialValues({});
    NotificationService.unread.value = 0;
  });

  /// A signed-in user, restored from a fake refresh token.
  Future<UserProvider> signedIn(WidgetTester tester) async {
    backend.store.token = 'refresh-1';
    backend.on(
      'POST',
      '/api/auth/refresh',
      (_) async =>
          FakeBackend.session(accessToken: 'a', refreshToken: 'refresh-2'),
    );
    final user = UserProvider();
    await tester.runAsync(user.restoreSession);
    return user;
  }

  testWidgets(
    'the bell lists notifications, highlights new ones and marks them read',
    (tester) async {
      NotificationService.unread.value = 1;
      backend.on('GET', '/api/notifications', (_) async {
        return FakeBackend.json({
          'items': [
            notificationJson(),
            notificationJson(
              id: 7,
              type: 'trip_reminder',
              message: 'Your trip to Jaipur starts tomorrow.',
              read: true,
              postId: null,
              planId: 'abc123def456',
              actor: false,
            ),
            notificationJson(
              id: 6,
              type: 'comment',
              message: 'Ben commented on your post:',
              detail: 'What a view!',
              read: true,
            ),
          ],
          'nextCursor': null,
          'unread': 1,
        });
      });
      backend.on('POST', '/api/notifications/read', (_) async {
        return FakeBackend.json({'unread': 0});
      });
      final user = await signedIn(tester);

      await pumpOnPhone(
        tester,
        ChangeNotifierProvider.value(
          value: user,
          child: const NotificationsScreen(),
        ),
      );

      expect(find.text('Cara and 1 other liked your post.'), findsOneWidget);
      expect(find.text('Your trip to Jaipur starts tomorrow.'), findsOneWidget);
      expect(find.text('What a view!'), findsOneWidget);
      expect(find.text('3 min'), findsWidgets);
      expect(find.text('Notification settings'), findsOneWidget);
      expect(backend.count('POST', '/api/notifications/read'), 1);
      expect(NotificationService.unread.value, 0);
    },
  );

  testWidgets('signed out, the bell asks to sign in', (tester) async {
    await pumpOnPhone(
      tester,
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const NotificationsScreen(),
      ),
    );

    expect(find.textContaining('Sign in from the Profile tab'), findsOneWidget);
    expect(backend.count('GET', '/api/notifications'), 0);
  });

  testWidgets('the bell shows the unread count', (tester) async {
    NotificationService.unread.value = 4;
    await pumpOnPhone(
      tester,
      Scaffold(body: NotificationBell(size: 28, onPressed: () {})),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.byTooltip('Notifications, 4 unread'), findsOneWidget);
  });

  testWidgets('a switch saves at once; this build has no push', (tester) async {
    Object? saved;
    backend.on('GET', '/api/notifications/settings', (_) async {
      return FakeBackend.json({
        'wanderbook': true,
        'tripReminders': true,
        'sharedPlans': true,
        'announcements': true,
      });
    });
    backend.on('PUT', '/api/notifications/settings', (request) async {
      saved = jsonDecode(request.body);
      return FakeBackend.json(saved!);
    });

    await pumpOnPhone(tester, const NotificationSettingsScreen());

    expect(
      find.textContaining("aren't available in this build"),
      findsOneWidget,
    );
    await tester.tap(find.text('Trip reminders'));
    await tester.pumpAndSettle();

    expect((saved! as Map)['tripReminders'], isFalse);
    expect((saved! as Map)['wanderbook'], isTrue);
  });
}
