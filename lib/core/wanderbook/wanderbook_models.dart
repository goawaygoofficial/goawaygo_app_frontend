/// Shapes of the backend's Wanderbook API (`/api/wanderbook/*`), the same as the website's
/// `features/wanderbook/types.ts`. Decided for 4.2 (see ROADMAP.md).
library;

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:intl/intl.dart';

String _string(Object? value) => value is String ? value : '';

int _int(Object? value) => value is num ? value.toInt() : 0;

/// Keeps the entries that have the expected shape; anything that isn't a list counts as empty.
List<T> listOf<T>(Object? json, T? Function(Object?) parse) =>
    json is List ? json.map(parse).whereType<T>().toList() : <T>[];

/// A person in a list, a search result, or a post's author.
class Person {
  const Person({
    required this.publicId,
    required this.name,
    this.photoUrl,
    this.homeTown = '',
    this.isPrivate = false,
  });

  final String publicId, name, homeTown;
  final String? photoUrl;
  final bool isPrivate;

  static Person? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['publicId'] is! String ||
        json['name'] is! String) {
      return null;
    }
    return Person(
      publicId: json['publicId'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      homeTown: _string(json['homeTown']),
      isPrivate: json['isPrivate'] == true,
    );
  }
}

/// `self`, `following`, `requested` or `none`.
enum Relationship { self, following, requested, none }

/// A profile as the viewer sees it.
class Profile {
  const Profile({
    required this.publicId,
    required this.name,
    this.photoUrl,
    this.coverUrl,
    required this.bio,
    required this.homeTown,
    required this.isPrivate,
    required this.posts,
    required this.followers,
    required this.following,
    required this.relationship,
    required this.followsYou,
    required this.blockedByYou,
    required this.canSeePosts,
    this.followRequests,
  });

  final String publicId, name, bio, homeTown;
  final String? photoUrl, coverUrl;
  final bool isPrivate, followsYou, blockedByYou;

  /// False for a private profile the viewer doesn't follow.
  final bool canSeePosts;
  final int posts, followers, following;
  final Relationship relationship;

  /// Waiting follow requests: only on your own profile.
  final int? followRequests;

  static Profile? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['publicId'] is! String) {
      return null;
    }
    return Profile(
      publicId: json['publicId'] as String,
      name: _string(json['name']),
      photoUrl: json['photoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      bio: _string(json['bio']),
      homeTown: _string(json['homeTown']),
      isPrivate: json['isPrivate'] == true,
      posts: _int(json['posts']),
      followers: _int(json['followers']),
      following: _int(json['following']),
      relationship: Relationship.values.firstWhere(
        (r) => r.name == json['relationship'],
        orElse: () => Relationship.none,
      ),
      followsYou: json['followsYou'] == true,
      blockedByYou: json['blockedByYou'] == true,
      canSeePosts: json['canSeePosts'] == true,
      followRequests: json['followRequests'] is num
          ? (json['followRequests'] as num).toInt()
          : null,
    );
  }
}

/// A page of a list; [nextCursor] is null on the last page.
class Paged<T> {
  const Paged(this.items, this.nextCursor);

  final List<T> items;
  final int? nextCursor;

  static Paged<T> fromJson<T>(Object? json, T? Function(Object?) parse) {
    if (json is! Map<String, dynamic>) return Paged(<T>[], null);
    final next = json['nextCursor'];
    return Paged(
      listOf(json['items'], parse),
      next is num ? next.toInt() : null,
    );
  }
}

class Photo {
  const Photo({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
  });

  final String id, url;
  final int width, height;

  static Photo? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! String ||
        json['url'] is! String) {
      return null;
    }
    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      width: _int(json['width']),
      height: _int(json['height']),
    );
  }
}

/// A place tag: names only (exact coordinates are never stored).
class PlaceTag {
  const PlaceTag({required this.name, this.region = '', this.country = ''});

  final String name, region, country;

