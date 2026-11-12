import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/notifications/notification_models.dart';
import 'package:app_frontend/core/notifications/notification_service.dart';
import 'package:app_frontend/core/notifications/push_notifications.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:flutter/material.dart';

/// Push on this phone (Android's permission), and a switch per kind of push (saved for the account at once). The
/// website has the same switches.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  NotificationSettings? _settings;
  String? _error;
  bool _saving = false;
  bool? _allowed;

  static const _switches = [
    (
      'wanderbook',
      'Wanderbook',
      'New followers, follow requests, likes and comments on your posts.',
    ),
    (
      'tripReminders',
      'Trip reminders',
      'Three days before a planned trip, and the day before.',
    ),
    (
      'sharedPlans',
      'Shared trip plans',
      'When someone opens a plan you shared (at most once a day).',
    ),
    ('announcements', 'News from GoAwayGo', 'New features and beta builds.'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the phone's settings: show whether push is on now.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final allowed = await PushNotifications.allowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final settings = await NotificationService.settings();
      if (mounted) setState(() => _settings = settings);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _turnOn() async {
    final allowed = await PushNotifications.requestPermission();
    // Android stops asking after two refusals: the phone's settings are the way back.
    if (!allowed) await PushNotifications.openSettings();
    await _checkPermission();
  }

  bool _value(NotificationSettings settings, String key) => switch (key) {
    'wanderbook' => settings.wanderbook,
    'tripReminders' => settings.tripReminders,
    'sharedPlans' => settings.sharedPlans,
    _ => settings.announcements,
  };

  NotificationSettings _with(
    NotificationSettings settings,
    String key,
    bool on,
  ) => NotificationSettings(
    wanderbook: key == 'wanderbook' ? on : settings.wanderbook,
    tripReminders: key == 'tripReminders' ? on : settings.tripReminders,
    sharedPlans: key == 'sharedPlans' ? on : settings.sharedPlans,
    announcements: key == 'announcements' ? on : settings.announcements,
  );

  Future<void> _toggle(NotificationSettings before, String key, bool on) async {
    setState(() {
      _settings = _with(before, key, on);
      _saving = true;
    });
    try {
      final saved = await NotificationService.saveSettings(_settings!);
      if (mounted) setState(() => _settings = saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _settings = before);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final settings = _settings;
    final muted = TextStyle(
      color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
      fontSize: 14,
    );

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
                  tooltip: tr('Back'),
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: ColorsUtil.whiteColor,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            Text(
              tr('Notification settings'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _Card(
              child: !PushNotifications.available
                  ? Text(
                      tr(
                        tr(
                          'Push notifications aren\'t available in this build of the app. The bell on Home still lists everything.',
                        ),
                      ),
                      style: muted,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Push on this phone'),
                                style: TextStyle(
                                  color: ColorsUtil.whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _allowed == true
                                    ? tr(
                                        'On. Choose below what you hear about.',
                                      )
                                    : tr(
                                        'Off. Turn it on to hear about likes, comments and your trips.',
                                      ),
                                style: muted,
                              ),
                            ],
                          ),
                        ),
                        if (_allowed == false) ...[
                          const SizedBox(width: 8),
                          PillButton(label: tr('Turn on'), onPressed: _turnOn),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              _Card(
                child: Column(
                  children: [
                    Text(_error!, style: muted, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    PillButton(label: tr('Try again'), onPressed: _load),
                  ],
                ),
              )
            else if (settings == null)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorsUtil.whiteColor,
                  ),
                ),
              )
            else
              for (final (key, title, text) in _switches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Card(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: SwitchListTile(
                      value: _value(settings, key),
                      onChanged: _saving
                          ? null
                          : (on) => _toggle(settings, key, on),
                      activeThumbColor: ColorsUtil.whiteColor,
                      activeTrackColor: ColorsUtil.secondary,
                      title: Text(
                        tr(title),
                        style: const TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(tr(text), style: muted),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// A lightly tinted rounded card (a Material, so switches inside show their ink).
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
