import 'package:intl/intl.dart';

/// Formatting for Book results (same output as the website's `format.ts`).
class BookFormat {
  BookFormat._();

  /// "₹7,517" (whole units: fares are rounded by the partner).
  static String price(int price, String currency) =>
      NumberFormat.simpleCurrency(
        locale: 'en_IN',
        name: currency,
        decimalDigits: 0,
      ).format(price);

  /// A `YYYY-MM-DD` (or the date part of an ISO timestamp) as a calendar day, without time-zone shifts.
  static DateTime _day(String value) => DateTime.parse(value.substring(0, 10));

  /// "Mon 7 Dec"
  static String day(String value) =>
      DateFormat('EEE d MMM').format(_day(value));

  /// "7–9 Dec", or "28 Apr – 5 May" across months.
  static String dateRange(String start, String end) {
    final from = _day(start);
    final to = _day(end);
    final sameMonth = from.month == to.month && from.year == to.year;
    return sameMonth
        ? '${from.day}–${to.day} ${DateFormat('MMM').format(to)}'
        : '${DateFormat('d MMM').format(from)} – ${DateFormat('d MMM').format(to)}';
  }

  /// "December 2026"
  static String month(String value) => DateFormat('MMMM y').format(_day(value));

  /// The departure's local time, read straight from the timestamp ("2026-12-07T07:10:00+05:30" → "7:10 AM").
  static String time(String iso) {
    final parts = iso.length >= 16
        ? iso.substring(11, 16).split(':')
        : ['0', '0'];
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final hour12 = hours % 12 == 0 ? 12 : hours % 12;
    return '$hour12:${minutes.toString().padLeft(2, '0')} ${hours < 12 ? 'AM' : 'PM'}';
  }

  /// "2h 05m"
  static String duration(int minutes) =>
      '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

  static String stops(int stops) => switch (stops) {
    0 => 'Nonstop',
    1 => '1 stop',
    _ => '$stops stops',
  };

  static String plural(int count, String word) =>
      '$count $word${count == 1 ? '' : 's'}';

  /// `YYYY-MM-DD` for the backend.
  static String isoDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
