import 'package:app_frontend/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('fromJson reads all fields, including snake_case profile_picture', () {
      final user = UserModel.fromJson({
        'id': 7,
        'name': 'Asha',
        'email': 'asha@example.com',
        'profile_picture': 'https://example.com/a.png',
        'phone': '+911234567890',
      });

      expect(user.id, 7);
      expect(user.name, 'Asha');
      expect(user.email, 'asha@example.com');
      expect(user.profilePicture, 'https://example.com/a.png');
      expect(user.phone, '+911234567890');
    });

    test('fromJson allows optional fields to be missing', () {
      final user = UserModel.fromJson({
        'id': 1,
        'name': 'Ravi',
        'email': 'ravi@example.com',
      });

      expect(user.profilePicture, isNull);
      expect(user.phone, isNull);
    });

    test('toJson and fromJson round-trip without losing data', () {
      final original = UserModel(
        id: 3,
        name: 'Meera',
        email: 'meera@example.com',
        profilePicture: 'https://example.com/m.png',
        phone: '+919876543210',
      );

      final copy = UserModel.fromJson(original.toJson());

      expect(copy.toJson(), original.toJson());
    });
  });
}
