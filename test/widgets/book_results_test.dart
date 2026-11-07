import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/features/03_flights/screens/flight_results_screen.dart';
import 'package:app_frontend/features/05_rentals/screens/rental_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/book_test.dart' show delhi, fareJson, mumbai;
import '../helpers/fake_backend.dart';

/// A phone screen (375 x 812): the results must fit without overflowing.
Future<void> pumpOnPhone(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  testWidgets(
    'flight results show the fare on the date, other dates and See all flights',
    (tester) async {
      backend.on('GET', '/api/book/flights', (_) async {
        return FakeBackend.json({
          'priceKind': 'recent',
          'currency': 'INR',
          'onDate': [fareJson()],
          'nearby': [fareJson(price: 6630, day: '2026-12-01')],
          'searchLink': 'https://tp.media/r?u=search',
        });
      });
      await pumpOnPhone(
        tester,
        const FlightResultsScreen(
          search: FlightSearch(from: delhi, to: mumbai, depart: '2026-12-07'),
        ),
      );

      expect(find.text('New Delhi to Mumbai'), findsOneWidget);
      expect(find.text('₹7,517'), findsOneWidget);
      expect(find.text('₹6,630'), findsOneWidget);
      expect(find.text('Other dates in December 2026'), findsOneWidget);
      expect(find.text('See all flights'), findsOneWidget);
      expect(find.textContaining('2h 05m · Nonstop'), findsWidgets);
    },
  );

  testWidgets('unavailable flight prices offer Try again', (tester) async {
    backend.on('GET', '/api/book/flights', (_) async {
      return FakeBackend.error(
        503,
        'flight_prices_unavailable',
        "Flight prices aren't available right now.",
      );
    });
    await pumpOnPhone(
      tester,
      const FlightResultsScreen(
        search: FlightSearch(from: delhi, to: mumbai, depart: '2026-12-07'),
      ),
    );

    expect(find.text('No fares right now'), findsOneWidget);
    expect(
      find.text("Flight prices aren't available right now."),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('See all flights'), findsNothing);
  });

  testWidgets('car partners fit a phone, long partner names included', (
    tester,
  ) async {
    backend.on('GET', '/api/book/cars', (_) async {
      return FakeBackend.json([
        {
          'id': 'discovercars',
          'name': 'DiscoverCars',
          'link': 'https://tp.media/r?u=dc',
        },
        {
          'id': 'economybookings',
          'name': 'EconomyBookings',
          'link': 'https://tp.media/r?u=eb',
        },
      ]);
    });
    await pumpOnPhone(
      tester,
      const RentalResultsScreen(
        search: CarSearch(
          place: 'Goa',
          airport: 'GOI',
          pickup: '2026-12-07',
          dropoff: '2026-12-10',
        ),
      ),
    );

    expect(find.text('EconomyBookings'), findsOneWidget);
    expect(
      find.text('Opens on GOI airport; add your dates (7–10 Dec)'),
      findsOneWidget,
    );
    expect(find.textContaining('may earn a commission'), findsOneWidget);
  });
}
