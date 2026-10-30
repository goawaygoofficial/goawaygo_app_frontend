import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';

/// The Wanderbook API (the same calls as the website's `wanderbookService.ts`). Viewing works signed out;
/// everything that changes something needs sign-in.
class WanderbookService {
  WanderbookService._();

  static const _unexpected = ApiException(
    'Unexpected response from the server.',
    200,
  );

  static String _before(int? cursor) => cursor == null ? '' : '?before=$cursor';

  static Future<Object?> _get(String path, String error) =>
      Backend.api.request('GET', path, fallbackError: error);

  // ---- profiles ----

  static Future<Profile> myProfile() async =>
      Profile.fromJson(
        await _get('/api/wanderbook/me', 'Could not load your profile.'),
      ) ??
      (throw _unexpected);

  static Future<Profile> profile(String publicId) async =>
      Profile.fromJson(
        await _get(
          '/api/wanderbook/profiles/$publicId',
          'Could not load this profile.',
        ),
      ) ??
      (throw _unexpected);

  static Future<Profile> updateMyProfile({
    required String bio,
    required String homeTown,
    required bool isPrivate,
  }) async =>
      Profile.fromJson(
        await Backend.api.request(
          'PUT',
          '/api/wanderbook/me',
          body: {'bio': bio, 'homeTown': homeTown, 'isPrivate': isPrivate},
          fallbackError: 'Could not save your profile.',
        ),
      ) ??
      (throw _unexpected);

  /// [kind] `avatar` or `cover`; a null [photoId] removes it.
  static Future<Profile> setProfilePhoto(String kind, String? photoId) async =>
      Profile.fromJson(
        await Backend.api.request(
          'PUT',
          '/api/wanderbook/me/$kind',
          body: {'photoId': photoId},
          fallbackError: 'Could not change the photo.',
        ),
      ) ??
      (throw _unexpected);

  static Future<void> follow(String publicId, bool on) => Backend.api.request(
    on ? 'POST' : 'DELETE',
    '/api/wanderbook/profiles/$publicId/follow',
    fallbackError: on ? 'Could not follow.' : 'Could not unfollow.',
  );

  static Future<void> block(String publicId, bool on) => Backend.api.request(
    on ? 'POST' : 'DELETE',
    '/api/wanderbook/profiles/$publicId/block',
    fallbackError: on ? 'Could not block.' : 'Could not unblock.',
  );

  /// [list] `followers` or `following`.
  static Future<Paged<Person>> follows(
    String publicId,
    String list, [
    int? cursor,
  ]) async => Paged.fromJson(
    await _get(
      '/api/wanderbook/profiles/$publicId/$list${_before(cursor)}',
      'Could not load the list.',
    ),
    Person.fromJson,
  );

  static Future<Paged<Person>> followRequests([int? cursor]) async =>
      Paged.fromJson(
        await _get(
          '/api/wanderbook/me/follow-requests${_before(cursor)}',
          'Could not load follow requests.',
        ),
        Person.fromJson,
      );

  static Future<void> answerFollowRequest(String publicId, bool approve) =>
      Backend.api.request(
        approve ? 'POST' : 'DELETE',
        '/api/wanderbook/me/follow-requests/$publicId',
        expectedStatus: 204,
        fallbackError: 'Could not answer the request.',
      );

  static Future<void> removeFollower(String publicId) => Backend.api.request(
    'DELETE',
    '/api/wanderbook/me/followers/$publicId',
    expectedStatus: 204,
    fallbackError: 'Could not remove this follower.',
  );

  static Future<List<Person>> blocked() async => listOf(
    await _get('/api/wanderbook/me/blocked', 'Could not load blocked people.'),
    Person.fromJson,
  );

  static Future<List<Person>> searchPeople(String text) async => listOf(
    await _get(
      '/api/wanderbook/people?q=${Uri.encodeQueryComponent(text)}',
      'Could not search.',
    ),
    Person.fromJson,
  );

  // ---- photos and posts ----

