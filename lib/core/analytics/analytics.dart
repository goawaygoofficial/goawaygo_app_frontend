import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The whole event list (same as the website's). Properties never contain names, emails, free text or IDs.
sealed class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.properties = const {}]);

  final String name;
  final Map<String, Object> properties;
}

class SignUpCompleted extends AnalyticsEvent {
  const SignUpCompleted()
    : super('sign_up_completed', const {'method': 'email'});
}

class SignInCompleted extends AnalyticsEvent {
  SignInCompleted({required bool google})
    : super('sign_in_completed', {'method': google ? 'google' : 'email'});
}

enum TravelCategory { flights, stays, rentals }

class TravelCategoryOpened extends AnalyticsEvent {
  TravelCategoryOpened(TravelCategory category)
    : super('travel_category_opened', {'category': category.name});
}

class DestinationSearched extends AnalyticsEvent {
  const DestinationSearched() : super('destination_searched');
}

enum AnalyticsConsent { granted, denied }

/// Product analytics (PostHog, EU cloud), only after the user agrees. Until then the SDK isn't even started
/// (`com.posthog.posthog.AUTO_INIT` is off in the Android and iOS config), so nothing is stored or sent. Events are
/// anonymous: no person profiles or identify, no session replay, surveys or feature flags.
///
/// Builds without `POSTHOG_KEY` in their env file (local runs, tests) have no analytics and never ask.
class Analytics {
  Analytics._();

  static const _consentKey = 'goawaygo.analyticsConsent';

  /// Where the choice was kept before the GoAwayGo rename; moved to [_consentKey] on first start.
  static const _legacyConsentKey = 'goaway.analyticsConsent';
  static const _host = 'https://eu.i.posthog.com';

  /// The user's answer; null until they choose. Widgets listen to it ("Privacy choices").
  static final consent = ValueNotifier<AnalyticsConsent?>(null);

  static bool _started = false;

  /// Whether this build has analytics at all (a key in its env file).
  static bool get available => _key.isNotEmpty;

  static String get _key => dotenv.env['POSTHOG_KEY']?.trim() ?? '';

  /// Reads the saved answer and starts PostHog if the user agreed earlier. Call once at startup.
  static Future<void> init() async {
    if (!available) return;
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyConsentKey);
    if (legacy != null) {
      if (prefs.getString(_consentKey) == null) {
        await prefs.setString(_consentKey, legacy);
      }
      await prefs.remove(_legacyConsentKey);
    }
    consent.value = switch (prefs.getString(_consentKey)) {
      'granted' => AnalyticsConsent.granted,
      'denied' => AnalyticsConsent.denied,
      _ => null,
    };
    if (consent.value == AnalyticsConsent.granted) await _start();
  }

  /// Saves the user's answer and starts or stops analytics to match.
  static Future<void> setConsent(AnalyticsConsent value) async {
    consent.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentKey, value.name);
    if (value == AnalyticsConsent.granted) {
      if (_started) {
        await Posthog().optIn();
      } else {
        await _start();
      }
    } else if (_started) {
      // Stop sending and forget the random ID this device had.
      await Posthog().optOut();
      await Posthog().reset();
    }
  }

  static Future<void> _start() async {
    final config = PostHogConfig(_key)
      ..host = _host
      ..personProfiles = PostHogPersonProfiles.never
      ..captureApplicationLifecycleEvents = true
      ..sessionReplay = false
      ..surveys = false
      ..preloadFeatureFlags = false
      ..sendFeatureFlagEvent = false
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false;
    try {
      await Posthog().setup(config);
      await Posthog().register(
        'environment',
        dotenv.env['SENTRY_ENVIRONMENT'] ?? 'staging',
      );
      _started = true;
    } on Object catch (error) {
      // Analytics must never break the app.
      debugPrint('Analytics not started: $error');
    }
  }

  /// Sends one event from the fixed list; does nothing without consent.
  static void track(AnalyticsEvent event) {
    if (!_started || consent.value != AnalyticsConsent.granted) return;
    Posthog()
        .capture(eventName: event.name, properties: event.properties)
        .catchError((Object _) {});
  }
}
