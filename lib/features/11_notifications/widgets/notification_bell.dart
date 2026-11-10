import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/notifications/notification_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The bell in Home's header with an orange badge for unread notifications ([NotificationService.unread]).
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.size,
    required this.onPressed,
  });

  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unread,
      builder: (context, unread, _) => IconButton(
        tooltip: unread > 0
            ? tr('Notifications, {0} unread', [unread])
            : tr('Notifications'),
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          backgroundColor: ColorsUtil.secondary,
          textColor: ColorsUtil.whiteColor,
          largeSize: 18,
          child: Icon(
            Icons.notifications,
            size: size,
            color: ColorsUtil.brandOrangeLight,
          ),
        ),
      ),
    );
  }
}
