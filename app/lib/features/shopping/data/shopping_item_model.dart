/// Representation of a shopping list item.
class ShoppingItem {
  final String id;
  final String householdId;
  final String name;
  final double? quantity;
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
    required this.bought,
    this.boughtAt,
    required this.archived,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted name with quantity if available, e.g. "Tomatoes (2)"
  String get displayTitle {
    if (quantity != null) {
      final formattedQty = quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toString();
      return '$name ($formattedQty)';
    }
    return name;
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String? ?? '',
      householdId: json['household_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
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
      'bought': bought,
      if (boughtAt != null) 'bought_at': boughtAt!.toIso8601String(),
      'archived': archived,
      'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
