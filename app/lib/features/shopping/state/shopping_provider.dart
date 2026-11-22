import 'package:flutter/foundation.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/data/shopping_repository.dart';

/// Status of the mark-bought operation.
enum MarkBoughtStatus {
  success,
  alreadyBought,
  error,
}

/// Result returned from marking an item bought.
class MarkBoughtResult {
  final MarkBoughtStatus status;
  final String message;

  const MarkBoughtResult({
    required this.status,
    required this.message,
  });
}

/// Provider managing shopping list items, addition, and transition to pantry.
class ShoppingProvider extends ChangeNotifier {
  final ShoppingRepository _repository;
  final VoidCallback? _onUnauthorized;

  bool _isLoading = false;
  String? _errorMessage;
  List<ShoppingItem> _items = [];
  final Set<String> _processingItemIds = {};

  ShoppingProvider({
    required ShoppingRepository repository,
    VoidCallback? onUnauthorized,
  })  : _repository = repository,
        _onUnauthorized = onUnauthorized;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShoppingItem> get items => _items;

  /// Unbought items (sorted newest first by backend).
  List<ShoppingItem> get unboughtItems =>
      _items.where((item) => !item.bought).toList();

  /// Bought items (sorted most recently bought first by backend).
  List<ShoppingItem> get boughtItems =>
      _items.where((item) => item.bought).toList();

  /// Checks if a specific item is currently being processed to prevent double-actions.
  bool isItemProcessing(String id) => _processingItemIds.contains(id);

  /// Loads shopping items from the server.
  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getShoppingItems();
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

  /// Adds a new item to the shopping list.
  Future<bool> addItem(String name, {double? quantity}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    try {
      await _repository.addShoppingItem(trimmedName, quantity: quantity);
      await loadItems();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      } else {
        _errorMessage = e.message;
        notifyListeners();
      }
      return false;
    } catch (_) {
      _errorMessage = 'Failed to add item to shopping list.';
      notifyListeners();
      return false;
    }
  }

  /// Marks a shopping item as bought and creates a corresponding pantry item.
  /// Prevents double-taps, handles 409 Conflict gracefully as 'already bought',
  /// and automatically triggers session logout on 401.
  Future<MarkBoughtResult> markItemBought(
    String id, {
    required DateTime expiryDate,
    double? quantity,
    String? unit,
    String? category,
    String? location,
  }) async {
    if (_processingItemIds.contains(id)) {
      return const MarkBoughtResult(
        status: MarkBoughtStatus.error,
        message: 'Action already in progress.',
      );
    }

    _processingItemIds.add(id);
    notifyListeners();

    try {
      await _repository.markBought(
        id,
        expiryDate: expiryDate,
        quantity: quantity,
        unit: unit,
        category: category,
        location: location,
      );
      await loadItems();
      return const MarkBoughtResult(
        status: MarkBoughtStatus.success,
        message: 'Item added to pantry',
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Treat 409 as 'already bought', refresh the list and inform the user friendly
        await loadItems();
        return const MarkBoughtResult(
          status: MarkBoughtStatus.alreadyBought,
          message: 'Item is already marked as bought.',
        );
      } else if (e.statusCode == 401) {
        _onUnauthorized?.call();
        return const MarkBoughtResult(
          status: MarkBoughtStatus.error,
          message: 'Session expired. Please log in again.',
        );
      } else {
        return MarkBoughtResult(
          status: MarkBoughtStatus.error,
          message: e.message,
        );
      }
    } catch (_) {
      return const MarkBoughtResult(
        status: MarkBoughtStatus.error,
        message: 'Failed to mark item as bought. Please try again.',
      );
    } finally {
      _processingItemIds.remove(id);
      notifyListeners();
    }
  }
}
