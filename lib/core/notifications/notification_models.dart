/// Shapes of the backend's notifications API (`/api/notifications`), the same as the website's
/// `features/notifications/types.ts`.
library;

String _string(Object? value) => value is String ? value : '';

String? _optional(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

/// Who a notification is about (their Wanderbook profile).
class NotificationActor {
  const NotificationActor({
    required this.publicId,
    required this.name,
    this.photoUrl,
  });

  final String publicId;
  final String name;
  final String? photoUrl;

  static NotificationActor? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['publicId'] is! String) {
      return null;
    }
    return NotificationActor(
      publicId: json['publicId'] as String,
      name: _string(json['name']),
      photoUrl: _optional(json['photoUrl']),
    );
  }
}

/// One line in the bell; the backend writes the text.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.detail,
    required this.read,
    required this.createdAt,
    this.actor,
    this.postId,
    this.planId,
  });

  final int id;

  /// `follow`, `follow_request`, `follow_accepted`, `like`, `comment`, `trip_reminder`, `plan_opened` or
  /// `announcement`.
  final String type;

  /// "Asha liked your post."
  final String message;

  /// A comment's text or an announcement's message; empty otherwise.
  final String detail;
  final bool read;
  final DateTime createdAt;
  final NotificationActor? actor;
  final String? postId;
  final String? planId;

  static NotificationItem? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! int ||
        json['type'] is! String ||
        json['message'] is! String) {
      return null;
    }
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as String,
      message: json['message'] as String,
      detail: _string(json['detail']),
      read: json['read'] == true,
      createdAt:
          DateTime.tryParse(_string(json['createdAt'])) ?? DateTime.now(),
      actor: NotificationActor.fromJson(json['actor']),
      postId: _optional(json['postId']),
      planId: _optional(json['planId']),
    );
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.nextCursor,
    required this.unread,
  });

  final List<NotificationItem> items;

  /// Pass to the next request to continue; null on the last page.
  final int? nextCursor;
  final int unread;
}

/// Which pushes this account gets (the bell lists everything either way).
class NotificationSettings {
  const NotificationSettings({
    this.wanderbook = true,
    this.tripReminders = true,
    this.sharedPlans = true,
    this.announcements = true,
  });

  final bool wanderbook;
  final bool tripReminders;
  final bool sharedPlans;
  final bool announcements;

  static NotificationSettings fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return NotificationSettings(
      wanderbook: map['wanderbook'] != false,
      tripReminders: map['tripReminders'] != false,
      sharedPlans: map['sharedPlans'] != false,
      announcements: map['announcements'] != false,
    );
  }

  Map<String, bool> toJson() => {
    'wanderbook': wanderbook,
    'tripReminders': tripReminders,
    'sharedPlans': sharedPlans,
    'announcements': announcements,
  };
}
