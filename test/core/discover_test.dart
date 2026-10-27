import 'dart:convert';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/discover/recent_searches_store.dart';
import 'package:app_frontend/features/06_destinationInfo/utils/card_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> placeJson({String name = 'Jaipur', String id = 'p-1'}) => {
  'id': id,
  'name': name,
  'type': 'city',
  'city': '',
  'region': 'Rajasthan',
  'country': 'India',
  'countryCode': 'IN',
  'lat': 26.9,
  'lon': 75.8,
  'label': '$name, Rajasthan, India',
};

Map<String, Object?> photoJson(String url) => {
  'url': url,
  'credit': 'Photo: Jane, CC BY-SA 4.0, Wikimedia Commons',
  'creditUrl': 'https://commons.wikimedia.org/wiki/File:x.jpg',
  'source': 'wikimedia',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discover models', () {
    test('a destination page keeps each card separate, drops odd entries and non-https links', () {
      final page = DestinationPage.fromJson({
        'place': placeJson(),
        'status': 'ok',
        'model': 'gemini-3-flash-preview',
        'cards': [
          {
            'id': 'visa',
            'available': true,
            'items': [
              {
                'label': 'eVisa',
                'detail': 'Apply online',
                'mayChange': true,
                'link': 'https://indianvisaonline.gov.in',
              },
              {
                'label': 'Old site',
                'detail': 'x',
                'mayChange': false,
                'link': 'http://insecure.example',
              },
              {'label': 42},
            ],
          },
          {'id': 'hotels', 'available': false, 'items': []},
          'not a card',
        ],
        'spots': [
          {'name': 'Hawa Mahal', 'photo': photoJson('https://img/1.jpg')},
          {'name': 'No photo'},
        ],
      })!;

      expect(page.status, DestinationStatus.ok);
      expect(page.cards.map((c) => c.id), ['visa', 'hotels']);
      expect(page.cards[0].items.map((i) => i.label), ['eVisa', 'Old site']);
      expect(page.cards[0].items[0].mayChange, isTrue);
      expect(page.cards[0].items[0].link, 'https://indianvisaonline.gov.in');
      expect(page.cards[0].items[1].link, isNull);
      expect(page.cards[1].available, isFalse);
      expect(page.spots.map((s) => s.name), ['Hawa Mahal']);
      expect(page.place.context, 'Rajasthan, India');
    });

    test('an unexpected status counts as busy, and a page without a place is rejected', () {
      expect(
        DestinationPage.fromJson({'place': placeJson(), 'status': 'odd'})!
            .status,
        DestinationStatus.busy,
      );
      expect(DestinationPage.fromJson({'status': 'ok'}), isNull);
    });

    test('every card id the backend sends has a title on the page', () {
      expect(cardMeta.keys, [
        'quickFacts',
        'visa',
        'seasons',
        'attractions',
        'hotels',
        'cuisine',
        'transport',
        'insurance',
        'currency',
      ]);
    });
  });

  group('DiscoverService', () {
    late FakeBackend backend;

    setUp(() => backend = FakeBackend());

    test(
      'opens a picked place by its id, and a typed one by its text',
      () async {
        backend.on(
          'GET',
          '/api/discover/destination',
          (_) async => FakeBackend.json({
            'place': placeJson(),
            'status': 'busy',
            'cards': [],
            'spots': [],
          }),
        );

        await DiscoverService.getDestination(
          DestinationRequest.place(Place.fromJson(placeJson())!),
        );
        await DiscoverService.getDestination(
          const DestinationRequest.text('Hallstatt', 'Hallstatt, Austria'),
        );

        expect(backend.requests[0].url.queryParameters, {'placeId': 'p-1'});
        expect(backend.requests[1].url.queryParameters, {
          'q': 'Hallstatt, Austria',
        });
      },
    );

    test('a place that does not exist is a 404', () async {
      backend.on(
        'GET',
        '/api/discover/destination',
        (_) async => FakeBackend.error(
          404,
          'place_not_found',
          "We couldn't find that place.",
        ),
      );

      expect(
        () => DiscoverService.getDestination(
          const DestinationRequest.text('zzzz'),
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    });

    test(
      'photos for searches kept on the device keep the device places, in order',
      () async {
        backend.on(
          'POST',
          '/api/discover/photos',
          (_) async => FakeBackend.json([
            {
              'place': placeJson(id: ''),
              'spot': 'Amer Fort',
              'photo': photoJson('https://img/amer.jpg'),
            },
            {'place': placeJson(id: ''), 'spot': 'Somewhere', 'photo': null},
          ]),
        );
        final searches = [
          RecentSearch(place: Place.fromJson(placeJson())!, spot: 'Amer Fort'),
          RecentSearch(
            place: Place.fromJson(placeJson(name: 'Agra', id: 'p-2'))!,
            spot: 'Somewhere',
          ),
        ];

        final slides = await DiscoverService.getPhotosFor(searches);

        final sent = jsonDecode(backend.requests.single.body) as Map;
        expect((sent['items'] as List).first, {
          'spot': 'Amer Fort',
          'place': 'Jaipur',
          'type': 'city',
          'country': 'India',
          'lat': 26.9,
          'lon': 75.8,
        });
        expect(slides.map((s) => s.place.id), ['p-1', 'p-2']);
        expect(slides[0].photo?.url, 'https://img/amer.jpg');
        expect(slides[1].photo, isNull);
      },
    );

    test('ideas without a photo are left out; saving sends the idea as a saved place', () async {
      backend.on(
        'GET',
        '/api/discover/ideas',
        (_) async => FakeBackend.json([
          {
            'id': 'hallstatt|austria',
            'name': 'Hallstatt',
            'area': 'Upper Austria',
            'country': 'Austria',
            'category': 'old town',
            'kind': 'hidden gem',
            'summary': 'Lakeside village',
            'lat': 47.56,
            'lon': 13.64,
            'photo': photoJson('https://img/h.jpg'),
          },
          {'id': 'x', 'name': 'No photo', 'country': 'Nowhere'},
        ]),
      );
      backend.on(
        'POST',
        '/api/me/saved-places',
        (_) async => FakeBackend.json('', 204),
      );

      final ideas = await DiscoverService.getTripIdeas(6);
      await DiscoverService.saveIdea(ideas.single);

      expect(ideas.single.hiddenGem, isTrue);
      expect(ideas.single.where, 'Upper Austria, Austria');
      expect(jsonDecode(backend.requests.last.body), {
        'key': 'hallstatt|austria',
        'name': 'Hallstatt',
        'area': 'Upper Austria',
        'country': 'Austria',
        'lat': 47.56,
        'lon': 13.64,
        'category': 'old town',
      });
    });
  });

  group('RecentSearchesStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps the newest 5, each place once, newest first', () async {
      for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
        await RecentSearchesStore.remember(
          Place.fromJson(placeJson(name: name, id: name))!,
          '$name spot',
        );
      }
      await RecentSearchesStore.remember(
        Place.fromJson(placeJson(name: 'D', id: 'D'))!,
        null,
      );

      final searches = await RecentSearchesStore.read();
      expect(searches.map((s) => s.place.name), ['D', 'F', 'E', 'C', 'B']);
      expect(searches.first.spot, 'D');
    });

    test('unreadable stored data counts as no searches', () async {
      SharedPreferences.setMockInitialValues({
        'goawaygo.recentSearches': 'not json',
      });
      expect(await RecentSearchesStore.read(), isEmpty);
    });
  });
}
