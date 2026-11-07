import 'dart:convert';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/core/plans/plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> slotJson(String place, int cost) => {
  'place': place,
  'activity': 'Walk the ramparts and the mirror palace.',
  'cost': cost,
};

Map<String, Object?> dayJson(int day, {String title = 'Forts and bazaars'}) => {
  'day': day,
  'date': '2026-12-${(9 + day).toString().padLeft(2, '0')}',
  'title': title,
  'morning': slotJson('City Palace', 500),
  'afternoon': slotJson('Jantar Mantar', 700),
  'evening': slotJson('Hawa Mahal', 0),
  'food': ['Pyaaz kachori', 'Lal maas'],
  'tip': 'Hire a registered guide at the gate.',
  'cost': 3000,
};

Map<String, Object?> planJson({
  String id = 'abc123def456',
  bool mine = true,
  bool shared = false,
  String firstDay = 'Forts and bazaars',
}) => {
  'id': id,
  'mine': mine,
  'shared': shared,
  'place': {
    'placeId': 'p1',
    'name': 'Jaipur',
    'area': 'Rajasthan',
    'country': 'India',
    'lat': 26.9,
    'lon': 75.8,
  },
  'airport': 'JAI',
  'startDate': '2026-12-10',
  'endDate': '2026-12-12',
  'days': 3,
  'travellers': 'couple',
  'pace': 'balanced',
  'budget': 'mid',
  'interests': ['history', 'food'],
  'currency': 'INR',
  'title': 'Jaipur Heritage and Flavors',
  'summary': 'Three balanced days of forts, bazaars and Rajasthani food.',
  'dayPlans': [dayJson(1, title: firstDay), dayJson(2), dayJson(3)],
  'tips': ['Use Uber or Ola for fair prices.'],
  'estimate': {
    'perDay': 3000,
    'stayPerNight': 5000,
    'nights': 2,
    'total': 19000,
  },
  'createdAt': '2026-11-08T10:00:00Z',
};

const jaipur = PlanPlace(
  placeId: 'p1',
  name: 'Jaipur',
  area: 'Rajasthan',
  country: 'India',
  lat: 26.9,
  lon: 75.8,
);

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  group('PlanService', () {
    test('create sends the form and returns the plan', () async {
      Object? sent;
      backend.on('POST', '/api/plans', (request) async {
        sent = jsonDecode(request.body);
        return FakeBackend.json(planJson(), 201);
      });
      final before = PlanService.changes.value;

      final plan = await PlanService.create(
        const PlanRequest(
          place: jaipur,
          startDate: '2026-12-10',
          days: 3,
          travellers: 'couple',
          pace: 'balanced',
          budget: 'mid',
          interests: ['history', 'food'],
        ),
      );

      expect(sent, {
        'place': {
          'placeId': 'p1',
          'name': 'Jaipur',
          'area': 'Rajasthan',
          'country': 'India',
          'lat': 26.9,
          'lon': 75.8,
        },
        'startDate': '2026-12-10',
        'days': 3,
        'travellers': 'couple',
        'pace': 'balanced',
        'budget': 'mid',
        'interests': ['history', 'food'],
      });
      expect(plan.title, 'Jaipur Heritage and Flavors');
      expect(plan.dayPlans, hasLength(3));
      expect(plan.dayPlans.first.evening.cost, 0);
      expect(plan.estimate.total, 19000);
      expect(plan.airport, 'JAI');
      expect(PlanService.changes.value, before + 1);
    });

    test('create passes on the limit message', () async {
      backend.on('POST', '/api/plans', (_) async {
        return FakeBackend.error(
          429,
          'rate_limited',
          "You've made 5 plans today. Please try again tomorrow.",
        );
      });

      await expectLater(
        PlanService.create(
          const PlanRequest(
            place: jaipur,
            startDate: '2026-12-10',
            days: 3,
            travellers: 'solo',
            pace: 'relaxed',
            budget: 'budget',
            interests: [],
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('5 plans today'),
          ),
        ),
      );
    });

    test('list skips entries that are not plans', () async {
      backend.on('GET', '/api/plans', (_) async {
        return FakeBackend.json([
          {
            'id': 'abc123def456',
            'title': 'Jaipur Heritage and Flavors',
            'placeName': 'Jaipur',
            'country': 'India',
            'startDate': '2026-12-10',
            'days': 3,
            'shared': true,
          },
          {'id': 'broken'},
        ]);
      });

      final plans = await PlanService.list();

      expect(plans, hasLength(1));
      expect(plans.single.shared, isTrue);
    });

    test('changeDay sends the wish, share sends the switch', () async {
      Object? wish;
      Object? share;
      backend.on('POST', '/api/plans/abc123def456/days/2', (request) async {
        wish = jsonDecode(request.body);
        return FakeBackend.json(planJson());
      });
      backend.on('PUT', '/api/plans/abc123def456/share', (request) async {
        share = jsonDecode(request.body);
        return FakeBackend.json(planJson(shared: true));
      });

      await PlanService.changeDay('abc123def456', 2, 'more street food');
      final shared = await PlanService.share('abc123def456', shared: true);

      expect(wish, {'wish': 'more street food'});
      expect(share, {'shared': true});
      expect(shared.shared, isTrue);
    });

    test('delete expects 204', () async {
      backend.on('DELETE', '/api/plans/abc123def456', (_) async {
        return FakeBackend.json('', 204);
      });

      await PlanService.delete('abc123def456');

      expect(backend.count('DELETE', '/api/plans/abc123def456'), 1);
    });
  });

  group('plan helpers', () {
    test('the shared link is the website page', () {
      expect(
        PlanService.sharedLink('abc', 'https://staging.goawaygo.com/'),
        'https://staging.goawaygo.com/plans/shared/abc',
      );
      expect(PlanService.sharedLink('abc', ' '), isNull);
    });

    test('a one-day plan leaves the next day; longer plans on the last', () {
      expect(
        PlanService.leaveDate('2026-12-31', '2026-12-31', 1),
        '2027-01-01',
      );
      expect(
        PlanService.leaveDate('2026-12-10', '2026-12-12', 3),
        '2026-12-12',
      );
      expect(PlanService.endDate('2026-12-30', 3), '2027-01-01');
    });

    test('who is going sets guests and rooms', () {
      expect(PlanService.party('solo'), (guests: 1, rooms: 1));
      expect(PlanService.party('couple'), (guests: 2, rooms: 1));
      expect(PlanService.party('family'), (guests: 4, rooms: 1));
      expect(PlanService.party('friends'), (guests: 4, rooms: 2));
    });

    test('a destination plans with its region, or its city', () {
      const place = Place(
        id: 'p1',
        name: 'Amer',
        type: 'place',
        city: 'Jaipur',
        region: '',
        country: 'India',
        countryCode: 'in',
        lat: 26.98,
        lon: 75.85,
        label: 'Amer, Jaipur, India',
      );

      final planPlace = PlanPlace.fromPlace(place);

      expect(planPlace.area, 'Jaipur');
      expect(planPlace.placeId, 'p1');
      expect(planPlace.where, 'Jaipur, India');
    });

    test('labels come from the options', () {
      expect(PlanOption.labelOf(PlanOptions.budgets, 'mid'), 'Mid-range');
      expect(PlanOption.labelOf(PlanOptions.budgets, 'odd'), 'odd');
    });
  });
}
