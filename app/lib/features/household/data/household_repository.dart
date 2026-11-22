import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/household/data/household_model.dart';

/// Repository interacting with backend /v1/household endpoints.
class HouseholdRepository {
  final ApiClient _apiClient;

  HouseholdRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the current household.
  Future<HouseholdModel> fetchHousehold() async {
    final response = await _apiClient.get('/v1/household');
    return HouseholdModel.fromJson(response as Map<String, dynamic>);
  }

  /// Joins a household using an invite code.
  /// Returns a map containing the household and the new access token.
  Future<Map<String, dynamic>> joinHousehold(String code) async {
    final body = {'code': code.trim()};
    final response = await _apiClient.post('/v1/household/join', body: body);
    // Expected response shape: {"household": {...}, "access_token": "..."}
    final householdJson = response['household'] as Map<String, dynamic>;
    final token = response['access_token'] as String;
    return {
      'household': HouseholdModel.fromJson(householdJson),
      'accessToken': token,
    };
  }

  /// Regenerates the household invite code.
  Future<HouseholdModel> regenerateCode() async {
    final response = await _apiClient.post('/v1/household/regenerate-code');
    return HouseholdModel.fromJson(response as Map<String, dynamic>);
  }
}
