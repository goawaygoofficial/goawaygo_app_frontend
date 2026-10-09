import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:app_frontend/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final user = UserModel(id: 42, name: 'Test User', email: 'test@example.com');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProvider', () {
    test('starts with no user', () {
      expect(UserProvider().user, isNull);
    });

    test('setUser stores the user in state and in local storage', () async {
      final provider = UserProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setUser(user);
      await pumpEventQueue();

      expect(provider.user?.id, 42);
      expect(notified, isTrue);
      final saved = await UserService.loadUserFromPrefs();
      expect(saved?.email, 'test@example.com');
    });

    test('clearUser removes the user from state and local storage', () async {
      final provider = UserProvider()..setUser(user);
      await pumpEventQueue();

      await provider.clearUser();

      expect(provider.user, isNull);
      expect(await UserService.loadUserFromPrefs(), isNull);
    });

    test('loadUserFromPrefs leaves user empty when nothing is saved', () async {
      final provider = UserProvider();

      await provider.loadUserFromPrefs();

      expect(provider.user, isNull);
    });
  });
}
