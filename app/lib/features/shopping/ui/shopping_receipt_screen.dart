import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/grocery_catalog.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';

/// Paper-receipt style view of the current unbought shopping list.
class ShoppingReceiptScreen extends StatelessWidget {
  const ShoppingReceiptScreen({super.key});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatToday() {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  Map<String, List<ShoppingItem>> _groupByCategory(List<ShoppingItem> items) {
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final cat = item.effectiveCategory;
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    final ordered = <String, List<ShoppingItem>>{};
    for (final cat in kCategories) {
      final list = grouped.remove(cat);
      if (list != null && list.isNotEmpty) {
        ordered[cat] = list;
      }
    }
    final remainingKeys = grouped.keys.toList()..sort();
    for (final key in remainingKeys) {
      ordered[key] = grouped[key]!;
    }
    return ordered;
  }

  String _buildPlainText(Map<String, List<ShoppingItem>> grouped) {
    final buffer = StringBuffer();
    buffer.writeln('Stockora Shopping List');
    buffer.writeln(_formatToday());
    buffer.writeln();

    for (final entry in grouped.entries) {
      buffer.writeln(entry.key);
      for (final item in entry.value) {
        final qty = item.formattedQuantity;
        if (qty != null) {
          buffer.writeln('- ${item.name} ($qty)');
        } else {
          buffer.writeln('- ${item.name}');
        }
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ShoppingProvider>().unboughtItems;
    final grouped = _groupByCategory(items);
    final theme = Theme.of(context);

    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: Color(0xFF1F2937),
      height: 1.4,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receipt',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Stockora Shopping List',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatToday(),
                        textAlign: TextAlign.center,
                        style: monoStyle.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _DashedSeparator(),
                      const SizedBox(height: 16),
                      if (grouped.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No items on your list.',
                            textAlign: TextAlign.center,
                            style: monoStyle.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        for (final entry in grouped.entries) ...[
                          Text(
                            entry.key.toUpperCase(),
                            style: monoStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          for (final item in entry.value) ...[
                            _ReceiptLine(
                              name: item.name,
                              quantity: item.formattedQuantity,
                              style: monoStyle,
                            ),
                            const SizedBox(height: 4),
                          ],
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 4),
                      const _DashedSeparator(),
                      const SizedBox(height: 14),
                      Text(
                        '${items.length} items',
                        textAlign: TextAlign.center,
                        style: monoStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final text = _buildPlainText(grouped);
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('List copied'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        label: const Text(
                          'Copy list',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String name;
  final String? quantity;
  final TextStyle style;

  const _ReceiptLine({
    required this.name,
    required this.quantity,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (quantity == null) {
      return Text(name, style: style);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.62,
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '.' * 80,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: style.copyWith(color: const Color(0xFF9CA3AF)),
                ),
              ),
            ),
            Text(quantity!, style: style),
          ],
        );
      },
    );
  }
}

class _DashedSeparator extends StatelessWidget {
  const _DashedSeparator();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset((startX + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
