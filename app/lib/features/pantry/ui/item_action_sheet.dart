import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/pantry/ui/add_item_screen.dart';

/// Displays a modal bottom sheet allowing the user to mark an item as used,
/// mark it as thrown away, or edit its details.
Future<void> showItemActionSheet(
  BuildContext context,
  ItemModel item, {
  bool allowEdit = false,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with item name and expiry status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expires: ${item.expiryDate.year}-${item.expiryDate.month.toString().padLeft(2, '0')}-${item.expiryDate.day.toString().padLeft(2, '0')} (${item.daysLeftLabel})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Option 1: Mark as used
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Mark as used',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Item was eaten or cooked'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await context.read<ItemsProvider>().markUsed(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} marked as used'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 4),

              // Option 2: Thrown away
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFC62828),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Thrown away',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Item spoiled or discarded'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await context.read<ItemsProvider>().markThrown(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} marked as thrown away'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (_) {}
                },
              ),

              // Option 3: Edit details (if requested or enabled)
              if (allowEdit) ...[
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Edit item',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Update name, expiry, or details'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddItemScreen(itemToEdit: item),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