  static PlaceTag? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['name'] is! String) return null;
    return PlaceTag(
      name: json['name'] as String,
      region: _string(json['region']),
      country: _string(json['country']),
    );
  }

  Map<String, String> toJson() => {
    'name': name,
    'region': region,
    'country': country,
  };

  String get label =>
      [name, region, country].where((part) => part.isNotEmpty).join(', ');
}

class Post {
  const Post({
    required this.publicId,
    required this.author,
    required this.caption,
    this.place,
    required this.photos,
    required this.likes,
    required this.comments,
    required this.likedByYou,
    required this.isYours,
    required this.createdAt,
    this.editedAt,
  });

  final String publicId, caption;
  final Person author;
  final PlaceTag? place;
  final List<Photo> photos;
  final int likes, comments;
  final bool likedByYou, isYours;
  final DateTime createdAt;
  final DateTime? editedAt;

  static Post? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['publicId'] is! String) {
      return null;
    }
    final author = Person.fromJson(json['author']);
    if (author == null) return null;
    return Post(
      publicId: json['publicId'] as String,
      author: author,
      caption: _string(json['caption']),
      place: PlaceTag.fromJson(json['place']),
      photos: listOf(json['photos'], Photo.fromJson),
      likes: _int(json['likes']),
      comments: _int(json['comments']),
      likedByYou: json['likedByYou'] == true,
      isYours: json['isYours'] == true,
      createdAt:
          DateTime.tryParse(_string(json['createdAt'])) ?? DateTime.now(),
      editedAt: DateTime.tryParse(_string(json['editedAt'])),
    );
  }

  Post copyWith({bool? likedByYou, int? likes, int? comments}) => Post(
    publicId: publicId,
    author: author,
    caption: caption,
    place: place,
    photos: photos,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    likedByYou: likedByYou ?? this.likedByYou,
    isYours: isYours,
    createdAt: createdAt,
    editedAt: editedAt,
  );
}

class Comment {
  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.canDelete,
  });

  final int id;
  final Person author;
  final String text;
  final DateTime createdAt;
  final bool canDelete;

  static Comment? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! num) return null;
    final author = Person.fromJson(json['author']);
    if (author == null) return null;
    return Comment(
      id: (json['id'] as num).toInt(),
      author: author,
      text: _string(json['text']),
      createdAt:
          DateTime.tryParse(_string(json['createdAt'])) ?? DateTime.now(),
      canDelete: json['canDelete'] == true,
    );
  }
}

/// An upload, with the place its location suggests.
class Uploaded {
  const Uploaded(this.photo, this.suggestedPlace);

  final Photo photo;
  final PlaceTag? suggestedPlace;

  static Uploaded? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final photo = Photo.fromJson(json['photo']);
    return photo == null
        ? null
        : Uploaded(photo, PlaceTag.fromJson(json['suggestedPlace']));
  }
}

/// Report reasons (the backend's ReportService.REASONS) with their labels.
const reportReasons = <String, String>{
  'spam': 'Spam or scam',
  'nudity': 'Nudity or sexual content',
  'violence': 'Violence or dangerous acts',
  'hate': 'Hate speech or symbols',
  'harassment': 'Bullying or harassment',
  'self_harm': 'Self-harm',
  'illegal': 'Illegal goods or activity',
  'false_information': 'False information',
  'other': 'Something else',
};

/// "3 min", "5 h", "2 d", or the date for older things.
String timeAgo(DateTime time) {
  final seconds = DateTime.now().difference(time).inSeconds;
  if (seconds < 60) return tr('now');
  if (seconds < 3600) return tr('{0} min', [seconds ~/ 60]);
  if (seconds < 86400) return tr('{0} h', [seconds ~/ 3600]);
  if (seconds < 7 * 86400) return tr('{0} d', [seconds ~/ 86400]);
  return DateFormat.yMMMd(I18n.locale).format(time);
}
