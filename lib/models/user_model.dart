/// A user as the backend sends it (snake_case JSON).
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
    this.emailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      phone: json['phone'],
      emailVerified: json['email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'phone': phone,
      'email_verified': emailVerified,
    };
  }
}
