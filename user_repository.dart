// lib/data/user_repository.dart

import 'package:scheduler_app/models/user.dart'; // Import User model

/// Mock UserRepository: Simulates API calls for user data.
/// In a real app, this would make HTTP requests to a backend.
class UserRepository {
  // A map to store mock users, indexed by UID
  final Map<String, User> _mockUsers = {
    'mock_uid_1': User(
      id: 'mock_uid_1',
      name: 'Authenticated User',
      email: 'auth.user@example.com',
      bio: 'This is my bio loaded from mock repository after login!',
      isAvailable: true,
    ),
    'mock_uid_2': User(
      id: 'mock_uid_2',
      name: 'Test User',
      email: 'test.user@example.com',
      bio: 'Another mock user.',
      isAvailable: false,
    ),
  };

  /// Simulates fetching a user's profile by UID from an API.
  Future<User?> getCurrentUser(String uid) async {
    print('Simulating API call: getCurrentUser for UID: $uid');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return _mockUsers[uid]; // Return user from map
  }

  /// Simulates updating a user's profile on an API.
  Future<User> updateUserProfile(User updatedUser) async {
    print('Simulating API call: updateUserProfile for ${updatedUser.name}');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _mockUsers[updatedUser.id] = updatedUser; // Update our mock user
    return updatedUser;
  }

  /// Simulates fetching a list of friends (mock data).
  Future<List<User>> getFriends() async {
    print('Simulating API call: getFriends');
    await Future.delayed(const Duration(seconds: 1));
    return [
      User(id: 'friend1', name: 'Alice', email: 'alice@example.com', isAvailable: true, bio: 'Coffee lover'),
      User(id: 'friend2', name: 'Bob', email: 'bob@example.com', isAvailable: false, bio: 'Busy developer'),
      User(id: 'friend3', name: 'Charlie', email: 'charlie@example.com', isAvailable: true, bio: 'Always on time'),
    ];
  }
}