import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:intl/intl.dart';

/// Formatting for Book results (same output as the website's `format.ts`).
class BookFormat {
  BookFormat._();

  /// "₹7,517" (whole units: fares are rounded by the partner).
  static String price(int price, String currency) =>
      NumberFormat.simpleCurrency(
        locale: I18n.locale,
        name: currency,
        decimalDigits: 0,
      ).format(price);

  /// A `YYYY-MM-DD` (or the date part of an ISO timestamp) as a calendar day, without time-zone shifts.
  static DateTime _day(String value) => DateTime.parse(value.substring(0, 10));

  /// "Mon 7 Dec" (in the traveller's locale)
  static String day(String value) =>
      DateFormat.MMMEd(I18n.locale).format(_day(value));

  /// "7 Dec – 9 Dec" (or "Dec 7 – Dec 9"), as the traveller's locale writes dates.
  static String dateRange(String start, String end) {
    final dayMonth = DateFormat.MMMd(I18n.locale);
    return '${dayMonth.format(_day(start))} – ${dayMonth.format(_day(end))}';
  }

  /// "December 2026"
  static String month(String value) =>
      DateFormat.yMMMM(I18n.locale).format(_day(value));

  /// The departure's local time, read straight from the timestamp ("2026-12-07T07:10:00+05:30" → "7:10 AM").
  static String time(String iso) {
    final parts = iso.length >= 16
        ? iso.substring(11, 16).split(':')
        : ['0', '0'];
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    // 12 or 24 hours, as the locale writes times.
    return DateFormat.jm(I18n.locale)
        .format(DateTime(2000, 1, 1, hours, minutes));
  }

  /// "2h 05m"
  static String duration(int minutes) => tr('{0}h {1}m', [
    minutes ~/ 60,
    (minutes % 60).toString().padLeft(2, '0'),
  ]);

  static String stops(int stops) => switch (stops) {
    0 => tr('Nonstop'),
    1 => tr('1 stop'),
    _ => tr('{0} stops', [stops]),
  };

  /// "1 day", "3 days" (and passengers, guests, rooms), translated.
  static String plural(int count, String word) =>
      count == 1 ? tr('1 $word') : tr('{0} ${word}s', [count]);

  /// `YYYY-MM-DD` for the backend.
  static String isoDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
