import 'dart:convert';

import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recent searches of a signed-out user, kept only on this device (the Privacy Policy says so). Signed-in users'
/// searches are kept by their account instead. Only places and spot names are stored, never photos.
class RecentSearchesStore {
  RecentSearchesStore._();

  static const _key = 'goawaygo.recentSearches';

  /// Same as the account's history (backend `SearchHistory.KEEP`).
  static const max = 5;

  static Future<List<RecentSearch>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return parseList(
        jsonDecode(raw),
        RecentSearch.fromJson,
      ).take(max).toList();
    } on FormatException {
      return const [];
    }
  }

  /// Puts the place first (once), keeping the newest 5.
  static Future<void> remember(Place place, String? spot) async {
    final others = (await read()).where((e) => e.place.label != place.label);
    final next = [
      RecentSearch(place: place, spot: spot ?? place.name),
      ...others,
    ].take(max);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final search in next) search.toJson()]),
    );
  }
}
