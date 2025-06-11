// lib/models/user.dart

/// Data model for a User in ChronoPlan.
class User {
  final String id;
  String name;
  String email;
  String bio; // For the user's bio feature
  bool isAvailable; // For the availability feature (mocked)
  String? profileImageUrl; // Optional profile image

  User({
    required this.id,
    required this.name,
    required this.email,
    this.bio = '',
    this.isAvailable = false,
    this.profileImageUrl,
  });

  // --- Methods for JSON serialization/deserialization (if coming from API) ---
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? false,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'isAvailable': isAvailable,
      'profileImageUrl': profileImageUrl,
    };
  }
}