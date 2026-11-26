import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/ui_helpers.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/pantry/ui/add_item_screen.dart';
import 'package:pantry_app/features/pantry/ui/item_action_sheet.dart';

/// Pantry inventory screen with soft sage cards, category chips, and status pills.
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge(ItemModel item) {
    Color textColor;
    Color bgColor;
    String label;

    switch (item.expiryStatus) {
      case 'expired':
        textColor = AppTheme.statusExpired;
        bgColor = AppTheme.statusExpiredContainer;
        label = 'Expired';
        break;
      case 'soon':
        textColor = AppTheme.statusSoon;
        bgColor = AppTheme.statusSoonContainer;
        label = item.daysLeftLabel;
        break;
      case 'fresh':
      default:
        textColor = AppTheme.statusFresh;
        bgColor = AppTheme.statusFreshContainer;
        label = 'Fresh';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _subtitleForItem(ItemModel item) {
    final parts = <String>[];
    if (item.category != null && item.category!.trim().isNotEmpty) {
      parts.add(item.category!.trim());
    }
    if (item.quantity != null) {
      final qtyStr = item.quantity! % 1 == 0
          ? item.quantity!.toInt().toString()
          : item.quantity!.toString();
      if (item.unit != null && item.unit!.trim().isNotEmpty) {
        parts.add('$qtyStr ${item.unit!.trim()}');
      } else {
        parts.add(qtyStr);
      }
    }
    if (parts.isEmpty) {
      return 'Expires: ${item.daysLeftLabel}';
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsProvider = context.watch<ItemsProvider>();
    final items = itemsProvider.filteredItems;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => itemsProvider.refreshAll(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header + Add Item pill + Search Box
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.kitchen_rounded,
                          color: AppTheme.primaryGreen,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pantry',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddItemScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Item'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: AppTheme.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  itemsProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.borderSubtle,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) {
                        itemsProvider.setSearchQuery(val);
                      },
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: itemsProvider.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = itemsProvider.categories[index];
                    final isSelected = itemsProvider.selectedCategory == cat;
                    final chipLabel =
                        cat == 'All' ? 'All' : '${itemEmoji('', cat)} $cat';

                    return ChoiceChip(
                      label: Text(
                        chipLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.borderSubtle,
                        ),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      onSelected: (_) {
                        itemsProvider.setSelectedCategory(cat);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Items (${items.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),

              // Active Items List
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (itemsProvider.isLoading &&
                        itemsProvider.activeItems.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (itemsProvider.errorMessage != null &&
                        itemsProvider.activeItems.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 56,
                                color: AppTheme.statusExpired,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                itemsProvider.errorMessage!,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => itemsProvider.refreshAll(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (items.isEmpty) {
                      final hasFilter =
                          itemsProvider.searchQuery.isNotEmpty ||
                          itemsProvider.selectedCategory != 'All';

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.kitchen_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  hasFilter
                                      ? 'No items match your filter.'
                                      : 'Your pantry is empty.',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hasFilter
                                      ? 'Try clearing the search query or selecting "All".'
                                      : 'Tap Add Item to add your first grocery item.',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (!hasFilter) ...[
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const AddItemScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add your first item'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        Container(
                          decoration: AppTheme.cardDecoration(),
                          child: Column(
                            children: [
                              for (int i = 0; i < items.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: AppTheme.borderSubtle,
                                  ),
                                InkWell(
                                  onTap: () => showItemActionSheet(
                                    context,
                                    items[i],
                                    allowEdit: true,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        ItemEmojiBadge(
                                          name: items[i].name,
                                          category: items[i].category,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                items[i].displayTitle,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _subtitleForItem(items[i]),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildStatusBadge(items[i]),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
