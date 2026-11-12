import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/notifications/notification_models.dart';
import 'package:flutter/foundation.dart';

/// Notifications (4.5): the bell's list, the push switches and this phone's push token (the same calls as the
/// website's `notificationsService.ts`).
class NotificationService {
  NotificationService._();

  static const _unexpected = ApiException(
    'Unexpected response from the server.',
    200,
  );

  /// The bell's badge. Refreshed by [refreshUnread] (Home, a push arriving) and set to 0 when the list is read.
  static final unread = ValueNotifier<int>(0);

  /// The signed-in user's notifications, newest first; [before] continues from a page's `nextCursor`.
  static Future<NotificationPage> list([int? before]) async {
    final data = await Backend.api.request(
      'GET',
      '/api/notifications${before == null ? '' : '?before=$before'}',
      fallbackError: 'Could not load your notifications.',
    );
    if (data is! Map<String, dynamic>) throw _unexpected;
    final page = NotificationPage(
      items: parseList(data['items'], NotificationItem.fromJson),
      nextCursor: data['nextCursor'] is int ? data['nextCursor'] as int : null,
      unread: data['unread'] is int ? data['unread'] as int : 0,
    );
    if (before == null) unread.value = page.unread;
    return page;
  }

  /// Updates the badge; keeps the last count when offline or signed out.
  static Future<void> refreshUnread() async {
    try {
      final data = await Backend.api.request(
        'GET',
        '/api/notifications/unread',
        fallbackError: 'Could not load your notifications.',
      );
      if (data is Map<String, dynamic> && data['unread'] is int) {
        unread.value = data['unread'] as int;
      }
    } on ApiException {
      // Shown again next time.
    }
  }

  static Future<void> markAllRead() async {
    await Backend.api.request(
      'POST',
      '/api/notifications/read',
      fallbackError: 'Could not update your notifications.',
    );
    unread.value = 0;
  }

  static Future<NotificationSettings> settings() async =>
      NotificationSettings.fromJson(
        await Backend.api.request(
          'GET',
          '/api/notifications/settings',
          fallbackError: 'Could not load your notification settings.',
        ),
      );

  static Future<NotificationSettings> saveSettings(
    NotificationSettings settings,
  ) async => NotificationSettings.fromJson(
    await Backend.api.request(
      'PUT',
      '/api/notifications/settings',
      body: settings.toJson(),
      fallbackError: 'Could not save your notification settings.',
    ),
  );

  /// Tells the backend to push to this phone (after sign-in, and when Firebase gives the app a new token).
  static Future<void> registerDevice(String token) async {
    await Backend.api.request(
      'PUT',
      '/api/notifications/devices',
      body: {'token': token, 'platform': 'android'},
      expectedStatus: 204,
      fallbackError: 'Could not turn on notifications.',
    );
  }

  /// Stops pushes to this phone (before signing out, so the next person on it gets none of yours).
  static Future<void> removeDevice(String token) async {
    await Backend.api.request(
      'POST',
      '/api/notifications/devices/remove',
      body: {'token': token, 'platform': 'android'},
      expectedStatus: 204,
      fallbackError: 'Could not turn off notifications.',
    );
  }
}
