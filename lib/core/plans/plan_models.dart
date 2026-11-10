/// Shapes of the backend's trip planner API (`/api/plans`), the same as the website's `features/plans/types.ts`.
library;

import 'package:app_frontend/core/discover/discover_models.dart';

String _string(Object? value) => value is String ? value : '';

int _int(Object? value) => value is num ? value.round() : 0;

double _double(Object? value) => value is num ? value.toDouble() : 0;

List<String> _strings(Object? value) => value is List
    ? value.whereType<String>().where((s) => s.isNotEmpty).toList()
    : <String>[];

/// A choice in the plan form, with its label (`couple` → "Couple").
class PlanOption {
  const PlanOption(this.value, this.label);

  final String value;
  final String label;

  /// The label of [value] in [options], or [value] itself.
  static String labelOf(List<PlanOption> options, String value) => options
      .firstWhere(
        (o) => o.value == value,
        orElse: () => PlanOption(value, value),
      )
      .label;
}

class PlanOptions {
  PlanOptions._();

  static const travellers = [
    PlanOption('solo', 'Solo'),
    PlanOption('couple', 'Couple'),
    PlanOption('family', 'Family'),
    PlanOption('friends', 'Friends'),
  ];

  static const paces = [
    PlanOption('relaxed', 'Relaxed'),
    PlanOption('balanced', 'Balanced'),
    PlanOption('packed', 'Packed'),
  ];

  static const budgets = [
    PlanOption('budget', 'Budget'),
    PlanOption('mid', 'Mid-range'),
    PlanOption('luxury', 'Luxury'),
  ];

  static const interests = [
    PlanOption('culture', 'Culture'),
    PlanOption('history', 'History'),
    PlanOption('food', 'Food'),
    PlanOption('nature', 'Nature'),
    PlanOption('adventure', 'Adventure'),
    PlanOption('beaches', 'Beaches'),
    PlanOption('nightlife', 'Nightlife'),
    PlanOption('shopping', 'Shopping'),
    PlanOption('art', 'Art'),
    PlanOption('relaxation', 'Relaxation'),
  ];

  static const maxDays = 10;
  static const maxInterests = 6;
}

/// Where a plan is for: a destination page's place or a place saved in My Trips.
class PlanPlace {
  const PlanPlace({
    this.placeId,
    required this.name,
    required this.area,
    required this.country,
    required this.lat,
    required this.lon,
  });

  /// A destination page's place (its region, or city, is the area).
  factory PlanPlace.fromPlace(Place place) => PlanPlace(
    placeId: place.id.isEmpty ? null : place.id,
    name: place.name,
    area: place.region.isNotEmpty ? place.region : place.city,
    country: place.country,
    lat: place.lat,
    lon: place.lon,
  );

  factory PlanPlace.fromSaved(SavedPlace place) => PlanPlace(
    name: place.name,
    area: place.area,
    country: place.country,
    lat: place.lat,
    lon: place.lon,
  );

  final String? placeId;
  final String name, area, country;
  final double lat, lon;

  /// "Rajasthan, India"
  String get where => [area, country].where((s) => s.isNotEmpty).join(', ');

  static PlanPlace? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['name'] is! String) return null;
    return PlanPlace(
      placeId: json['placeId'] is String ? json['placeId'] as String : null,
      name: json['name'] as String,
      area: _string(json['area']),
      country: _string(json['country']),
      lat: _double(json['lat']),
      lon: _double(json['lon']),
    );
  }

  Map<String, Object?> toJson() => {
    'placeId': placeId,
    'name': name,
    'area': area,
    'country': country,
    'lat': lat,
    'lon': lon,
  };
}

class PlanRequest {
  const PlanRequest({
    required this.place,
    required this.startDate,
    required this.days,
    required this.travellers,
    required this.pace,
    required this.budget,
    required this.interests,
  });

  final PlanPlace place;

  /// `YYYY-MM-DD`
  final String startDate;
  final int days;
  final String travellers, pace, budget;
  final List<String> interests;

  Map<String, Object?> toJson() => {
    'place': place.toJson(),
    'startDate': startDate,
    'days': days,
    'travellers': travellers,
    'pace': pace,
    'budget': budget,
    'interests': interests,
  };
}

/// One part of a day: where, what to do and its rough cost (whole group).
class Slot {
  const Slot({required this.place, required this.activity, required this.cost});

