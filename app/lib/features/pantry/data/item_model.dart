/// Representation of a pantry inventory item.
class ItemModel {
  final String id;
  final String householdId;
  final String name;
  final DateTime expiryDate;
  final String status; // 'active', 'used', 'thrown'
  final int daysLeft;
  final String expiryStatus; // 'fresh', 'soon', 'expired'
  final double? quantity;
  final String? unit;
  final String? category;
  final String? location;
  final String? barcode;
  final String addedBy;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.id,
    required this.householdId,
    required this.name,
    required this.expiryDate,
    required this.status,
    required this.daysLeft,
    required this.expiryStatus,
    this.quantity,
    this.unit,
    this.category,
    this.location,
    this.barcode,
    required this.addedBy,
    this.usedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Human-friendly display title including quantity and unit if available (e.g. "Milk (1 L)").
  String get displayTitle {
    if (quantity != null) {
      final formattedQty = quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toString();
      if (unit != null && unit!.trim().isNotEmpty) {
        return '$name ($formattedQty ${unit!.trim()})';
      }
      return '$name ($formattedQty)';
    }
    return name;
  }

  /// Compact formatted days left string (e.g. "2 days", "Today", "Expired").
  String get daysLeftLabel {
    if (daysLeft < 0) {
      return 'Expired';
    } else if (daysLeft == 0) {
      return 'Today';
    } else if (daysLeft == 1) {
      return '1 day';
    } else {
      return '$daysLeft days';
    }
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedExpiry;
    final rawExpiry = json['expiry_date'];
    if (rawExpiry is String) {
      parsedExpiry = DateTime.parse(rawExpiry);
    } else if (rawExpiry is DateTime) {
      parsedExpiry = rawExpiry;
    } else {
      parsedExpiry = DateTime.now();
    }

    return ItemModel(
      id: json['id'] as String? ?? '',
      householdId: json['household_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      expiryDate: parsedExpiry,
      status: json['status'] as String? ?? 'active',
      daysLeft: json['days_left'] as int? ?? 0,
      expiryStatus: json['expiry_status'] as String? ?? 'fresh',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      location: json['location'] as String?,
      barcode: json['barcode'] as String?,
      addedBy: json['added_by'] as String? ?? '',
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
