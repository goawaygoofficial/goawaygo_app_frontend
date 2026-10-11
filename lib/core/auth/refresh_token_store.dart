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

  static const _key = 'goaway_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