  final String place, activity;
  final int cost;

  static Slot? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['place'] is! String ||
        json['activity'] is! String) {
      return null;
    }
    return Slot(
      place: json['place'] as String,
      activity: json['activity'] as String,
      cost: _int(json['cost']),
    );
  }
}

class DayPlan {
  const DayPlan({
    required this.day,
    required this.date,
    required this.title,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.food,
    required this.tip,
    required this.cost,
  });

  final int day;

  /// `YYYY-MM-DD`
  final String date;
  final String title;
  final Slot morning, afternoon, evening;
  final List<String> food;
  final String tip;

  /// The day's food, local transport and activities, whole group.
  final int cost;

  static DayPlan? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['day'] is! int ||
        json['date'] is! String ||
        json['title'] is! String) {
      return null;
    }
    final morning = Slot.fromJson(json['morning']);
    final afternoon = Slot.fromJson(json['afternoon']);
    final evening = Slot.fromJson(json['evening']);
    if (morning == null || afternoon == null || evening == null) return null;
    return DayPlan(
      day: json['day'] as int,
      date: json['date'] as String,
      title: json['title'] as String,
      morning: morning,
      afternoon: afternoon,
      evening: evening,
      food: _strings(json['food']),
      tip: _string(json['tip']),
      cost: _int(json['cost']),
    );
  }
}

/// Rough costs for the whole group; flights never included.
class Estimate {
  const Estimate({
    required this.perDay,
    required this.stayPerNight,
    required this.nights,
    required this.total,
  });

  final int perDay, stayPerNight, nights, total;

  static Estimate fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return Estimate(
      perDay: _int(map['perDay']),
      stayPerNight: _int(map['stayPerNight']),
      nights: _int(map['nights']),
      total: _int(map['total']),
    );
  }
}

class Plan {
  const Plan({
    required this.id,
    required this.mine,
    required this.shared,
    required this.place,
    required this.airport,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.travellers,
    required this.pace,
    required this.budget,
    required this.interests,
    required this.currency,
    required this.title,
    required this.summary,
    required this.dayPlans,
    required this.tips,
    required this.estimate,
  });

  final String id;

  /// The viewer made this plan (can change, share and delete it).
  final bool mine;
  final bool shared;
  final PlanPlace place;

  /// The destination's city airport (IATA), for the Flights shortcut.
  final String? airport;
  final String startDate, endDate;
  final int days;
  final String travellers, pace, budget;
  final List<String> interests;
  final String currency, title, summary;
  final List<DayPlan> dayPlans;
  final List<String> tips;
  final Estimate estimate;

  static Plan? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! String ||
        json['title'] is! String ||
        json['startDate'] is! String ||
        json['endDate'] is! String) {
      return null;
    }
    final place = PlanPlace.fromJson(json['place']);
    if (place == null) return null;
    return Plan(
      id: json['id'] as String,
      mine: json['mine'] == true,
      shared: json['shared'] == true,
      place: place,
      airport:
          json['airport'] is String && (json['airport'] as String).isNotEmpty
          ? json['airport'] as String
          : null,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      days: _int(json['days']),
      travellers: _string(json['travellers']),
      pace: _string(json['pace']),
      budget: _string(json['budget']),
      interests: _strings(json['interests']),
      currency: json['currency'] is String ? json['currency'] as String : 'INR',
      title: json['title'] as String,
      summary: _string(json['summary']),
      dayPlans: parseList(json['dayPlans'], DayPlan.fromJson),
      tips: _strings(json['tips']),
      estimate: Estimate.fromJson(json['estimate']),
    );
  }
}

/// A plan in My Trips.
class PlanSummary {
  const PlanSummary({
    required this.id,
    required this.title,
    required this.placeName,
    required this.country,
    required this.startDate,
    required this.days,
    required this.shared,
  });

  final String id, title, placeName, country, startDate;
  final int days;
  final bool shared;

  static PlanSummary? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! String ||
        json['title'] is! String ||
        json['placeName'] is! String ||
        json['startDate'] is! String ||
        json['days'] is! int) {
      return null;
    }
    return PlanSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      placeName: json['placeName'] as String,
      country: _string(json['country']),
      startDate: json['startDate'] as String,
      days: json['days'] as int,
      shared: json['shared'] == true,
    );
  }
}
