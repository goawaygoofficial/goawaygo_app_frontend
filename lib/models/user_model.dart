class UserModel {
  final int id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'phone': phone,
    };
  }
}