  /// Uploads one original photo. The backend removes its location data and checks it before storing.
  static Future<Uploaded> uploadPhoto(List<int> bytes, String filename) async =>
      Uploaded.fromJson(
        await Backend.api.upload(
          '/api/wanderbook/photos',
          field: 'file',
          bytes: bytes,
          filename: filename,
          fallbackError: 'Could not upload this photo.',
        ),
      ) ??
      (throw _unexpected);

  static Future<Post> createPost({
    required List<String> photoIds,
    required String caption,
    PlaceTag? place,
  }) async =>
      Post.fromJson(
        await Backend.api.request(
          'POST',
          '/api/wanderbook/posts',
          body: {
            'photoIds': photoIds,
            'caption': caption,
            'place': place?.toJson(),
          },
          expectedStatus: 201,
          fallbackError: 'Could not post.',
        ),
      ) ??
      (throw _unexpected);

  static Future<Post> post(String publicId) async =>
      Post.fromJson(
        await _get(
          '/api/wanderbook/posts/$publicId',
          'Could not load this post.',
        ),
      ) ??
      (throw _unexpected);

  static Future<Post> editPost(
    String publicId, {
    required String caption,
    PlaceTag? place,
  }) async =>
      Post.fromJson(
        await Backend.api.request(
          'PUT',
          '/api/wanderbook/posts/$publicId',
          body: {'caption': caption, 'place': place?.toJson()},
          fallbackError: 'Could not save the post.',
        ),
      ) ??
      (throw _unexpected);

  static Future<void> deletePost(String publicId) => Backend.api.request(
    'DELETE',
    '/api/wanderbook/posts/$publicId',
    expectedStatus: 204,
    fallbackError: 'Could not delete the post.',
  );

  static Future<Paged<Post>> feed([int? cursor]) async => Paged.fromJson(
    await _get(
      '/api/wanderbook/feed${_before(cursor)}',
      'Could not load the feed.',
    ),
    Post.fromJson,
  );

  static Future<Paged<Post>> profilePosts(
    String publicId, [
    int? cursor,
  ]) async => Paged.fromJson(
    await _get(
      '/api/wanderbook/profiles/$publicId/posts${_before(cursor)}',
      'Could not load posts.',
    ),
    Post.fromJson,
  );

  static Future<Post> like(String publicId, bool on) async =>
      Post.fromJson(
        await Backend.api.request(
          on ? 'POST' : 'DELETE',
          '/api/wanderbook/posts/$publicId/like',
          fallbackError: 'Could not like this post.',
        ),
      ) ??
      (throw _unexpected);

  static Future<List<Person>> likes(String publicId) async => listOf(
    await _get(
      '/api/wanderbook/posts/$publicId/likes',
      'Could not load likes.',
    ),
    Person.fromJson,
  );

  static Future<Paged<Comment>> comments(
    String publicId, [
    int? after,
  ]) async => Paged.fromJson(
    await _get(
      '/api/wanderbook/posts/$publicId/comments${after == null ? '' : '?after=$after'}',
      'Could not load comments.',
    ),
    Comment.fromJson,
  );

  static Future<Comment> addComment(String publicId, String text) async =>
      Comment.fromJson(
        await Backend.api.request(
          'POST',
          '/api/wanderbook/posts/$publicId/comments',
          body: {'text': text},
          expectedStatus: 201,
          fallbackError: 'Could not comment.',
        ),
      ) ??
      (throw _unexpected);

  static Future<void> deleteComment(int id) => Backend.api.request(
    'DELETE',
    '/api/wanderbook/comments/$id',
    expectedStatus: 204,
    fallbackError: 'Could not delete the comment.',
  );

  /// [targetType] `post`, `comment` or `user`; [target] the post's or profile's public id, or the comment id.
  static Future<void> report({
    required String targetType,
    required String target,
    required String reason,
    String details = '',
  }) => Backend.api.request(
    'POST',
    '/api/wanderbook/reports',
    body: {
      'targetType': targetType,
      'target': target,
      'reason': reason,
      'details': details,
    },
    expectedStatus: 204,
    fallbackError: 'Could not send the report.',
  );
}
