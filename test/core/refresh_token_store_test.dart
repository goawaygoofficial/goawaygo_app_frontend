import 'package:app_frontend/core/auth/refresh_token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a token saved under the old name is moved, so nobody is signed out',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'goaway_refresh_token': 'old-token',
      });
      const storage = FlutterSecureStorage();
      const store = SecureRefreshTokenStore(storage);

      expect(await store.read(), 'old-token');
      expect(await storage.read(key: 'goawaygo_refresh_token'), 'old-token');
      expect(await storage.read(key: 'goaway_refresh_token'), isNull);
    },
  );

  test('clear removes both names', () async {
    FlutterSecureStorage.setMockInitialValues({
      'goaway_refresh_token': 'a',
      'goawaygo_refresh_token': 'b',
    });
    const store = SecureRefreshTokenStore(FlutterSecureStorage());

    await store.clear();

    expect(await store.read(), isNull);
  });
}
