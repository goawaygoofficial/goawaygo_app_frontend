import 'package:app_frontend/features/08_wanderbook/screens/people_screen.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/10_plans/screens/plan_screen.dart';
import 'package:app_frontend/features/11_notifications/screens/notifications_screen.dart';
import 'package:flutter/material.dart';

/// Opens what a notification is about (from the bell or a tapped push): the post, trip plan, follow requests or
/// profile; the bell's list when there is nothing more specific (announcements).
void openNotification(
  BuildContext context, {
  required String type,
  String? postId,
  String? planId,
  String? profileId,
}) {
  if (postId != null) {
    openPost(context, postId);
  } else if (planId != null) {
    _push(context, PlanScreen(id: planId));
  } else if (type == 'follow_request') {
    _push(context, const PeopleScreen(mode: PeopleMode.requests));
  } else if (profileId != null) {
    openProfile(context, profileId);
  } else {
    _push(context, const NotificationsScreen());
  }
}

/// A tapped push's data (strings from Firebase).
void openPushData(BuildContext context, Map<String, dynamic> data) {
  String? text(String key) {
    final value = data[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  openNotification(
    context,
    type: text('type') ?? '',
    postId: text('postId'),
    planId: text('planId'),
    profileId: text('profileId'),
  );
}

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
