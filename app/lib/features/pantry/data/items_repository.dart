import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';

/// Repository interacting with backend /v1/items endpoints.
class ItemsRepository {
  final ApiClient _apiClient;

  ItemsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches items filtered by status, category, or search query.
  Future<List<ItemModel>> getItems({
    String? status = 'active',
    String? category,
    String? q,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }

    final response = await _apiClient.get('/v1/items', queryParams: queryParams);
    if (response is List) {
      return response
          .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches top 5 active items expiring soonest for the Home screen.
  Future<List<ItemModel>> getUseFirstItems() async {
    final response = await _apiClient.get('/v1/items/use-first');
    if (response is List) {
      return response
          .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Adds a new pantry item.
  Future<ItemModel> addItem({
    required String name,
    required DateTime expiryDate,
    double? quantity,
    String? unit,
    String? category,
    String? location,
  }) async {
    // Format date as YYYY-MM-DD
    final formattedDate =
        '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'name': name.trim(),
      'expiry_date': formattedDate,
    };
    if (quantity != null) body['quantity'] = quantity;
    if (unit != null && unit.trim().isNotEmpty) body['unit'] = unit.trim();
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }
    if (location != null && location.trim().isNotEmpty) {
      body['location'] = location.trim();
    }

    final response = await _apiClient.post('/v1/items', body: body);
    return ItemModel.fromJson(response as Map<String, dynamic>);
  }

  /// Updates editable fields of an existing pantry item.
  Future<ItemModel> updateItem(
    String id, {
    String? name,
    DateTime? expiryDate,
    double? quantity,
    String? unit,
    String? category,
    String? location,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (expiryDate != null) {
      body['expiry_date'] =
          '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
    }
    if (quantity != null) body['quantity'] = quantity;
    if (unit != null) body['unit'] = unit.trim().isEmpty ? null : unit.trim();
    if (category != null) {
      body['category'] = category.trim().isEmpty ? null : category.trim();
    }
    if (location != null) {
      body['location'] = location.trim().isEmpty ? null : location.trim();
    }

    final response = await _apiClient.patch('/v1/items/$id', body: body);
    return ItemModel.fromJson(response as Map<String, dynamic>);
  }

  /// Marks item status as 'used'.
  Future<ItemModel> markUsed(String id) async {
    final response = await _apiClient.post('/v1/items/$id/use');
    return ItemModel.fromJson(response as Map<String, dynamic>);
  }

  /// Marks item status as 'thrown'.
  Future<ItemModel> markThrown(String id) async {
    final response = await _apiClient.post('/v1/items/$id/throw');
    return ItemModel.fromJson(response as Map<String, dynamic>);
  }
}
