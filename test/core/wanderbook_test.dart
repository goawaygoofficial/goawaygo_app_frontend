import 'dart:convert';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> personJson([String name = 'Asha']) => {
  'publicId': '0123456789ab',
  'name': name,
  'photoUrl': null,
  'homeTown': 'Pune',
  'isPrivate': false,
};

Map<String, Object?> postJson() => {
  'publicId': 'aaaaaaaaaaaa',
  'author': personJson(),
  'caption': 'Lake day',
  'place': {'name': 'Hallstatt', 'region': '', 'country': 'Austria'},
  'photos': [
    {
      'id': 'p1',
      'url': 'https://media.test/p/1.jpg',
      'width': 4000,
      'height': 3000,
    },
    {'url': 'missing id'},
  ],
  'likes': 3,
  'comments': 1,
  'likedByYou': true,
  'isYours': false,
  'createdAt': '2026-10-30T10:00:00Z',
  'editedAt': null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wanderbook models', () {
    test('a post keeps its photos in order and drops odd entries', () {
      final post = Post.fromJson(postJson())!;
      expect(post.photos.map((p) => p.id), ['p1']);
      expect(post.place!.label, 'Hallstatt, Austria');
      expect(post.likedByYou, isTrue);
      expect(post.editedAt, isNull);
      expect(Post.fromJson({'publicId': 'x'}), isNull); // no author
    });

    test(
      'a profile reads its relationship and only shows requests when given',
      () {
        final profile = Profile.fromJson({
          'publicId': 'bbbbbbbbbbbb',
          'name': 'Ben',
          'bio': '',
          'homeTown': '',
          'isPrivate': true,
          'posts': 2,
          'followers': 5,
          'following': 1,
          'relationship': 'requested',
          'followsYou': false,
          'blockedByYou': false,
          'canSeePosts': false,
        })!;
        expect(profile.relationship, Relationship.requested);
        expect(profile.followRequests, isNull);
        expect(
          Profile.fromJson({'publicId': 'x', 'relationship': 'odd'})!
              .relationship,
          Relationship.none,
        );
      },
    );

    test('pages carry the cursor of the next page', () {
      final page = Paged.fromJson({
        'items': [personJson(), 'not a person'],
        'nextCursor': 42,
      }, Person.fromJson);
      expect(page.items.single.name, 'Asha');
      expect(page.nextCursor, 42);
    });
  });

  group('WanderbookService', () {
    late FakeBackend backend;

    setUp(() => backend = FakeBackend());

    test('uploads the photo file untouched as multipart, and reads the suggested place', () async {
      backend.on(
        'POST',
        '/api/wanderbook/photos',
        (_) async => FakeBackend.json({
          'photo': {
            'id': 'p9',
            'url': 'https://media.test/p/9.jpg',
            'width': 10,
            'height': 5,
          },
          'suggestedPlace': {
            'name': 'Paris',
            'region': 'Ile-de-France',
            'country': 'France',
          },
        }),
      );
      final bytes = List<int>.generate(64, (i) => i);

      final uploaded = await WanderbookService.uploadPhoto(bytes, 'trip.jpg');

      final request = backend.requests.single;
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      final body = latin1.decode(request.bodyBytes);
      expect(body, contains('name="file"; filename="trip.jpg"'));
      expect(request.bodyBytes.length, greaterThan(bytes.length));
      expect(uploaded.photo.id, 'p9');
      expect(uploaded.suggestedPlace!.label, 'Paris, Ile-de-France, France');
    });

    test('an upload is sent again after the session is refreshed', () async {
      // Signed in with an access token that has since expired.
      backend.store.token = 'refresh-1';
      var refreshes = 0;
      backend.on('POST', '/api/auth/refresh', (_) async {
        refreshes++;
        return FakeBackend.session(
          accessToken: refreshes == 1 ? 'old' : 'new',
          refreshToken: 'refresh-${refreshes + 1}',
        );
      });
      await Backend.session.refresh();
      backend.on('POST', '/api/wanderbook/photos', (request) async {
        if (request.headers['authorization'] == 'Bearer old') {
          return FakeBackend.error(401, 'unauthorized', 'Expired');
        }
        return FakeBackend.json({
          'photo': {'id': 'p1', 'url': 'u', 'width': 1, 'height': 1},
        });
      });

      final uploaded = await WanderbookService.uploadPhoto([1, 2, 3], 'a.jpg');

      expect(uploaded.photo.id, 'p1');
      expect(backend.count('POST', '/api/wanderbook/photos'), 2);
    });

    test('refused content brings the backend message', () async {
      backend.on(
        'POST',
        '/api/wanderbook/posts',
        (_) async => FakeBackend.error(
          422,
          'content_not_allowed',
          'This text goes against our Community Guidelines, so it can\'t be posted.',
        ),
      );
      expect(
        () => WanderbookService.createPost(photoIds: ['p1'], caption: 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Community Guidelines'),
          ),
        ),
      );
    });

    test(
      'creating a post sends the photos in order, the caption and the place',
      () async {
        backend.on(
          'POST',
          '/api/wanderbook/posts',
          (_) async => FakeBackend.json(postJson(), 201),
        );

        await WanderbookService.createPost(
          photoIds: ['p2', 'p1'],
          caption: 'Lake day',
          place: const PlaceTag(name: 'Hallstatt', country: 'Austria'),
        );

        expect(jsonDecode(backend.requests.single.body), {
          'photoIds': ['p2', 'p1'],
          'caption': 'Lake day',
          'place': {'name': 'Hallstatt', 'region': '', 'country': 'Austria'},
        });
      },
    );
  });
}
