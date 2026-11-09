import 'package:app_frontend/core/account/account_models.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/foundation.dart';

/// The signed-in user's account (Me, 4.6): details, password, email, deleting it, and Recently viewed.
class AccountService {
  AccountService._();

  static Future<Regions>? _regions;

  /// Forgets the loaded countries (each test has its own fake backend).
  @visibleForTesting
  static void resetCache() => _regions = null;

  static UserModel _user(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from server.', 200);
    }
    return UserModel.fromJson(data);
  }

  /// Name (also the Wanderbook name), country and currency; null clears a choice.
  static Future<UserModel> updateDetails({
    required String name,
    String? country,
    String? currency,
  }) async {
    final data = await Backend.api.request(
      'PUT',
      '/api/users/me',
      body: {'name': name, 'country': country, 'currency': currency},
      fallbackError: 'Could not save your details.',
    );
    return _user(data);
  }

  /// Every country (with its currency) and currency, loaded once per app run.
  static Future<Regions> regions() {
    return _regions ??= Backend.api
        .request(
          'GET',
          '/api/regions',
          fallbackError: 'Could not load countries.',
        )
        .then(Regions.fromJson)
        .catchError((Object error) {
          _regions = null;
          throw error;
        });
  }

  /// Changes the password (or sets the first one). The backend signs out every device and returns a new
  /// session for this one, which is stored like a sign-in.
  static Future<UserModel> changePassword(
    Proof proof,
    String newPassword,
  ) async {
    final data = await Backend.api.request(
      'POST',
      '/api/auth/change-password',
      body: {...proof.toJson(), 'newPassword': newPassword},
      fallbackError: 'Could not change your password.',
    );
    return Backend.session.start(data);
  }

  /// Emails a confirmation link to the new address; the account keeps its email until it is opened.
  static Future<UserModel> changeEmail(Proof proof, String newEmail) async {
    final data = await Backend.api.request(
      'POST',
      '/api/auth/change-email',
      body: {...proof.toJson(), 'newEmail': newEmail},
      fallbackError: 'Could not change your email.',
    );
    return _user(data);
  }

  /// Deleted for good after 30 days (signing in before then keeps it). Ends the session on this phone and
  /// returns the date it will be deleted.
  static Future<DateTime?> deleteAccount(Proof proof) async {
    final data = await Backend.api.request(
      'POST',
      '/api/auth/delete-account',
      body: proof.toJson(),
      fallbackError: 'Could not delete your account.',
    );
    await Backend.session.end();
    final deleteOn = data is Map<String, dynamic> ? data['deleteOn'] : null;
    return deleteOn is String ? DateTime.tryParse(deleteOn) : null;
  }

  static Future<RecentlyViewed> recentlyViewed() async {
    final data = await Backend.api.request(
      'GET',
      '/api/me/recently-viewed',
      fallbackError: 'Could not load what you viewed.',
    );
    return RecentlyViewed.fromJson(data);
  }

  static Future<void> clearRecentlyViewed() async {
    await Backend.api.request(
      'DELETE',
      '/api/me/recently-viewed',
      expectedStatus: 204,
      fallbackError: 'Could not clear the list.',
    );
  }
}
