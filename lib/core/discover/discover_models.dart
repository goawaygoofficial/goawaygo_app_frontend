/// Shapes of the backend's Discover API (`/api/discover/*`, `/api/me/saved-places`), the same as the website's
/// `features/discover/types.ts`. See backend `docs/destination-prompts.md`.
library;

String _string(Object? value) => value is String ? value : '';

double _double(Object? value) => value is num ? value.toDouble() : 0;

/// A real place found by the place search (Geoapify).
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.region,
    required this.country,
    required this.countryCode,
    required this.lat,
    required this.lon,
    required this.label,
  });

  /// `country`, `region`, `city` or `place`.
  final String id, name, type, city, region, country, countryCode, label;
  final double lat, lon;

  /// Null if the JSON isn't a place.
  static Place? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    if (json['name'] is! String ||
        json['label'] is! String ||
        json['lat'] is! num ||
        json['lon'] is! num) {
      return null;
    }
    return Place(
      id: _string(json['id']),
      name: json['name'] as String,
      type: _string(json['type']),
      city: _string(json['city']),
      region: _string(json['region']),
      country: _string(json['country']),
      countryCode: _string(json['countryCode']),
      lat: _double(json['lat']),
      lon: _double(json['lon']),
      label: json['label'] as String,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'city': city,
    'region': region,
    'country': country,
    'countryCode': countryCode,
    'lat': lat,
    'lon': lon,
    'label': label,
  };

  /// "Jaipur, Rajasthan, India" → "Rajasthan, India" (the name is shown separately).
  String get context {
    final prefix = '$name, ';
    if (label.startsWith(prefix)) return label.substring(prefix.length);
    return label == name ? (name == country ? '' : country) : label;
  }
}

/// A photo and its required credit (Wikimedia Commons or Unsplash).
class Photo {
  const Photo({
    required this.url,
    required this.credit,
    required this.creditUrl,
  });

  final String url, credit, creditUrl;

  static Photo? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['url'] is! String ||
        json['credit'] is! String) {
      return null;
    }
    return Photo(
      url: json['url'] as String,
      credit: json['credit'] as String,
      creditUrl: _string(json['creditUrl']),
    );
  }
}

class CardItem {
  const CardItem({
    required this.label,
    required this.detail,
    required this.mayChange,
    this.link,
  });

  final String label, detail;

  /// Prices, rates, dates, opening hours…: shown with "May vary".
  final bool mayChange;

  /// An official https link the backend checked.
  final String? link;

  static CardItem? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['label'] is! String ||
        json['detail'] is! String) {
      return null;
    }
    final link = json['link'];
    return CardItem(
      label: json['label'] as String,
      detail: json['detail'] as String,
      mayChange: json['mayChange'] == true,
      link: link is String && link.startsWith('https://') ? link : null,
    );
  }
}

/// One of the nine AI cards. Not [available]: nothing passed the backend's checks.
class InfoCard {
  const InfoCard({
    required this.id,
    required this.available,
    required this.items,
  });

  final String id;
  final bool available;
  final List<CardItem> items;

  static InfoCard? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! String) return null;
    final items = parseList(json['items'], CardItem.fromJson);
    return InfoCard(
      id: json['id'] as String,
      available: json['available'] == true && items.isNotEmpty,
      items: items,
    );
  }
}

class Spot {
  const Spot({required this.name, required this.photo});

  final String name;
  final Photo photo;

  static Spot? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['name'] is! String) return null;
    final photo = Photo.fromJson(json['photo']);
    return photo == null
        ? null
        : Spot(name: json['name'] as String, photo: photo);
  }
}

/// `ok`: cards and photos. `busy`: the AI couldn't answer right now (photos still shown). `unknown`: the AI
/// doesn't know this place.
enum DestinationStatus { ok, busy, unknown }

class DestinationPage {
  const DestinationPage({
    required this.place,
    required this.status,
    required this.cards,
    required this.spots,
  });

  final Place place;
  final DestinationStatus status;
  final List<InfoCard> cards;
  final List<Spot> spots;

  static DestinationPage? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final place = Place.fromJson(json['place']);
    if (place == null) return null;
    return DestinationPage(
      place: place,
      status: switch (json['status']) {
        'ok' => DestinationStatus.ok,
        'unknown' => DestinationStatus.unknown,
        _ => DestinationStatus.busy,
      },
      cards: parseList(json['cards'], InfoCard.fromJson),
      spots: parseList(json['spots'], Spot.fromJson),
    );
  }
}

/// One slide of the home banner: a searched place and a photo of its top spot (null if none was found).
class BannerSlide {
  const BannerSlide({required this.place, required this.spot, this.photo});

  final Place place;
  final String spot;
  final Photo? photo;

  static BannerSlide? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['spot'] is! String) return null;
    final place = Place.fromJson(json['place']);
    if (place == null) return null;
    return BannerSlide(
      place: place,
      spot: json['spot'] as String,
      photo: Photo.fromJson(json['photo']),
    );
  }
}

/// A searched place kept on this device for signed-out users (the account keeps them when signed in).
class RecentSearch {
  const RecentSearch({required this.place, required this.spot});

  final Place place;

  /// The place's top spot when it was searched; its photo is looked up live.
  final String spot;

  static RecentSearch? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['spot'] is! String) return null;
    final place = Place.fromJson(json['place']);
    return place == null
        ? null
        : RecentSearch(place: place, spot: json['spot'] as String);
  }

  Map<String, Object> toJson() => {'place': place.toJson(), 'spot': spot};
}

/// "Ideas for your next trip": a real place the backend confirmed on Wikipedia.
class TripIdea {
  const TripIdea({
    required this.id,
    required this.name,
    required this.area,
    required this.country,
    required this.category,
    required this.hiddenGem,
    required this.summary,
    required this.lat,
    required this.lon,
    required this.photo,
  });

  /// Stable for the same place ("hallstatt|austria"); the saved-place key.
  final String id, name, area, country, category, summary;
  final bool hiddenGem;
  final double lat, lon;
  final Photo photo;

  static TripIdea? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! String ||
        json['name'] is! String ||
        json['country'] is! String) {
      return null;
    }
    final photo = Photo.fromJson(json['photo']);
    if (photo == null) return null;
    return TripIdea(
      id: json['id'] as String,
      name: json['name'] as String,
      area: _string(json['area']),
      country: json['country'] as String,
      category: _string(json['category']),
      hiddenGem: json['kind'] == 'hidden gem',
      summary: _string(json['summary']),
      lat: _double(json['lat']),
      lon: _double(json['lon']),
      photo: photo,
    );
  }

  String get where => [area, country].where((s) => s.isNotEmpty).join(', ');
}

/// A place in My Trips.
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.key,
    required this.name,
    required this.area,
    required this.country,
    required this.category,
  });

  final int id;
  final String key, name, area, country, category;

  static SavedPlace? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! int ||
        json['key'] is! String ||
        json['name'] is! String) {
      return null;
    }
    return SavedPlace(
      id: json['id'] as int,
      key: json['key'] as String,
      name: json['name'] as String,
      area: _string(json['area']),
      country: _string(json['country']),
      category: _string(json['category']),
    );
  }

  String get where => [area, country].where((s) => s.isNotEmpty).join(', ');
}

/// Keeps the entries that have the expected shape, so one odd entry can't break a whole list. Anything that
/// isn't a list counts as empty.
List<T> parseList<T>(Object? json, T? Function(Object?) parse) =>
    json is List ? json.map(parse).whereType<T>().toList() : <T>[];
