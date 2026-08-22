import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(null) {
    // Restore session automatically on startup so user stays logged in
    _restoreSession();
  }

  /// Called at startup. If Firebase has a persisted session, re-verify with backend.
  Future<void> _restoreSession() async {
    // Give Firebase time to restore its auth state from storage
    await Future.delayed(const Duration(milliseconds: 600));
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _ref.read(authLoadingProvider.notifier).state = true;
      try {
        final user = await _authService.verifyWithBackend();
        state = user;
        _ref.read(currentUserProvider.notifier).state = user;
      } finally {
        _ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> signInAnonymously() async {
    _ref.read(authLoadingProvider.notifier).state = true;
    try {
      await _authService.signInAnonymously();
      final user = await _authService.verifyWithBackend();
      state = user;
      _ref.read(currentUserProvider.notifier).state = user;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _ref.read(authLoadingProvider.notifier).state = true;
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred == null) return false;
      final user = await _authService.verifyWithBackend();
      state = user;
      _ref.read(currentUserProvider.notifier).state = user;
      return true;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> updateUsername(String username) async {
    try {
      await apiService.put('/api/users/me', data: {'username': username});
      if (state != null) {
        state = UserModel(
          id: state!.id,
          firebaseUid: state!.firebaseUid,
          username: username,
          avatarColor: state!.avatarColor,
          isAnonymous: state!.isAnonymous,
          watchStreak: state!.watchStreak,
          stats: state!.stats,
          watchHistory: state!.watchHistory,
        );
        _ref.read(currentUserProvider.notifier).state = state;
      }
    } catch (_) {}
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
    _ref.read(currentUserProvider.notifier).state = null;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
