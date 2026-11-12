import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/discover/discover_models.dart';

/// Sent when loading photos from Wikimedia and Unsplash: Wikimedia asks apps to say who they are (the backend
/// sends the same). Browsers use their own, so this only matters on phones.
const photoHeaders = {
  'User-Agent': 'GoAwayGo/1.0 (https://goawaygo.com; team@goawaygo.com)',
};

/// Which place to open: a picked suggestion (preferred) or what the user typed.
class DestinationRequest {
  DestinationRequest.place(Place place)
    : name = place.name,
      placeId = place.id,
      text = null;

  const DestinationRequest.text(this.name, [String? text])
    : placeId = null,
      text = text ?? name;

  /// Shown while the page loads.
  final String name;
  final String? placeId;
  final String? text;
}

/// Discover: place search, destination pages, the home banner, ideas and My Trips (the same calls as the
/// website's `discoverService.ts`).
class DiscoverService {
  DiscoverService._();

  /// The AI writes the cards meanwhile: usually 10-20 s, up to about a minute on the free tier.
  static const destinationTimeout = Duration(seconds: 120);

  static const _unexpected = ApiException(
    'Unexpected response from the server.',
    200,
  );

  /// Up to 6 real places matching what the user is typing (at least 2 characters).
  static Future<List<Place>> suggestPlaces(String text) async {
    final data = await Backend.api.request(
      'GET',
      '/api/discover/places?q=${Uri.encodeQueryComponent(text)}',
      fallbackError: 'Could not search places.',
    );
    return parseList(data, Place.fromJson);
  }

  /// The whole destination page, sent only when it is ready. Signed in, the search is added to the account's
  /// recent searches. Throws [ApiException] with status 404 when the place doesn't exist.
  static Future<DestinationPage> getDestination(
    DestinationRequest request,
  ) async {
    final param = request.placeId != null
        ? 'placeId=${Uri.encodeQueryComponent(request.placeId!)}'
        : 'q=${Uri.encodeQueryComponent(request.text!)}';
    final data = await Backend.api.request(
      'GET',
      // The exchange rate on the money card is against the traveller's currency.
      '/api/discover/destination?$param&currency=${I18n.currency}',
      fallbackError: 'Could not open this destination.',
      timeout: destinationTimeout,
    );
    return DestinationPage.fromJson(data) ?? (throw _unexpected);
  }

  /// The signed-in user's last 5 searched places, newest first, each with a live photo.
  static Future<List<BannerSlide>> getRecentSearches() async {
    final data = await Backend.api.request(
      'GET',
      '/api/discover/recent',
      fallbackError: 'Could not load your recent searches.',
    );
    return parseList(data, BannerSlide.fromJson);
  }

  /// Live photos for searches kept on this device (signed out). The slides keep the device's own places.
  static Future<List<BannerSlide>> getPhotosFor(
    List<RecentSearch> searches,
  ) async {
    if (searches.isEmpty) return const [];
    final data = await Backend.api.request(
      'POST',
      '/api/discover/photos',
      body: {
        'items': [
          for (final search in searches)
            {
              'spot': search.spot,
              'place': search.place.name,
              'type': search.place.type,
              'country': search.place.country,
              'lat': search.place.lat,
              'lon': search.place.lon,
            },
        ],
      },
      fallbackError: 'Could not load photos.',
    );
    final slides = data is List ? data : const [];
    return [
      for (var i = 0; i < searches.length; i++)
        BannerSlide(
          place: searches[i].place,
          spot: searches[i].spot,
          photo: i < slides.length && slides[i] is Map<String, dynamic>
              ? Photo.fromJson((slides[i] as Map<String, dynamic>)['photo'])
              : null,
        ),
    ];
  }

  /// Random ideas for the next trip from the backend's hourly pool (empty while none are ready).
  static Future<List<TripIdea>> getTripIdeas(int count) async {
    final data = await Backend.api.request(
      'GET',
      '/api/discover/ideas?count=$count',
      fallbackError: 'Could not load ideas.',
    );
    return parseList(data, TripIdea.fromJson);
  }

  /// My Trips, newest first (signed in).
  static Future<List<SavedPlace>> listSavedPlaces() async {
    final data = await Backend.api.request(
      'GET',
      '/api/me/saved-places',
      fallbackError: 'Could not load My Trips.',
    );
    return parseList(data, SavedPlace.fromJson);
  }

  /// Saves an idea to My Trips; saving it again changes nothing.
  static Future<void> saveIdea(TripIdea idea) async {
    await Backend.api.request(
      'POST',
      '/api/me/saved-places',
      body: {
        'key': idea.id,
        'name': idea.name,
        'area': idea.area,
        'country': idea.country,
        'lat': idea.lat,
        'lon': idea.lon,
        'category': idea.category,
      },
      expectedStatus: 204,
      fallbackError: 'Could not save this place.',
    );
  }

  static Future<void> removeSavedPlace(int id) async {
    await Backend.api.request(
      'DELETE',
      '/api/me/saved-places/$id',
      expectedStatus: 204,
      fallbackError: 'Could not remove this place.',
    );
  }
}
