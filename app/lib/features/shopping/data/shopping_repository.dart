import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';

/// Repository interacting with backend /v1/shopping endpoints.
class ShoppingRepository {
  final ApiClient _apiClient;

  ShoppingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches shopping items. Defaults to unarchived items, unbought first.
  Future<List<ShoppingItem>> getShoppingItems({
    bool? bought,
    bool includeArchived = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (bought != null) {
      queryParams['bought'] = bought.toString();
    }
    if (includeArchived) {
      queryParams['include_archived'] = 'true';
    }

    final response =
        await _apiClient.get('/v1/shopping', queryParams: queryParams);
    if (response is List) {
      return response
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Adds a new item to the shopping list.
  Future<ShoppingItem> addShoppingItem(
    String name, {
    double? quantity,
    String? unit,
    String? category,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
    };
    if (quantity != null) {
      body['quantity'] = quantity;
    }
    if (unit != null && unit.trim().isNotEmpty) {
      body['unit'] = unit.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }

    final response = await _apiClient.post('/v1/shopping', body: body);
    return ShoppingItem.fromJson(response as Map<String, dynamic>);
  }

  /// Updates allowed fields of an existing shopping item.
  Future<ShoppingItem> updateShoppingItem(
    String id, {
    String? name,
    double? quantity,
    String? unit,
    String? category,
    bool? archived,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (quantity != null) body['quantity'] = quantity;
    if (unit != null && unit.trim().isNotEmpty) body['unit'] = unit.trim();
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }
    if (archived != null) body['archived'] = archived;

    final response = await _apiClient.patch('/v1/shopping/$id', body: body);
    return ShoppingItem.fromJson(response as Map<String, dynamic>);
  }

  /// Marks a shopping item as bought and creates a pantry item.
  /// Throws ApiException (e.g. 409 if already bought).
  Future<Map<String, dynamic>> markBought(
    String id, {
    required DateTime expiryDate,
    double? quantity,
    String? unit,
    String? category,
    String? location,
  }) async {
    final formattedDate =
        '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
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

    final response =
        await _apiClient.post('/v1/shopping/$id/bought', body: body);
    return response as Map<String, dynamic>;
  }

  /// Marks multiple shopping items as bought in one bulk request.
  Future<List<BulkBoughtResultItem>> markBoughtBulk(
    List<BulkBoughtItemInput> items,
  ) async {
    final body = <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(),
    };

    final response =
        await _apiClient.post('/v1/shopping/bought-bulk', body: body);
    if (response is Map<String, dynamic>) {
      final rawResults = response['results'];
      if (rawResults is List) {
        return rawResults
            .whereType<Map<String, dynamic>>()
            .map(BulkBoughtResultItem.fromJson)
            .toList();
      }
    }
    return const [];
  }
}

/// Request payload for a single item in POST /v1/shopping/bought-bulk.
class BulkBoughtItemInput {
  final String id;
  final DateTime expiryDate;
  final double? quantity;
  final String? unit;
  final String? category;
  final String? location;

  const BulkBoughtItemInput({
    required this.id,
    required this.expiryDate,
    this.quantity,
    this.unit,
    this.category,
    this.location,
  });

  Map<String, dynamic> toJson() {
    final formattedDate =
        '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';

    return <String, dynamic>{
      'id': id,
      'expiry_date': formattedDate,
      if (quantity != null) 'quantity': quantity,
      if (unit != null && unit!.trim().isNotEmpty) 'unit': unit!.trim(),
      if (category != null && category!.trim().isNotEmpty)
        'category': category!.trim(),
      if (location != null && location!.trim().isNotEmpty)
        'location': location!.trim(),
    };
  }
}

/// Per-item result returned by POST /v1/shopping/bought-bulk.
class BulkBoughtResultItem {
  final String id;
  final String status;
  final String code;
  final String message;
  final Map<String, dynamic>? shoppingItem;
  final Map<String, dynamic>? pantryItem;

  const BulkBoughtResultItem({
    required this.id,
    required this.status,
    required this.code,
    required this.message,
    this.shoppingItem,
    this.pantryItem,
  });

  bool get isOk => status == 'ok';

  factory BulkBoughtResultItem.fromJson(Map<String, dynamic> json) {
    return BulkBoughtResultItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'error',
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Failed to add item to pantry.',
      shoppingItem: json['shopping_item'] is Map
          ? Map<String, dynamic>.from(json['shopping_item'] as Map)
          : null,
      pantryItem: json['pantry_item'] is Map
          ? Map<String, dynamic>.from(json['pantry_item'] as Map)
          : null,
    );
  }
}
