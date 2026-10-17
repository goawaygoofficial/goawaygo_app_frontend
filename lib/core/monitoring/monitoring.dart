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

/// Error tracking for builds that set SENTRY_DSN in their env file (staging, production). Local runs (`.env`
/// without it) send nothing. Crashes, including native Android ones, go to Sentry project goaway-app with the
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
    options.beforeBreadcrumb = (breadcrumb, hint) {
      final url = breadcrumb?.data?['url'];
      if (breadcrumb != null && url is String) {
        breadcrumb.data = {...?breadcrumb.data, 'url': scrubUrl(url)};
      }
      return breadcrumb;
    };
  }, appRunner: appRunner);
}
