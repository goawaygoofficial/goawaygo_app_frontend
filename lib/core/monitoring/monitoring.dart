import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Single-use tokens and OAuth values in URLs never leave the phone.
final _sensitiveQuery = RegExp(
  r'([?&#](?:token|code|state|access_token)=)[^&#\s]*',
  caseSensitive: false,
);

String scrubUrl(String url) =>
    url.replaceAllMapped(_sensitiveQuery, (m) => '${m[1]}[Filtered]');

/// Breadcrumb data keys that can hold a URL (`url.full` since sentry_flutter 10, `url` before).
const _urlKeys = ['url', 'url.full'];

/// Cuts tokens out of the URLs in an HTTP or navigation breadcrumb.
Breadcrumb? scrubBreadcrumb(Breadcrumb? breadcrumb, [Hint? hint]) {
  final data = breadcrumb?.data;
  if (breadcrumb == null || data == null) return breadcrumb;
  final scrubbed = {...data};
  for (final key in _urlKeys) {
    final url = scrubbed[key];
    if (url is String) scrubbed[key] = scrubUrl(url);
  }
  breadcrumb.data = scrubbed;
  return breadcrumb;
}

/// Error tracking for builds that set SENTRY_DSN in their env file (staging, production). Local runs (`.env`
/// without it) send nothing. Crashes, including native Android ones, go to Sentry project goawaygo-app with the
/// environment and release (package@version+build). No personal data: no user details, IPs or screenshots (view
/// hierarchy is off by default too), and tokens are cut out of URLs.
///
/// Runs [appRunner] either way, inside Sentry's error zone when it is on.
Future<void> runWithMonitoring(FutureOr<void> Function() appRunner) async {
  final dsn = dotenv.env['SENTRY_DSN']?.trim() ?? '';
  if (dsn.isEmpty) {
    await appRunner();
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = dsn;
    options.environment = dotenv.env['SENTRY_ENVIRONMENT'] ?? 'staging';
    options.sendDefaultPii = false;
    options.attachScreenshot = false;
    options.tracesSampleRate = 0.1;
    // Don't add tracing headers to API calls: the API only accepts a few request headers.
    options.tracePropagationTargets.clear();
    options.beforeBreadcrumb = scrubBreadcrumb;
  }, appRunner: appRunner);
  // Proves a build reports to Sentry: only in builds made with --dart-define=SENTRY_SELF_TEST=true.
  if (const bool.fromEnvironment('SENTRY_SELF_TEST')) {
    await Sentry.captureMessage(
      'GoAwayGo app Sentry self-test (safe to resolve)',
    );
  }
}
