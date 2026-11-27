import 'package:flutter/foundation.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/notification_service.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/data/items_repository.dart';

/// Provider managing pantry and home items state, categories, and inventory metrics.
class ItemsProvider extends ChangeNotifier {
  final ItemsRepository _repository;
  final VoidCallback? _onUnauthorized;

  bool _isLoading = false;
  String? _errorMessage;

  List<ItemModel> _activeItems = [];
  List<ItemModel> _useFirstItems = [];
  int _usedBeforeExpiringThisWeekCount = 0;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  ItemsProvider({
    required ItemsRepository repository,
    VoidCallback? onUnauthorized,
  })  : _repository = repository,
        _onUnauthorized = onUnauthorized;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ItemModel> get activeItems => _activeItems;
  List<ItemModel> get useFirstItems => _useFirstItems;
  int get usedBeforeExpiringThisWeekCount => _usedBeforeExpiringThisWeekCount;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Total count of active items in the household pantry.
  int get itemsAtHomeCount => _activeItems.length;

  /// Count of items expiring soon or already expired (soon + expired).
  int get expiringSoonCount => _activeItems
      .where((item) =>
          item.expiryStatus == 'soon' || item.expiryStatus == 'expired')
      .length;

  /// Count of items that have passed their expiration date.
  int get expiredCount =>
      _activeItems.where((item) => item.expiryStatus == 'expired').length;

  /// Dynamic list of categories present in active inventory plus 'All'.
  List<String> get categories {
    final categorySet = <String>{};
    for (final item in _activeItems) {
      if (item.category != null && item.category!.trim().isNotEmpty) {
        categorySet.add(item.category!.trim());
      }
    }
    final sortedList = categorySet.toList()..sort();
    return ['All', ...sortedList];
  }

  /// Active pantry items filtered by selected category and search text.
  List<ItemModel> get filteredItems {
    return _activeItems.where((item) {
      // Category filter
      if (_selectedCategory != 'All') {
        if (item.category?.trim().toLowerCase() !=
            _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // Search query filter (case-insensitive substring)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesCategory =
            item.category?.toLowerCase().contains(query) ?? false;
        final matchesLocation =
            item.location?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesCategory && !matchesLocation) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Loads Use First items, active inventory, and computes the 7-day progress line.
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getUseFirstItems(),
        _repository.getItems(status: 'active'),
        _repository.getItems(status: 'used'),
      ]);

      _useFirstItems = results[0];
      _activeItems = results[1];

      // Calculate progress line: items used in last 7 days whose used_at <= expiry_date
      final usedItems = results[2];
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      int count = 0;
      for (final item in usedItems) {
        if (item.usedAt != null && item.usedAt!.isAfter(sevenDaysAgo)) {
          // Compare calendar dates (used_at date <= expiry_date)
          final usedDate = DateTime(
            item.usedAt!.year,
            item.usedAt!.month,
            item.usedAt!.day,
          );
          final expDate = DateTime(
            item.expiryDate.year,
            item.expiryDate.month,
            item.expiryDate.day,
          );
          if (!usedDate.isAfter(expDate)) {
            count++;
          }
        }
      }
      _usedBeforeExpiringThisWeekCount = count;

      // Re-schedule daily expiry-summary notifications with fresh data.
      final reminderItems = _activeItems
          .map((i) => ReminderItem(name: i.name, expiryDate: i.expiryDate))
          .toList();
      NotificationService.instance.scheduleDailySummaries(reminderItems);

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

  /// Adds a new pantry item and refreshes inventory.
  Future<bool> addItem({
    required String name,
    required DateTime expiryDate,
    double? quantity,
    String? unit,
    String? category,
    String? location,
  }) async {
    try {
      await _repository.addItem(
        name: name,
        expiryDate: expiryDate,
        quantity: quantity,
        unit: unit,
        category: category,
        location: location,
      );
      await refreshAll();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      }
      rethrow;
    }
  }

  /// Updates an item and refreshes inventory.
  Future<bool> updateItem(
    String id, {
    String? name,
    DateTime? expiryDate,
    double? quantity,
    String? unit,
    String? category,
    String? location,
  }) async {
    try {
      await _repository.updateItem(
        id,
        name: name,
        expiryDate: expiryDate,
        quantity: quantity,
        unit: unit,
        category: category,
        location: location,
      );
      await refreshAll();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      }
      rethrow;
    }
  }

  /// Marks item as used.
  Future<void> markUsed(String id) async {
    try {
      await _repository.markUsed(id);
      await refreshAll();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      }
      rethrow;
    }
  }

  /// Marks item as thrown away.
  Future<void> markThrown(String id) async {
    try {
      await _repository.markThrown(id);
      await refreshAll();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      }
      rethrow;
    }
  }
}
