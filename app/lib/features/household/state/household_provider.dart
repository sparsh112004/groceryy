import 'package:flutter/foundation.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/household/data/household_model.dart';
import 'package:pantry_app/features/household/data/household_repository.dart';

/// Provider managing household state, loading, joining, and code regeneration.
class HouseholdProvider extends ChangeNotifier {
  final HouseholdRepository _repository;
  final VoidCallback? _onUnauthorized;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  HouseholdModel? _household;

  HouseholdProvider({
    required HouseholdRepository repository,
    VoidCallback? onUnauthorized,
  })  : _repository = repository,
        _onUnauthorized = onUnauthorized;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  HouseholdModel? get household => _household;

  /// Loads the current household from the backend.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _household = await _repository.fetchHousehold();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoading = false;
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      } else if (e.statusCode == 0) {
        _errorMessage = 'Cannot reach the server, please try again.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Cannot reach the server, please try again.';
      notifyListeners();
    }
  }

  /// Joins a household using an invite code.
  /// Returns the new access token on success, or null on failure (errorMessage is set).
  Future<String?> join(String code) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.joinHousehold(code);
      _household = result['household'] as HouseholdModel? ?? _household;
      _isSubmitting = false;
      notifyListeners();
      return result['accessToken'] as String?;
    } on ApiException catch (e) {
      _isSubmitting = false;
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      } else {
        _errorMessage = e.message;
        notifyListeners();
      }
      return null;
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Failed to join household.';
      notifyListeners();
      return null;
    }
  }

  /// Regenerates the household invite code.
  /// Returns true on success, false otherwise.
  Future<bool> regenerateCode() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _household = await _repository.regenerateCode();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmitting = false;
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      } else {
        _errorMessage = e.message;
        notifyListeners();
      }
      return false;
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Failed to regenerate invite code.';
      notifyListeners();
      return false;
    }
  }
}
