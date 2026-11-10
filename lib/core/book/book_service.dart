import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/discover/discover_models.dart';

/// Book (4.3): airports, recent flight prices and partner links (the same calls as the website's `bookService.ts`).
/// The app asks with `channel=app`, so it only gets partners that allow promotion in apps.
class BookService {
  BookService._();

  /// The traveller's currency: the account's, their choice, or a guess from the phone's region (4.7).
  static String get currency => I18n.currency;

  static const _unexpected = ApiException(
    'Unexpected response from the server.',
    200,
  );

  /// Cities and airports matching what the user is typing (at least 2 characters).
  static Future<List<Airport>> suggestAirports(String text) async {
    final data = await Backend.api.request(
      'GET',
      '/api/book/airports?q=${Uri.encodeQueryComponent(text)}',
      fallbackError: 'Could not search airports.',
    );
    return parseList(data, Airport.fromJson);
  }

  /// Recent fares for a trip, cheaper dates that month and the link to the partner's live search.
  static Future<FlightResults> searchFlights(FlightSearch search) async {
    final query = {
      'from': search.from.code,
      'to': search.to.code,
      'depart': search.depart,
      if (search.returnDate != null) 'return': search.returnDate!,
      'adults': '${search.adults}',
      'currency': currency,
      'channel': 'app',
    };
    final data = await Backend.api.request(
      'GET',
      '/api/book/flights?${Uri(queryParameters: query).query}',
      fallbackError: 'Could not find flight prices.',
    );
    return FlightResults.fromJson(data) ?? (throw _unexpected);
  }

  /// Hotel partners opened on the place and dates.
  static Future<List<PartnerCard>> stayPartners(StaySearch search) async {
    final query = {
      'place': search.place,
      'checkin': search.checkin,
      'checkout': search.checkout,
      'adults': '${search.adults}',
      'rooms': '${search.rooms}',
      'currency': currency,
      'channel': 'app',
    };
    final data = await Backend.api.request(
      'GET',
      '/api/book/stays?${Uri(queryParameters: query).query}',
      fallbackError: 'Could not open hotel partners.',
    );
    if (data is! List) throw _unexpected;
    return parseList(data, PartnerCard.fromJson);
  }

  /// Car rental partners opened on the pick-up place and dates.
  static Future<List<PartnerCard>> carPartners(CarSearch search) async {
    final query = {
      'place': search.place,
      if (search.airport != null) 'airport': search.airport!,
      'pickup': search.pickup,
      'dropoff': search.dropoff,
      'currency': currency,
      'channel': 'app',
    };
    final data = await Backend.api.request(
      'GET',
      '/api/book/cars?${Uri(queryParameters: query).query}',
      fallbackError: 'Could not open car rental partners.',
    );
    if (data is! List) throw _unexpected;
    return parseList(data, PartnerCard.fromJson);
  }
}
