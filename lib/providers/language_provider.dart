import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:flutter/foundation.dart';

/// The app's language (4.7). Changing it loads the translations, remembers the choice, tells the signed-in account
/// (its pushes and emails follow) and rebuilds the app in the new language.
class LanguageProvider extends ChangeNotifier {
  String get code => I18n.code;

  /// Where to land after the app rebuilds in a new language: the Profile tab, where the picker is.
  bool changedHere = false;

  Future<void> change(String code) async {
    if (code == I18n.code) return;
    await I18n.load(code);
    await I18n.remember(code);
    changedHere = true;
    notifyListeners();
    await tellAccount();
  }

  /// The account follows the app's language (best effort: the app works without it).
  static Future<void> tellAccount() async {
    if (Backend.session.accessToken == null) return;
    try {
      await Backend.api.request(
        'PUT',
        '/api/users/me/language',
        body: {'language': I18n.code},
        fallbackError: 'Could not save your language.',
      );
    } on ApiException {
      // Next time.
    }
  }
}
