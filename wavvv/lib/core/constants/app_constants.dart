class AppConstants {
  // Sync Mechanism Constants
  static const double driftThresholdSeconds = 3.0; // drift > 3s triggers auto-sync
  static const Duration syncThrottleDuration = Duration(milliseconds: 2000); // max 1 sync update per 2s
  static const Duration writeDebounceDuration = Duration(milliseconds: 500); // debounce user actions 500ms

  // Shared Preferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyUserToken = 'auth_token';
  static const String keySavedUser = 'saved_user';

  // Wave reaction
  static const Duration waveCooldownDuration = Duration(seconds: 5);
}
