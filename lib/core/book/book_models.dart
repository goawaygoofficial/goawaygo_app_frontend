import 'package:app_frontend/core/discover/discover_models.dart';

/// A city or airport to fly from or to (a city code covers all its airports).
class Airport {
  const Airport({
    required this.code,
    required this.type,
    required this.name,
    this.city = '',
    this.country = '',
  });

  /// IATA code, e.g. `DEL`.
  final String code;

  /// `city` or `airport`.
  final String type;
  final String name;

  /// The airport's city; empty for a city.
  final String city;
  final String country;

  bool get isAirport => type == 'airport';

  /// "Indira Gandhi International Airport (DEL)" / "New Delhi (DEL), India"
  String get label => isAirport
      ? '$name ($code)'
      : '$name ($code)${country.isEmpty ? '' : ', $country'}';

  static Airport? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final code = json['code'];
    final name = json['name'];
    final type = json['type'];
    if (code is! String ||
        name is! String ||
        (type != 'city' && type != 'airport')) {
      return null;
    }
    return Airport(
      code: code,
      type: type as String,
      name: name,
      city: json['city'] is String ? json['city'] as String : '',
      country: json['country'] is String ? json['country'] as String : '',
    );
  }
}

/// One fare as Aviasales last saw it (a recent price, not a live one).
class Fare {
  const Fare({
    required this.origin,
    required this.destination,
    required this.airline,
    required this.airlineName,
    required this.departAt,
    required this.returnAt,
    required this.stops,
    required this.returnStops,
    required this.durationMinutes,
    required this.price,
    required this.link,
  });

  final String origin;
  final String destination;

  /// IATA airline code, e.g. `6E`.
  final String airline;
  final String airlineName;

  /// Departure in the airport's local time, ISO 8601 with offset.
  final String departAt;
  final String? returnAt;
  final int stops;
  final int? returnStops;
  final int? durationMinutes;

  /// Per adult, in [FlightResults.currency].
  final int price;

  /// Our affiliate link to this fare on Aviasales.
  final String link;

  static Fare? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final price = json['price'];
    final departAt = json['departAt'];
    final link = json['link'];
    final airline = json['airline'];
    if (price is! num ||
        departAt is! String ||
        link is! String ||
        airline is! String) {
      return null;
    }
    return Fare(
      origin: json['origin'] is String ? json['origin'] as String : '',
      destination: json['destination'] is String
          ? json['destination'] as String
          : '',
      airline: airline,
      airlineName: json['airlineName'] is String
          ? json['airlineName'] as String
          : airline,
      departAt: departAt,
      returnAt: json['returnAt'] is String ? json['returnAt'] as String : null,
      stops: json['stops'] is num ? (json['stops'] as num).toInt() : 0,
      returnStops: json['returnStops'] is num
          ? (json['returnStops'] as num).toInt()
          : null,
      durationMinutes: json['durationMinutes'] is num
          ? (json['durationMinutes'] as num).toInt()
          : null,
      price: price.round(),
      link: link,
    );
  }
}

class FlightResults {
  const FlightResults({
    required this.currency,
    required this.onDate,
    required this.nearby,
    required this.searchLink,
  });

  final String currency;

  /// The cheapest fares on the dates asked (often one, sometimes none).
  final List<Fare> onDate;

  /// The cheapest fares on other dates of the same month, cheapest first.
  final List<Fare> nearby;

  /// Aviasales' live search for exactly this trip.
  final String searchLink;

  static FlightResults? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final currency = json['currency'];
    final searchLink = json['searchLink'];
    if (currency is! String || searchLink is! String) return null;
    return FlightResults(
      currency: currency,
      onDate: parseList(json['onDate'], Fare.fromJson),
      nearby: parseList(json['nearby'], Fare.fromJson),
      searchLink: searchLink,
    );
  }
}

/// A partner card: opens the partner's own search with the traveller's place and dates.
class PartnerCard {
  const PartnerCard({required this.id, required this.name, required this.link});

  final String id;
  final String name;
  final String link;

  static PartnerCard? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['name'];
    final link = json['link'];
    if (id is! String || name is! String || link is! String) return null;
    return PartnerCard(id: id, name: name, link: link);
  }
}

class FlightSearch {
  const FlightSearch({
    required this.from,
    required this.to,
    required this.depart,
    this.returnDate,
    this.adults = 1,
  });

  final Airport from;
  final Airport to;

  /// `YYYY-MM-DD`
  final String depart;

  /// `YYYY-MM-DD`; null for one way.
  final String? returnDate;
  final int adults;
}

class StaySearch {
  const StaySearch({
    required this.place,
    required this.checkin,
    required this.checkout,
    this.adults = 2,
    this.rooms = 1,
  });

  final String place;
  final String checkin;
  final String checkout;
  final int adults;
  final int rooms;
}

class CarSearch {
  const CarSearch({
    required this.place,
    this.airport,
    required this.pickup,
    required this.dropoff,
  });

  final String place;

  /// IATA code when an airport was picked.
  final String? airport;
  final String pickup;
  final String dropoff;
}
