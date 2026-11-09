import 'package:app_frontend/core/discover/discover_models.dart';

/// "Confirm it's you" before changing the password or email, or deleting the account: the current password, or a
/// fresh Google ID token for accounts without a password.
class Proof {
  const Proof.password(String this.password) : googleIdToken = null;
  const Proof.google(String this.googleIdToken) : password = null;

  final String? password;
  final String? googleIdToken;

  Map<String, String> toJson() => {
    'password': ?password,
    'googleIdToken': ?googleIdToken,
  };
}

class Country {
  const Country(this.code, this.name, this.currency);

  final String code, name;

  /// The country's currency (ISO 4217), or null (e.g. Antarctica).
  final String? currency;
}

class CurrencyOption {
  const CurrencyOption(this.code, this.name, this.symbol);

  final String code, name, symbol;

  /// "INR · Indian Rupee (₹)"
  String get label =>
      symbol == code ? '$code · $name' : '$code · $name ($symbol)';
}

/// The countries and currencies a user can pick.
class Regions {
  const Regions(this.countries, this.currencies);

  final List<Country> countries;
  final List<CurrencyOption> currencies;

  static Regions fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final countries = <Country>[];
    for (final c
        in map['countries'] is List ? map['countries'] as List : const []) {
      if (c is Map && c['code'] is String && c['name'] is String) {
        countries.add(
          Country(
            c['code'] as String,
            c['name'] as String,
            c['currency'] is String ? c['currency'] as String : null,
          ),
        );
      }
    }
    final currencies = <CurrencyOption>[];
    for (final c
        in map['currencies'] is List ? map['currencies'] as List : const []) {
      if (c is Map && c['code'] is String && c['name'] is String) {
        currencies.add(
          CurrencyOption(
            c['code'] as String,
            c['name'] as String,
            c['symbol'] is String ? c['symbol'] as String : c['code'] as String,
          ),
        );
      }
    }
    return Regions(countries, currencies);
  }

  String? countryName(String? code) {
    if (code == null) return null;
    for (final c in countries) {
      if (c.code == code) return c.name;
    }
    return code;
  }
}

class ViewedPlace {
  const ViewedPlace(this.place, this.viewedAt);

  final Place place;
  final DateTime? viewedAt;
}

class ViewedPlan {
  const ViewedPlan({
    required this.id,
    required this.title,
    required this.placeName,
    required this.country,
    required this.mine,
    this.viewedAt,
  });

  final String id, title, placeName, country;

  /// The viewer's own plan; otherwise one shared with them by link.
  final bool mine;
  final DateTime? viewedAt;
}

/// Places and trip plans the signed-in user opened, newest first.
class RecentlyViewed {
  const RecentlyViewed(this.places, this.plans);

  final List<ViewedPlace> places;
  final List<ViewedPlan> plans;

  bool get isEmpty => places.isEmpty && plans.isEmpty;

  static RecentlyViewed fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    DateTime? time(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    final places = <ViewedPlace>[];
    for (final item
        in map['places'] is List ? map['places'] as List : const []) {
      if (item is! Map<String, dynamic>) continue;
      final place = Place.fromJson(item['place']);
      if (place != null) places.add(ViewedPlace(place, time(item['viewedAt'])));
    }
    final plans = <ViewedPlan>[];
    for (final item in map['plans'] is List ? map['plans'] as List : const []) {
      if (item is! Map<String, dynamic> ||
          item['id'] is! String ||
          item['title'] is! String ||
          item['placeName'] is! String) {
        continue;
      }
      plans.add(
        ViewedPlan(
          id: item['id'] as String,
          title: item['title'] as String,
          placeName: item['placeName'] as String,
          country: item['country'] is String ? item['country'] as String : '',
          mine: item['mine'] == true,
          viewedAt: time(item['viewedAt']),
        ),
      );
    }
    return RecentlyViewed(places, plans);
  }
}
