import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/notifications/notification_models.dart';
import 'package:app_frontend/core/notifications/notification_service.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/11_notifications/open_notification.dart';
import 'package:app_frontend/features/11_notifications/screens/notification_settings_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The bell's list (the website's `NotificationsPage`): Wanderbook activity, trip reminders, shared plans and
/// announcements, newest first. Opening it marks everything read; the new ones stay highlighted while it is open.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem>? _items;
  int? _nextCursor;
  String? _error;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    if (context.read<UserProvider>().user != null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _items = null;
    });
    try {
      final page = await NotificationService.list();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _nextCursor = page.nextCursor;
      });
      if (page.unread > 0) {
        try {
          await NotificationService.markAllRead();
        } on ApiException {
          // Still unread; marked next time.
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await NotificationService.list(cursor);
      if (!mounted) return;
      setState(() {
        _items = [...?_items, ...page.items];
        _nextCursor = page.nextCursor;
      });
    } on ApiException catch (error) {
      if (mounted) showError(context, error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final signedIn = context.watch<UserProvider>().user != null;
    final items = _items;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Image.asset('assets/images/logo.png', height: height * 0.1),
                const Spacer(),
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: ColorsUtil.whiteColor,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications,
                  color: ColorsUtil.secondaryLight,
                  size: 26,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Notifications',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!signedIn)
              const _Panel(
                text: 'Sign in from the Profile tab to see likes, comments, new followers and trip reminders.',
              )
            else if (_error != null)
              _Panel(
                text: _error!,
                action: PillButton(label: 'Try again', onPressed: _load),
              )
            else if (items == null)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorsUtil.whiteColor,
                  ),
                ),
              )
            else if (items.isEmpty)
              const _Panel(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                text: 'Likes, comments, new followers and trip reminders show up here.',
              )
            else ...[
              for (final item in items) _NotificationTile(item: item),
              if (_nextCursor != null)
                Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: ColorsUtil.whiteColor,
                          ),
                        )
                      : PillButton(
                          label: 'Show older',
                          quiet: true,
                          onPressed: _loadMore,
                        ),
                ),
            ],
            if (signedIn)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Notification settings'),
                    style: TextButton.styleFrom(
                      foregroundColor: ColorsUtil.secondaryLighter,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  static const _icons = {
    'trip_reminder': Icons.calendar_month,
    'plan_opened': Icons.travel_explore,
    'announcement': Icons.campaign,
  };

  bool get _opensSomething =>
      item.postId != null ||
      item.planId != null ||
      item.actor != null ||
      item.type == 'follow_request';

  @override
  Widget build(BuildContext context) {
    final icon = _icons[item.type];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: item.read
            ? ColorsUtil.whiteColor.withValues(alpha: 0.08)
            : ColorsUtil.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _opensSomething
              ? () => openNotification(
                  context,
                  type: item.type,
                  postId: item.postId,
                  planId: item.planId,
                  profileId: item.actor?.publicId,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null && item.actor == null)
                  ClipOval(
                    child: Container(
                      width: 44,
                      height: 44,
                      color: ColorsUtil.secondary,
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  )
                else
                  Avatar(url: item.actor?.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.detail,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        timeAgo(item.createdAt),
                        style: const TextStyle(
                          color: ColorsUtil.primaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.read)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6, left: 8),
                    decoration: const BoxDecoration(
                      color: ColorsUtil.secondaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.text, this.title, this.icon, this.action});

  final String text;
  final String? title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: ColorsUtil.secondaryLight, size: 40),
            const SizedBox(height: 8),
          ],
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
