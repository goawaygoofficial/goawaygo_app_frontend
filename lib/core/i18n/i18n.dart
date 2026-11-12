import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:app_frontend/core/i18n/region_currencies.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A language the app speaks (4.7).
class AppLanguage {
  const AppLanguage(this.code, this.name, {this.rtl = false});

  final String code;

  /// The language's own name ("हिन्दी").
  final String name;

  /// Read right to left (Arabic).
  final bool rtl;
}

const appLanguages = [
  AppLanguage('en', 'English'),
  AppLanguage('hi', 'हिन्दी'),
  AppLanguage('es', 'Español'),
  AppLanguage('fr', 'Français'),
  AppLanguage('de', 'Deutsch'),
  AppLanguage('ar', 'العربية', rtl: true),
  AppLanguage('ja', '日本語'),
];

/// The app's languages and the traveller's currency (4.7). Text is written in English and wrapped in
/// `tr('English sentence {0}', [value])`; `assets/i18n/<code>.json` maps each English sentence to its translation (the
/// same files as the website). A sentence without a translation stays English.
class I18n {
  I18n._();

  static const _languageKey = 'language';
  static const _currencyKey = 'currency';

  static String _code = 'en';
  static Map<String, String> _catalog = const {};
  static String? _accountCurrency;

  static String get code => _code;

  static AppLanguage get language => appLanguages.firstWhere(
    (l) => l.code == _code,
    orElse: () => appLanguages.first,
  );

  /// The locale for dates, numbers and prices: the phone's own (e.g. `en_IN`) when it is in the same language, so
  /// the region's formats are kept; otherwise the language.
  static String get locale {
    final device = PlatformDispatcher.instance.locale;
    return device.languageCode == _code && device.countryCode != null
        ? '${_code}_${device.countryCode}'
        : _code;
  }

  static bool isLanguage(String? code) =>
      appLanguages.any((l) => l.code == code);

  /// The traveller's choice, else the phone's first supported language, else English.
  static Future<String> detect() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    if (isLanguage(saved)) return saved!;
    for (final locale in PlatformDispatcher.instance.locales) {
      if (isLanguage(locale.languageCode)) return locale.languageCode;
    }
    return 'en';
  }

  /// Loads a language's translations and date formats, and makes it current.
  static Future<void> load(String code) async {
    final language = isLanguage(code) ? code : 'en';
    var catalog = const <String, String>{};
    if (language != 'en') {
      try {
        final raw = await rootBundle.loadString('assets/i18n/$language.json');
        catalog = (jsonDecode(raw) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        );
      } on Object {
        // Missing or broken file: English.
      }
    }
    _catalog = catalog;
    _code = language;
    Intl.defaultLocale = locale;
    await initializeDateFormatting(locale);
  }

  static Future<void> remember(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  /// The signed-in account's currency (UserProvider keeps it current); null when signed out or not chosen.
  static set accountCurrency(String? code) => _accountCurrency = code;

  /// A signed-out traveller's currency choice, kept on the phone.
  static Future<void> rememberCurrency(String code) async {
    _savedCurrency = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }

  static String? _savedCurrency;

  /// Reads the saved currency choice once at start-up (prices then never wait for storage).
  static Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _savedCurrency = prefs.getString(_currencyKey);
  }

  /// The currency prices are shown in: the account's, else the traveller's choice, else a guess from the phone's
  /// region (IN → INR), else US dollars.
  static String get currency {
    final account = _accountCurrency;
    if (account != null && account.isNotEmpty) {
      return account;
    }
    final saved = _savedCurrency;
    if (saved != null && saved.length == 3) {
      return saved;
    }
    for (final locale in PlatformDispatcher.instance.locales) {
      final guess = regionCurrencies[locale.countryCode?.toUpperCase()];
      if (guess != null) return guess;
    }
    return 'USD';
  }

  /// Tests: back to English with no translations.
  static void reset() {
    _code = 'en';
    _catalog = const {};
    _accountCurrency = null;
    _savedCurrency = null;
  }

  /// Tests: use these translations.
  static void useCatalog(String code, Map<String, String> catalog) {
    _code = code;
    _catalog = catalog;
  }

  static String translate(String template, List<Object?> args) {
    var text = _catalog[template] ?? template;
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', '${args[i]}');
    }
    return text;
  }
}

/// The English [template] in the app's language, with `{0}`, `{1}`... filled from [args].
String tr(String template, [List<Object?> args = const []]) =>
    I18n.translate(template, args);
