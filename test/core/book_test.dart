import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/book/book_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> fareJson({int price = 7517, String day = '2026-12-07'}) =>
    {
      'origin': 'DEL',
      'destination': 'BOM',
      'airline': '6E',
      'airlineName': 'IndiGo',
      'flightNumber': '5289',
      'departAt': '${day}T07:10:00+05:30',
      'returnAt': null,
      'stops': 0,
      'returnStops': null,
      'durationMinutes': 125,
      'price': price,
      'link': 'https://tp.media/r?u=$day',
    };

const delhi = Airport(
  code: 'DEL',
  type: 'city',
  name: 'New Delhi',
  country: 'India',
);
const mumbai = Airport(
  code: 'BOM',
  type: 'city',
  name: 'Mumbai',
  country: 'India',
);

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  group('Book models', () {
    test('airports keep cities and airports and drop odd entries', () {
      final airports = [
        {
          'code': 'DEL',
          'type': 'city',
          'name': 'New Delhi',
          'country': 'India',
        },
        {
          'code': 'DEL',
          'type': 'airport',
          'name': 'Indira Gandhi International Airport',
          'city': 'New Delhi',
        },
        {'code': 'XXX', 'type': 'station', 'name': 'Odd'},
      ].map(Airport.fromJson).whereType<Airport>().toList();
      expect(airports.map((a) => a.type), ['city', 'airport']);
      expect(airports[0].label, 'New Delhi (DEL), India');
      expect(airports[1].label, 'Indira Gandhi International Airport (DEL)');
      expect(airports[1].isAirport, isTrue);
    });

    test(
      'flight results need a currency and a search link; odd fares are dropped',
      () {
        final results = FlightResults.fromJson({
          'priceKind': 'recent',
          'currency': 'INR',
          'onDate': [
            fareJson(),
            {'price': 'cheap'},
          ],
          'nearby': [fareJson(price: 6630, day: '2026-12-01')],
          'searchLink': 'https://tp.media/r?u=search',
        })!;
        expect(results.onDate.single.airlineName, 'IndiGo');
        expect(results.nearby.single.price, 6630);
        expect(FlightResults.fromJson({'currency': 'INR'}), isNull);
      },
    );
  });

  group('Book format', () {
    test('prices, times, durations and dates read like the website', () {
      expect(BookFormat.price(7517, 'INR'), '₹7,517');
      expect(BookFormat.time('2026-12-07T07:10:00+05:30'), '7:10 AM');
      expect(BookFormat.time('2026-12-07T19:05:00+05:30'), '7:05 PM');
      expect(BookFormat.duration(125), '2h 05m');
      expect(BookFormat.stops(0), 'Nonstop');
      expect(BookFormat.stops(2), '2 stops');
      expect(BookFormat.dateRange('2026-12-07', '2026-12-09'), '7–9 Dec');
      expect(
        BookFormat.dateRange('2026-04-28', '2026-05-05'),
        '28 Apr – 5 May',
      );
      expect(BookFormat.plural(1, 'passenger'), '1 passenger');
      expect(BookFormat.isoDate(DateTime(2026, 3, 4)), '2026-03-04');
    });
  });

  group('BookService', () {
    test('a flight search asks for the app channel, INR and the return date when there is one', () async {
      backend.on('GET', '/api/book/flights', (_) async {
        return FakeBackend.json({
          'priceKind': 'recent',
          'currency': 'INR',
          'onDate': [fareJson()],
          'nearby': <Object>[],
          'searchLink': 'https://tp.media/r?u=search',
        });
      });
      final results = await BookService.searchFlights(
        const FlightSearch(
          from: delhi,
          to: mumbai,
          depart: '2026-12-07',
          returnDate: '2026-12-10',
          adults: 2,
        ),
      );
      expect(results.onDate, hasLength(1));
      final query = backend.requests.single.url.queryParameters;
      expect(query['from'], 'DEL');
      expect(query['to'], 'BOM');
      expect(query['return'], '2026-12-10');
      expect(query['adults'], '2');
      expect(query['channel'], 'app');
      expect(query['currency'], 'INR');
    });

    test(
      'flight prices that are unavailable surface the server message',
      () async {
        backend.on('GET', '/api/book/flights', (_) async {
          return FakeBackend.error(
            503,
            'flight_prices_unavailable',
            "Flight prices aren't available right now.",
          );
        });
        await expectLater(
          BookService.searchFlights(
            const FlightSearch(from: delhi, to: mumbai, depart: '2026-12-07'),
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              "Flight prices aren't available right now.",
            ),
          ),
        );
      },
    );

    test('stay and car partners come back as cards; the car airport is sent only when picked', () async {
      backend.on('GET', '/api/book/stays', (_) async {
        return FakeBackend.json([
          {
            'id': 'tripcom',
            'name': 'Trip.com',
            'link': 'https://tp.media/r?u=trip',
          },
        ]);
      });
      backend.on('GET', '/api/book/cars', (_) async {
        return FakeBackend.json([
          {
            'id': 'economybookings',
            'name': 'EconomyBookings',
            'link': 'https://tp.media/r?u=eb',
          },
          {'id': 'broken'},
        ]);
      });
      final stays = await BookService.stayPartners(
        const StaySearch(
          place: 'Jaipur',
          checkin: '2026-12-07',
          checkout: '2026-12-09',
        ),
      );
      expect(stays.single.name, 'Trip.com');
      expect(backend.requests.last.url.queryParameters['channel'], 'app');

      final cars = await BookService.carPartners(
        const CarSearch(
          place: 'Goa',
          pickup: '2026-12-07',
          dropoff: '2026-12-10',
        ),
      );
      expect(cars.single.id, 'economybookings');
      expect(
        backend.requests.last.url.queryParameters.containsKey('airport'),
        isFalse,
      );

      await BookService.carPartners(
        const CarSearch(
          place: 'Goa',
          airport: 'GOI',
          pickup: '2026-12-07',
          dropoff: '2026-12-10',
        ),
      );
      expect(backend.requests.last.url.queryParameters['airport'], 'GOI');
    });
  });
}
