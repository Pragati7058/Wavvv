import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      return null;
    }
  }

  /// Sign in with Google account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    apiService.clearToken();
  }

  /// Get Firebase ID token and send to backend for verification
  Future<UserModel?> verifyWithBackend() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        final mockUser = _createMockUser();
        apiService.setToken(getMockToken(mockUser.firebaseUid, mockUser.username));
        return mockUser;
      }

      String? token;
      try {
        token = await user.getIdToken();
      } catch (e) {
        token = null;
      }
      
      if (token == null) {
        final mockUser = _createMockUser();
        apiService.setToken(getMockToken(mockUser.firebaseUid, mockUser.username));
        return mockUser;
      }

      apiService.setToken(token);
      final response = await apiService.post(ApiConstants.authVerify);
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      // Backend verify failed — set mock token so subsequent API calls work
      final mockUser = _createMockUser();
      apiService.setToken(getMockToken(mockUser.firebaseUid, mockUser.username));
      return mockUser;
    }
  }

  /// Mock user for offline / no-Firebase development
  UserModel _createMockUser() {
    final user = _auth.currentUser;
    return UserModel(
      id: 'mock-id',
      firebaseUid: user?.uid ?? 'mock-uid',
      username: user?.displayName ?? 'WavvvUser',
      avatarColor: '#6366F1',
      isAnonymous: user?.isAnonymous ?? true,
      watchStreak: const WatchStreakModel(),
      stats: const UserStatsModel(),
      watchHistory: [],
    );
  }

  Future<String?> getIdToken() async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) return token;
    } catch (_) {}
    
    final mockUser = _createMockUser();
    return getMockToken(mockUser.firebaseUid, mockUser.username);
  }

  /// Mock token for offline development
  String getMockToken(String uid, String username) {
    return 'mock_${uid}_$username';
  }
}
