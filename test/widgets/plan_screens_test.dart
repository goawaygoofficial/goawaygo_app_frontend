import 'dart:convert';

import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/features/10_plans/screens/plan_form_screen.dart';
import 'package:app_frontend/features/10_plans/screens/plan_screen.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/plans_test.dart' show jaipur, planJson;
import '../helpers/fake_backend.dart';
import 'book_results_test.dart' show pumpOnPhone;

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    dotenv.loadFromString(
      envString: 'WEBSITE_URL=https://staging.goawaygo.com',
    );
  });

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a plan shows its estimate, shortcuts and days on a phone', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      PlanScreen(id: 'abc123def456', plan: Plan.fromJson(planJson())),
    );

    expect(find.text('Jaipur Heritage and Flavors'), findsOneWidget);
    expect(find.text('≈ ₹3,000 a day'), findsOneWidget);
    expect(find.text('Stays ≈ ₹5,000 a night'), findsOneWidget);
    expect(find.text('Flights'), findsOneWidget);
    expect(find.text('Car rentals'), findsOneWidget);
    expect(find.textContaining('10–12 Dec · 3 days'), findsOneWidget);
    await scrollTo(tester, find.text('Share by link'));
    expect(find.text('Delete plan'), findsOneWidget);
  });

  testWidgets('a plan opened from My Trips loads it', (tester) async {
    backend.on('GET', '/api/plans/abc123def456', (_) async {
      return FakeBackend.json(planJson());
    });

    await pumpOnPhone(tester, const PlanScreen(id: 'abc123def456'));

    expect(find.text('Jaipur Heritage and Flavors'), findsOneWidget);
  });

  testWidgets('change a day rewrites it with the wish', (tester) async {
    Object? sent;
    backend.on('POST', '/api/plans/abc123def456/days/1', (request) async {
      sent = jsonDecode(request.body);
      return FakeBackend.json(planJson(firstDay: 'Street food crawl'));
    });
    await pumpOnPhone(
      tester,
      PlanScreen(id: 'abc123def456', plan: Plan.fromJson(planJson())),
    );

    await scrollTo(tester, find.text('Change this day').first);
    await tester.tap(find.text('Change this day').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'more street food');
    await tester.tap(find.text('Rewrite day'));
    await tester.pumpAndSettle();

    expect(sent, {'wish': 'more street food'});
    expect(find.text('Street food crawl'), findsOneWidget);
  });

  testWidgets('share by link shows the website link', (tester) async {
    backend.on('PUT', '/api/plans/abc123def456/share', (_) async {
      return FakeBackend.json(planJson(shared: true));
    });
    await pumpOnPhone(
      tester,
      PlanScreen(id: 'abc123def456', plan: Plan.fromJson(planJson())),
    );

    await scrollTo(tester, find.text('Share by link'));
    await tester.tap(find.text('Share by link'));
    await tester.pumpAndSettle();

    expect(
      find.text('https://staging.goawaygo.com/plans/shared/abc123def456'),
      findsOneWidget,
    );
    expect(find.text('Stop sharing'), findsOneWidget);
  });

  testWidgets('delete needs a second tap', (tester) async {
    backend.on('DELETE', '/api/plans/abc123def456', (_) async {
      return FakeBackend.json('', 204);
    });
    await pumpOnPhone(
      tester,
      PlanScreen(id: 'abc123def456', plan: Plan.fromJson(planJson())),
    );

    await scrollTo(tester, find.text('Delete plan'));
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    expect(backend.count('DELETE', '/api/plans/abc123def456'), 0);

    await tester.tap(find.text('Tap again to delete this plan'));
    await tester.pumpAndSettle();
    expect(backend.count('DELETE', '/api/plans/abc123def456'), 1);
  });

  testWidgets('the plan form needs a start date and takes up to 6 interests', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    backend.store.token = 'refresh-1';
    backend.on(
      'POST',
      '/api/auth/refresh',
      (_) async =>
          FakeBackend.session(accessToken: 'a', refreshToken: 'refresh-2'),
    );
    final user = UserProvider();
    await tester.runAsync(user.restoreSession);
    await pumpOnPhone(
      tester,
      ChangeNotifierProvider.value(
        value: user,
        child: const PlanFormScreen(place: jaipur),
      ),
    );

    for (final interest in PlanOptions.interests.take(7)) {
      final chip = find.widgetWithText(FilterChip, interest.label);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    final picked = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected);
    // Couple, Balanced and Mid-range are picked from the start.
    expect(picked, hasLength(3 + PlanOptions.maxInterests));

    await tester.ensureVisible(find.text('Plan my trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan my trip'));
    await tester.pumpAndSettle();

    expect(find.text('Choose when your trip starts.'), findsOneWidget);
    expect(backend.count('POST', '/api/plans'), 0);
  });

  testWidgets('the plan form asks to sign in when signed out', (tester) async {
    await pumpOnPhone(
      tester,
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const PlanFormScreen(place: jaipur),
      ),
    );

    expect(find.text('Plan a trip'), findsOneWidget);
    expect(find.text('Jaipur'), findsOneWidget);
    expect(find.textContaining('Sign in from the Profile tab'), findsOneWidget);
    expect(find.text('Plan my trip'), findsNothing);
  });
}
