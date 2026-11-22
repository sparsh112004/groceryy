/// Core constants for the Pantry application.
class AppConstants {
  /// Base API URL read at compile time via --dart-define.
  /// Defaults to http://127.0.0.1:8000 for local development.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// Key used in secure storage for persisting the JWT token
  static const String storageAuthTokenKey = 'pantry_auth_token';

  /// Key used in secure storage for persisting active user profile metadata
  static const String storageUserKey = 'pantry_user_info';
}
