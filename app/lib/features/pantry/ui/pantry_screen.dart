import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/pantry/ui/add_item_screen.dart';
import 'package:pantry_app/features/pantry/ui/item_action_sheet.dart';

/// Pantry inventory screen following Wireframe 3:
/// - Header: Pantry
/// - Search field
/// - Category chips: All + active categories
/// - Active items sorted by expiry date
/// - Status pill: Fresh (check), Soon (warning), Expired (cross) (never color alone)
/// - Tap item row: opens action sheet with mark as used, thrown away, and edit options
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
    IconData icon;
    String label;

    switch (item.expiryStatus) {
      case 'expired':
        textColor = const Color(0xFFC62828);
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.close_rounded;
        label = 'Expired';
        break;
      case 'soon':
        textColor = const Color(0xFFE65100);
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.arrow_drop_up_rounded;
        label = 'Soon';
        break;
      case 'fresh':
      default:
        textColor = const Color(0xFF2E7D32);
        bgColor = const Color(0xFFE8F5E9);
        icon = Icons.circle_rounded;
        label = 'Fresh';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: item.expiryStatus == 'fresh' ? 10 : 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsProvider = context.watch<ItemsProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => itemsProvider.refreshAll(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Search Box
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantry',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search items TextField (Wireframe 3)
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search items',
                        prefixIcon: const Icon(Icons.search, size: 22),
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
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) {
                        itemsProvider.setSearchQuery(val);
                      },
                    ),
                  ],
                ),
              ),

              // Category Filter Chips (Wireframe 3: All, Dairy, Grains, Snacks, Spices, etc.)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: itemsProvider.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = itemsProvider.categories[index];
                    final isSelected = itemsProvider.selectedCategory == cat;

                    return FilterChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : const Color(0xFF374151),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primaryContainer,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : const Color(0xFFD1D5DB),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onSelected: (_) {
                        itemsProvider.setSelectedCategory(cat);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

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
                                color: Color(0xFFC62828),
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

                    final items = itemsProvider.filteredItems;

                    if (items.isEmpty) {
                      final hasFilter =
                          itemsProvider.searchQuery.isNotEmpty ||
                          itemsProvider.selectedCategory != 'All';

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                    : 'Tap + to add your first grocery item.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
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
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return InkWell(
                          onTap: () => showItemActionSheet(
                            context,
                            item,
                            allowEdit: true,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.displayTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(item),
                              ],
                            ),
                          ),
                        );
                      },
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
