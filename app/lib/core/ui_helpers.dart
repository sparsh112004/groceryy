import 'package:flutter/material.dart';

/// Returns a friendly emoji for a grocery item based on its name and category.
String itemEmoji(String itemName, String? category) {
  final lower = itemName.toLowerCase();

  if (lower.contains('milk') || lower.contains('doodh')) return '🥛';
  if (lower.contains('paneer') || lower.contains('cheese')) return '🧀';
  if (lower.contains('butter') || lower.contains('ghee')) return '🧈';
  if (lower.contains('curd') || lower.contains('yogurt')) return '🥣';
  if (lower.contains('egg')) return '🥚';
  if (lower.contains('bread') || lower.contains('bun') || lower.contains('pav')) {
    return '🍞';
  }
  if (lower.contains('rice') || lower.contains('atta') || lower.contains('flour')) {
    return '🌾';
  }
  if (lower.contains('noodle') || lower.contains('pasta') || lower.contains('maggi')) {
    return '🍜';
  }
  if (lower.contains('honey') || lower.contains('jam')) return '🍯';
  if (lower.contains('salt') || lower.contains('sugar')) return '🧂';
  if (lower.contains('oil')) return '🫗';
  if (lower.contains('tea') || lower.contains('chai') || lower.contains('coffee')) {
    return '☕';
  }
  if (lower.contains('banana')) return '🍌';
  if (lower.contains('apple')) return '🍎';
  if (lower.contains('mango')) return '🥭';
  if (lower.contains('tomato')) return '🍅';
  if (lower.contains('potato') || lower.contains('aloo')) return '🥔';
  if (lower.contains('onion') || lower.contains('pyaz')) return '🧅';
  if (lower.contains('carrot')) return '🥕';

  switch (category?.trim()) {
    case 'Dairy':
      return '🥛';
    case 'Fruits':
      return '🍎';
    case 'Vegetables':
      return '🥦';
    case 'Grains & Flours':
      return '🌾';
    case 'Pulses':
      return '🫘';
    case 'Spices':
      return '🌶️';
    case 'Snacks':
      return '🥨';
    case 'Beverages':
      return '🥤';
    case 'Bakery':
      return '🍞';
    case 'Oils & Condiments':
      return '🫒';
    case 'Frozen':
      return '🧊';
    default:
      return '🧺';
  }
}

/// Soft rounded emoji badge shown next to grocery items.
class ItemEmojiBadge extends StatelessWidget {
  final String name;
  final String? category;
  final double size;

  const ItemEmojiBadge({
    super.key,
    required this.name,
    this.category,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        itemEmoji(name, category),
        style: TextStyle(fontSize: size * 0.52),
      ),
    );
  }
}
