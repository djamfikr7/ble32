import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// User model
class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String token;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'operator',
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'token': token,
      };
}

/// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  }) : isAuthenticated = user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth notifier for state management
class AuthNotifier extends StateNotifier<AuthState> {
  static const _boxName = 'auth';
  static const _userKey = 'current_user';

  AuthNotifier() : super(AuthState()) {
    _loadStoredUser();
  }

  /// Load user from local storage on app start
  Future<void> _loadStoredUser() async {
    try {
      final box = await Hive.openBox(_boxName);
      final userData = box.get(_userKey);

      if (userData != null) {
        final user = User(
          id: userData['id'],
          email: userData['email'],
          fullName: userData['full_name'],
          role: userData['role'],
          token: userData['token'],
        );
        state = state.copyWith(user: user);
      }
    } catch (e) {
      // Ignore errors, user will need to login
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // For demo: accept any email with password length > 5
      if (password.length < 6) {
        state = state.copyWith(
          isLoading: false,
          error: 'Password must be at least 6 characters',
        );
        return false;
      }

      // Create demo user (in production, get from API response)
      final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      final user = User(
        id: 1,
        email: email,
        fullName: email.split('@').first,
        role: 'operator',
        token: token,
      );

      // Save to local storage
      final box = await Hive.openBox(_boxName);
      await box.put(_userKey, user.toJson());

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate
      if (!email.contains('@')) {
        state =
            state.copyWith(isLoading: false, error: 'Invalid email address');
        return false;
      }
      if (password.length < 6) {
        state = state.copyWith(
            isLoading: false, error: 'Password must be at least 6 characters');
        return false;
      }
      if (fullName.isEmpty) {
        state =
            state.copyWith(isLoading: false, error: 'Full name is required');
        return false;
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create new user (in production, get from API response)
      final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch,
        email: email,
        fullName: fullName,
        role: 'operator',
        token: token,
      );

      // Save to local storage
      final box = await Hive.openBox(_boxName);
      await box.put(_userKey, user.toJson());

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_userKey);
    } catch (_) {}

    state = state.copyWith(clearUser: true);
  }

  /// Clear any errors
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider to check if user is logged in
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
