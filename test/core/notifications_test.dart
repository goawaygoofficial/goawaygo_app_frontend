import 'dart:convert';

import 'package:app_frontend/core/notifications/notification_models.dart';
import 'package:app_frontend/core/notifications/notification_service.dart';
import 'package:app_frontend/core/notifications/push_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> notificationJson({
  int id = 9,
  String type = 'like',
  String message = 'Cara and 1 other liked your post.',
  String detail = '',
  bool read = false,
  String? postId = 'bbbbbbbbbbbb',
  String? planId,
  bool actor = true,
}) => {
  'id': id,
  'type': type,
  'message': message,
  'detail': detail,
  'read': read,
  'createdAt': DateTime.now()
      .subtract(const Duration(minutes: 3))
      .toUtc()
      .toIso8601String(),
  'actor': actor
      ? {'publicId': 'aaaaaaaaaaaa', 'name': 'Cara', 'photoUrl': null}
      : null,
  'postId': postId,
  'planId': planId,
};

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    NotificationService.unread.value = 0;
  });

  group('NotificationService', () {
    test('list reads the bell and its unread count', () async {
      backend.on('GET', '/api/notifications', (_) async {
        return FakeBackend.json({
          'items': [
            notificationJson(),
            notificationJson(
              id: 8,
              type: 'announcement',
              message: 'New in GoAwayGo',
              detail: 'Plan trips with AI.',
              read: true,
              postId: null,
              actor: false,
            ),
            {'id': 'broken'},
          ],
          'nextCursor': 8,
          'unread': 1,
        });
      });

      final page = await NotificationService.list();

      expect(page.items, hasLength(2));
      expect(page.items.first.actor?.name, 'Cara');
      expect(page.items.first.postId, 'bbbbbbbbbbbb');
      expect(page.items.last.actor, isNull);
      expect(page.items.last.detail, 'Plan trips with AI.');
      expect(page.nextCursor, 8);
      expect(NotificationService.unread.value, 1);
    });

    test('marking read clears the badge', () async {
      NotificationService.unread.value = 3;
      backend.on('POST', '/api/notifications/read', (_) async {
        return FakeBackend.json({'unread': 0});
      });

      await NotificationService.markAllRead();

      expect(NotificationService.unread.value, 0);
    });

    test('refreshUnread keeps the count when offline', () async {
      NotificationService.unread.value = 2;
      backend.on('GET', '/api/notifications/unread', (_) async {
        return FakeBackend.error(503, 'down', 'Down');
      });

      await NotificationService.refreshUnread();

      expect(NotificationService.unread.value, 2);
    });

    test('settings and the push token go to the backend', () async {
      Object? saved;
      Object? device;
      backend.on('PUT', '/api/notifications/settings', (request) async {
        saved = jsonDecode(request.body);
        return FakeBackend.json(saved!);
      });
      backend.on('PUT', '/api/notifications/devices', (request) async {
        device = jsonDecode(request.body);
        return FakeBackend.json('', 204);
      });

      final settings = await NotificationService.saveSettings(
        const NotificationSettings(tripReminders: false),
      );
      await NotificationService.registerDevice('phone-token');

      expect(saved, {
        'wanderbook': true,
        'tripReminders': false,
        'sharedPlans': true,
        'announcements': true,
      });
      expect(settings.tripReminders, isFalse);
      expect(device, {'token': 'phone-token', 'platform': 'android'});
    });
  });

  group('PushPrompts', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('asks after sign-in once, then once more later', () async {
      expect(await PushPrompts.shouldAskAfterSignIn(), isTrue);
      expect(await PushPrompts.shouldAskAgain(), isFalse);

      await PushPrompts.markAsked();
      expect(await PushPrompts.shouldAskAfterSignIn(), isFalse);
      expect(await PushPrompts.shouldAskAgain(), isTrue);

      await PushPrompts.markAskedAgain();
      expect(await PushPrompts.shouldAskAgain(), isFalse);
    });
  });

  test('a build without the Firebase key has no push', () {
    expect(PushNotifications.available, isFalse);
  });
}
