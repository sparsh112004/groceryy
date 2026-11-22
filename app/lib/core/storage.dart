import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pantry_app/core/constants.dart';

/// Secure storage service for holding authentication tokens
/// (uses Android Keystore on Android, and Web LocalStorage/fallback on Web).
class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Retrieves the saved JWT access token, or null if unauthenticated.
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: AppConstants.storageAuthTokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Persists the JWT access token.
  Future<void> saveAuthToken(String token) async {
    await _storage.write(
      key: AppConstants.storageAuthTokenKey,
      value: token,
    );
  }

  /// Removes the stored JWT access token (logout).
  Future<void> clearAuthToken() async {
    await _storage.delete(key: AppConstants.storageAuthTokenKey);
  }
}
