import 'package:flutter/foundation.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/storage.dart';
import 'package:pantry_app/features/auth/data/auth_models.dart';

/// Authentication status for the app session lifecycle.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  networkError,
}

/// State provider managing authentication lifecycle, tokens, and active profile.
class AuthProvider extends ChangeNotifier {
  // Existing fields and methods...

  final ApiClient _apiClient;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.initial;
  String? _token;
  UserModel? _currentUser;
  HouseholdModel? _currentHousehold;
  String? _errorMessage;
  bool _isSubmitting = false;

  AuthProvider({
    required ApiClient apiClient,
    required StorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  // Getters
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isSubmitting => _isSubmitting;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  HouseholdModel? get currentHousehold => _currentHousehold;
  String? get errorMessage => _errorMessage;

  /// Restores session on app startup:
  /// - Reads stored token
  /// - Calls GET /v1/me
  /// - On 401: clears stored token and sets unauthenticated
  /// - On Network error (statusCode == 0): maintains state and sets networkError for retry
  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final storedToken = await _storage.getAuthToken();
      if (storedToken == null || storedToken.trim().isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _token = storedToken;

      final response = await _apiClient.get('/v1/me');
      if (response is Map<String, dynamic>) {
        if (response['user'] is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(
            response['user'] as Map<String, dynamic>,
          );
        }
        if (response['household'] is Map<String, dynamic>) {
          _currentHousehold = HouseholdModel.fromJson(
            response['household'] as Map<String, dynamic>,
          );
        }
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Expired or invalid token: clean up and force login
        await _storage.clearAuthToken();
        _token = null;
        _currentUser = null;
        _currentHousehold = null;
        _status = AuthStatus.unauthenticated;
      } else if (e.statusCode == 0) {
        // Network connection error: MUST NOT log the user out!
        _status = AuthStatus.networkError;
        _errorMessage = 'Cannot reach the server, please try again.';
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // General network/connection failure fallback
      _status = AuthStatus.networkError;
      _errorMessage = 'Cannot reach the server, please try again.';
    }

    notifyListeners();
  }

  /// Logs in an existing user with identifier and PIN or password.
  Future<bool> login(String identifier, String secret) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/v1/auth/login',
        body: {
          'identifier': identifier.trim(),
          'secret': secret.trim(),
        },
      );

      if (response is Map<String, dynamic> &&
          response.containsKey('access_token')) {
        final accessToken = response['access_token'] as String;
        await _storage.saveAuthToken(accessToken);
        _token = accessToken;

        if (response['user'] is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(
            response['user'] as Map<String, dynamic>,
          );
        }

        // Fetch complete household info
        try {
          final meResponse = await _apiClient.get('/v1/me');
          if (meResponse is Map<String, dynamic> &&
              meResponse['household'] is Map<String, dynamic>) {
            _currentHousehold = HouseholdModel.fromJson(
              meResponse['household'] as Map<String, dynamic>,
            );
          }
        } catch (_) {
          // Non-critical: household info can be refreshed later
        }

        _status = AuthStatus.authenticated;
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      throw ApiException(statusCode: 500, message: 'Invalid response from server.');
    } on ApiException catch (e) {
      _isSubmitting = false;
      if (e.statusCode == 401) {
        _errorMessage = 'Wrong phone/email or PIN/password.';
      } else if (e.statusCode == 0) {
        _errorMessage = 'Cannot reach the server, please try again.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Cannot reach the server, please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user and auto-creates their personal household.
  Future<bool> signup(String name, String identifier, String secret) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/v1/auth/signup',
        body: {
          'name': name.trim(),
          'identifier': identifier.trim(),
          'secret': secret.trim(),
        },
      );

      if (response is Map<String, dynamic> &&
          response.containsKey('access_token')) {
        final accessToken = response['access_token'] as String;
        await _storage.saveAuthToken(accessToken);
        _token = accessToken;

        if (response['user'] is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(
            response['user'] as Map<String, dynamic>,
          );
        }

        // Fetch complete household info
        try {
          final meResponse = await _apiClient.get('/v1/me');
          if (meResponse is Map<String, dynamic> &&
              meResponse['household'] is Map<String, dynamic>) {
            _currentHousehold = HouseholdModel.fromJson(
              meResponse['household'] as Map<String, dynamic>,
            );
          }
        } catch (_) {
          // Non-critical fallback
        }

        _status = AuthStatus.authenticated;
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      throw ApiException(statusCode: 500, message: 'Invalid response from server.');
    } on ApiException catch (e) {
      _isSubmitting = false;
      if (e.statusCode == 400 &&
          (e.message.toLowerCase().contains('already exists') ||
              e.message.toLowerCase().contains('registered'))) {
        _errorMessage = 'An account with this phone or email already exists.';
      } else if (e.statusCode == 0) {
        _errorMessage = 'Cannot reach the server, please try again.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Cannot reach the server, please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Clears stored credentials and logs out of the current session.
  Future<void> logout() async {
    await _storage.clearAuthToken();
    _token = null;
    _currentUser = null;
    _currentHousehold = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Saves a new access token and updates the provider state.
  Future<void> saveNewAccessToken(String token) async {
    await _storage.saveAuthToken(token);
    _token = token;
    // Optionally, we could refresh profile info, but caller will handle reloads.
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
