/// A user as the backend sends it (snake_case JSON).
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;
  final bool emailVerified;

  /// ISO 3166 country and ISO 4217 currency the user picked (4.6), or null.
  final String? country;
  final String? currency;

  /// Whether the account has a password; otherwise "confirm it's you" uses Google.
  final bool hasPassword;
  final bool googleLinked;

  /// A new email waiting for its confirmation link.
  final String? pendingEmail;

  /// The language the account's pushes and emails use.
  final String? language;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
    this.emailVerified = false,
    this.country,
    this.currency,
    this.hasPassword = true,
    this.googleLinked = false,
    this.pendingEmail,
    this.language,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? text(String key) =>
        json[key] is String ? json[key] as String : null;
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      phone: json['phone'],
      emailVerified: json['email_verified'] ?? false,
      country: text('country'),
      currency: text('currency'),
      // Older backends don't say: assume a password, which is what "confirm it's you" asked for before.
      hasPassword: json['has_password'] ?? true,
      googleLinked: json['google_linked'] ?? false,
      pendingEmail: text('pending_email'),
      language: text('language'),
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
      'country': country,
      'currency': currency,
      'has_password': hasPassword,
      'google_linked': googleLinked,
      'pending_email': pendingEmail,
      'language': language,
    };
  }
}
