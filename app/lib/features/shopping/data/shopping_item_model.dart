import 'package:pantry_app/core/grocery_catalog.dart';

/// Representation of a shopping list item.
class ShoppingItem {
  final String id;
  final String householdId;
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final bool bought;
  final DateTime? boughtAt;
  final bool archived;
  final String addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItem({
    required this.id,
    required this.householdId,
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    required this.bought,
    this.boughtAt,
    required this.archived,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formats decimal quantity cleanly (e.g. 2.0 -> "2", 0.5 -> "0.5").
  static String formatQuantityNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// Formatted quantity and unit, e.g. "2 kg", "0.5 L", or null if neither is set.
  String? get formattedQuantity {
    final cleanUnit = unit?.trim();
    final hasUnit = cleanUnit != null && cleanUnit.isNotEmpty;
    if (quantity != null && hasUnit) {
      return '${formatQuantityNumber(quantity!)} $cleanUnit';
    }
    if (quantity != null) {
      return formatQuantityNumber(quantity!);
    }
    if (hasUnit) {
      return cleanUnit;
    }
    return null;
  }

  /// Effective category using the stored category or catalog fallback.
  String get effectiveCategory {
    final clean = category?.trim();
    if (clean != null && clean.isNotEmpty) {
      return clean;
    }
    return categoryFor(name);
  }

  /// Formatted name with quantity/unit if available, e.g. "Rice (2 kg)".
  String get displayTitle {
    final qty = formattedQuantity;
    if (qty != null) {
      return '$name ($qty)';
    }
    return name;
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String? ?? '',
      householdId: json['household_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      bought: json['bought'] as bool? ?? false,
      boughtAt: json['bought_at'] != null
          ? DateTime.tryParse(json['bought_at'].toString())
          : null,
      archived: json['archived'] as bool? ?? false,
      addedBy: json['added_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      'bought': bought,
      if (boughtAt != null) 'bought_at': boughtAt!.toIso8601String(),
      'archived': archived,
      'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
