// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:scheduler_app/data/user_repository.dart'; // Import UserRepository
import 'package:scheduler_app/models/user.dart'; // Import User model
import 'package:firebase_analytics/firebase_analytics.dart'; // New import for analytics
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // New import for Firebase Auth user
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // New import for crashlytics

/// UserProvider: Manages the state and logic for user-related data (profile, availability).
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository; // Dependency on UserRepository
  User? _currentUser; // The current logged-in user
  bool _isLoadingUser = false;

  User? get currentUser => _currentUser;
  bool get isLoadingUser => _isLoadingUser;

  UserProvider(this._userRepository); // Constructor: takes UserRepository

  /// Loads the current user's profile from the repository.
  /// It first checks Firebase Authentication for the current user.
  Future<void> loadCurrentUser() async {
    _isLoadingUser = true;
    notifyListeners();

    try {
      // Get current user from Firebase Authentication
      final fb_auth.User? firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // If authenticated, set user ID for analytics
        FirebaseAnalytics.instance.setUserId(id: firebaseUser.uid);
        // Now, fetch or create user profile from UserRepository (which might use Firestore later)
        _currentUser = await _userRepository.getCurrentUser(firebaseUser.uid); // Pass UID to repository
        // If user profile doesn't exist in mock, create a basic one (in a real app, this would be signup flow)
        if (_currentUser == null) {
          _currentUser = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'New User',
            email: firebaseUser.email ?? 'No Email',
          );
          await _userRepository.updateUserProfile(_currentUser!); // Save new user to mock
        }
      } else {
        _currentUser = null; // No user logged in
        FirebaseAnalytics.instance.setUserId(id: null); // Clear user ID if logged out
      }

    } catch (e, s) {
      print('Failed to load user: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Failed to load user profile in UserProvider');
      // Handle error (e.g., show error message to user)
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// Updates the current user's profile via the repository.
  Future<void> updateCurrentUserProfile(User updatedUser) async {
    _isLoadingUser = true;
    notifyListeners();

    try {
      _currentUser = await _userRepository.updateUserProfile(updatedUser);
      FirebaseAnalytics.instance.logEvent( // Analytics event
        name: 'profile_updated',
        parameters: {'user_id': updatedUser.id, 'bio_length': updatedUser.bio.length},
      );
      print('Analytics: Logged profile_updated');
    } catch (e, s) {
      print('Failed to update user: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Failed to update user profile in UserProvider');
      // Handle error
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  // --- Authentication Actions (Proxy to Firebase Auth) ---
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoadingUser = true;
    notifyListeners();
    try {
      final userCredential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Reload current user to get profile data after successful login
      await loadCurrentUser();
      FirebaseAnalytics.instance.logLogin(loginMethod: 'email'); // Analytics event
      print('Analytics: Logged login');
    } on fb_auth.FirebaseAuthException catch (e, s) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Firebase Auth sign-in failed');
      rethrow; // Re-throw to be caught by UI for error message
    } catch (e, s) {
      print('Generic sign-in error: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Generic sign-in error');
      rethrow;
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    _isLoadingUser = true;
    notifyListeners();
    try {
      final userCredential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // After creating, automatically load the new user's profile
      await loadCurrentUser();
      FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email'); // Analytics event
      print('Analytics: Logged sign_up');
    } on fb_auth.FirebaseAuthException catch (e, s) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Firebase Auth sign-up failed');
      rethrow;
    } catch (e, s) {
      print('Generic sign-up error: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Generic sign-up error');
      rethrow;
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoadingUser = true; // Indicate loading during sign-out
    notifyListeners();
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
      _currentUser = null; // Clear local user state
      FirebaseAnalytics.instance.logEvent(name: 'logout'); // Analytics event
      print('Analytics: Logged logout');
    } catch (e, s) {
      print('Error signing out: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Firebase Auth sign-out failed');
      rethrow;
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }
}