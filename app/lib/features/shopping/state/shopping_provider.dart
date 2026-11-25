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

/// Provider managing shopping list items, local picked state, and archiving.
class ShoppingProvider extends ChangeNotifier {
  final ShoppingRepository _repository;
  final VoidCallback? _onUnauthorized;

  bool _isLoading = false;
  String? _errorMessage;
  List<ShoppingItem> _items = [];
  final Set<String> _processingItemIds = {};
  final Set<String> _pickedItemIds = {};

  ShoppingProvider({
    required ShoppingRepository repository,
    VoidCallback? onUnauthorized,
  })  : _repository = repository,
        _onUnauthorized = onUnauthorized;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShoppingItem> get items => _items;
  Set<String> get pickedItemIds => Set.unmodifiable(_pickedItemIds);

  /// Unbought items (sorted newest first by backend).
  List<ShoppingItem> get unboughtItems =>
      _items.where((item) => !item.bought && !item.archived).toList();

  /// Bought items (sorted most recently bought first by backend).
  List<ShoppingItem> get boughtItems =>
      _items.where((item) => item.bought && !item.archived).toList();

  /// Checks if a specific item is currently being processed to prevent double-actions.
  bool isItemProcessing(String id) => _processingItemIds.contains(id);

  /// Checks whether an item is marked as picked in local memory.
  bool isPicked(String id) => _pickedItemIds.contains(id);

  /// Toggles the local, in-memory picked state of an item.
  void togglePicked(String id) {
    if (_pickedItemIds.contains(id)) {
      _pickedItemIds.remove(id);
    } else {
      _pickedItemIds.add(id);
    }
    notifyListeners();
  }

  /// Explicitly sets the local, in-memory picked state of an item.
  void setPicked(String id, bool picked) {
    if (picked) {
      _pickedItemIds.add(id);
    } else {
      _pickedItemIds.remove(id);
    }
    notifyListeners();
  }

  /// Clears all local picked states.
  void clearPicked() {
    if (_pickedItemIds.isEmpty) return;
    _pickedItemIds.clear();
    notifyListeners();
  }

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
  Future<bool> addItem(
    String name, {
    double? quantity,
    String? unit,
    String? category,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    try {
      await _repository.addShoppingItem(
        trimmedName,
        quantity: quantity,
        unit: unit,
        category: category,
      );
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

  /// Archives (removes) a shopping item via PATCH archived=true.
  Future<bool> archiveItem(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    ShoppingItem? removed;
    if (index != -1) {
      removed = _items[index];
      _items = List<ShoppingItem>.from(_items)..removeAt(index);
      notifyListeners();
    }

    try {
      await _repository.updateShoppingItem(id, archived: true);
      return true;
    } on ApiException catch (e) {
      if (removed != null) {
        _items = List<ShoppingItem>.from(_items)..insert(index, removed);
      }
      if (e.statusCode == 401) {
        _onUnauthorized?.call();
      } else {
        _errorMessage = e.message;
        notifyListeners();
      }
      return false;
    } catch (_) {
      if (removed != null) {
        _items = List<ShoppingItem>.from(_items)..insert(index, removed);
      }
      _errorMessage = 'Failed to remove item.';
      notifyListeners();
      return false;
    }
  }

  /// Restores an archived shopping item via PATCH archived=false.
  Future<bool> unarchiveItem(String id) async {
    try {
      await _repository.updateShoppingItem(id, archived: false);
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
      _errorMessage = 'Failed to restore item.';
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
