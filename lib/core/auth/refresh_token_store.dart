import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the long-lived refresh token is kept between app launches.
abstract interface class RefreshTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// The platform's encrypted store: Android Keystore-backed storage, iOS Keychain.
///
/// On iOS the token is `first_unlock_this_device`: readable after the first unlock (so background refreshes
/// work), and never included in backups or restored to another device.
class SecureRefreshTokenStore implements RefreshTokenStore {
  const SecureRefreshTokenStore([
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ]);

  static const _key = 'goawaygo_refresh_token';

  /// Where the token was kept before the GoAwayGo rename; moved to [_key] on first read, so nobody is signed out.
  static const _legacyKey = 'goaway_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final token = await _storage.read(key: _key);
    if (token != null) return token;
    final legacy = await _storage.read(key: _legacyKey);
    if (legacy != null) {
      await _storage.write(key: _key, value: legacy);
      await _storage.delete(key: _legacyKey);
    }
    return legacy;
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _legacyKey);
  }
}
