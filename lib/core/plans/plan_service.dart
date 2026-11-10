import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI trip planner (4.4): the same calls as the website's `plansService.ts`. Plans belong to the signed-in user;
/// a shared plan opens on the website for anyone with its link.
class PlanService {
  PlanService._();

  /// Writing a plan (or a day) takes the AI 10-40 s, longer when the free tier is busy.
  static const _writeTimeout = Duration(minutes: 2);

  static const _unexpected = ApiException(
    'Unexpected response from the server.',
    200,
  );

  /// Bumped whenever a plan is made, changed, shared or deleted, so My Trips can reload its list.
  static final changes = ValueNotifier<int>(0);

  static Plan _plan(Object? data) => Plan.fromJson(data) ?? (throw _unexpected);

  static T _changed<T>(T value) {
    changes.value++;
    return value;
  }

  /// Makes and saves a plan (signed in).
  static Future<Plan> create(PlanRequest request) async {
    final data = await Backend.api.request(
      'POST',
      '/api/plans',
      // Costs in the traveller's currency.
      body: {...request.toJson(), 'currency': I18n.currency},
      expectedStatus: 201,
      fallbackError: 'Could not make your plan.',
      timeout: _writeTimeout,
    );
    return _changed(_plan(data));
  }

  /// The signed-in user's plans, newest first.
  static Future<List<PlanSummary>> list() async {
    final data = await Backend.api.request(
      'GET',
      '/api/plans',
      fallbackError: 'Could not load your plans.',
    );
    if (data is! List) throw _unexpected;
    return parseList(data, PlanSummary.fromJson);
  }

  static Future<Plan> get(String id) async => _plan(
    await Backend.api.request(
      'GET',
      '/api/plans/${Uri.encodeComponent(id)}',
      fallbackError: 'Could not open this plan.',
    ),
  );

  static Future<void> delete(String id) async {
    await Backend.api.request(
      'DELETE',
      '/api/plans/${Uri.encodeComponent(id)}',
      expectedStatus: 204,
      fallbackError: 'Could not delete this plan.',
    );
    _changed(null);
  }

  /// Rewrites one day (1-based), optionally following a wish ("more street food").
  static Future<Plan> changeDay(String id, int day, String wish) async {
    final data = await Backend.api.request(
      'POST',
      '/api/plans/${Uri.encodeComponent(id)}/days/$day',
      body: {'wish': wish},
      fallbackError: 'Could not change this day.',
      timeout: _writeTimeout,
    );
    return _changed(_plan(data));
  }

  static Future<Plan> share(String id, {required bool shared}) async {
    final data = await Backend.api.request(
      'PUT',
      '/api/plans/${Uri.encodeComponent(id)}/share',
      body: {'shared': shared},
      fallbackError: shared
          ? 'Could not share this plan.'
          : 'Could not stop sharing.',
    );
    return _changed(_plan(data));
  }

  /// The plan's read-only page on the website (`WEBSITE_URL`), or null if that isn't set.
  static String? sharedLink(String id, [String? websiteUrl]) {
    final base = (websiteUrl ?? dotenv.env['WEBSITE_URL'] ?? '')
        .trim()
        .replaceAll(RegExp(r'/+$'), '');
    return base.isEmpty ? null : '$base/plans/shared/$id';
  }

  /// Check-out (or drop-off) for the booking shortcuts: the last day, or the day after for a one-day plan.
  static String leaveDate(String startDate, String endDate, int days) {
    if (days > 1) return endDate;
    return BookFormat.isoDate(
      DateTime.parse(startDate).add(const Duration(days: 1)),
    );
  }

  /// The last day of a plan that starts on [startDate] and lasts [days] days.
  static String endDate(String startDate, int days) => BookFormat.isoDate(
    DateTime.parse(startDate).add(Duration(days: days - 1)),
  );

  /// Guests and rooms for the Stays shortcut, from who is travelling.
  static ({int guests, int rooms}) party(String travellers) =>
      switch (travellers) {
        'solo' => (guests: 1, rooms: 1),
        'family' => (guests: 4, rooms: 1),
        'friends' => (guests: 4, rooms: 2),
        _ => (guests: 2, rooms: 1),
      };
}
