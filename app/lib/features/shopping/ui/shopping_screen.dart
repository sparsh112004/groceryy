import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/grocery_catalog.dart';
import 'package:pantry_app/core/ui_helpers.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/features/shopping/ui/add_shopping_item_sheet.dart';
import 'package:pantry_app/features/shopping/ui/add_to_pantry_flow_screen.dart';
import 'package:pantry_app/features/shopping/ui/shopping_receipt_screen.dart';

enum _ShoppingTab { toBuy, bought }

/// Shopping list screen with soothing sage cards, To Buy / Bought toggle, and catalog search.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _ShoppingTab _activeTab = _ShoppingTab.toBuy;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingProvider>().loadItems();
      final itemsProvider = context.read<ItemsProvider>();
      if (itemsProvider.activeItems.isEmpty && !itemsProvider.isLoading) {
        itemsProvider.refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  ItemModel? _findMatchingPantryItem(
    String input,
    List<ItemModel> activePantryItems,
  ) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    final matches = activePantryItems
        .where((item) => item.name.trim().toLowerCase() == trimmed)
        .toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return matches.first;
  }

  String _formatDuplicateHint(ItemModel item) {
    String expiryText;
    if (item.daysLeft < 0) {
      expiryText = 'expired';
    } else if (item.daysLeft == 0) {
      expiryText = 'expires today';
    } else if (item.daysLeft == 1) {
      expiryText = 'expires tomorrow';
    } else {
      expiryText = 'expires in ${item.daysLeft} days';
    }
    return 'You already have ${item.name} ($expiryText)';
  }

  Future<void> _openAddSheet({
    required String itemName,
    required String category,
    required String initialUnit,
  }) async {
    final shoppingProvider = context.read<ShoppingProvider>();
    final added = await AddShoppingItemSheet.show(
      context,
      itemName: itemName,
      category: category,
      initialUnit: initialUnit,
      onConfirm: (quantity, unit, selectedCategory) {
        return shoppingProvider.addItem(
          itemName,
          quantity: quantity,
          unit: unit,
          category: selectedCategory,
        );
      },
    );

    if (!mounted) return;

    if (added == true) {
      _textController.clear();
      _focusNode.unfocus();
    } else if (added == false) {
      final error = shoppingProvider.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _openAddToPantryFlow() async {
    final addedCount = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => const AddToPantryFlowScreen(),
      ),
    );

    if (!mounted || addedCount == null || addedCount <= 0) return;

    final label = addedCount == 1
        ? '1 item added to pantry'
        : '$addedCount items added to pantry';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _archiveItem(ShoppingItem item) async {
    final shoppingProvider = context.read<ShoppingProvider>();
    final success = await shoppingProvider.archiveItem(item.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${item.name}'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              shoppingProvider.unarchiveItem(item.id);
            },
          ),
        ),
      );
    } else if (shoppingProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shoppingProvider.errorMessage!),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Map<String, List<ShoppingItem>> _groupUnboughtByCategory(
    List<ShoppingItem> unbought,
  ) {
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in unbought) {
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

  Widget _buildTabToggle(int toBuyCount, int boughtCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EDE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            label: 'To Buy ($toBuyCount)',
            selected: _activeTab == _ShoppingTab.toBuy,
            onTap: () => setState(() => _activeTab = _ShoppingTab.toBuy),
          ),
          _buildSegmentButton(
            label: 'Bought ($boughtCount)',
            selected: _activeTab == _ShoppingTab.bought,
            onTap: () => setState(() => _activeTab = _ShoppingTab.bought),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? AppTheme.primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopping = context.watch<ShoppingProvider>();
    final pantry = context.watch<ItemsProvider>();

    final query = _textController.text.trim();
    final catalogMatches =
        query.isEmpty ? const <CatalogItem>[] : searchCatalog(query, limit: 6);
    final matchingPantryItem = _findMatchingPantryItem(
      _textController.text,
      pantry.activeItems,
    );

    final unbought = shopping.unboughtItems;
    final bought = shopping.boughtItems;
    final hasItems = unbought.isNotEmpty || bought.isNotEmpty;
    final groupedUnbought = _groupUnboughtByCategory(unbought);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: "Shopping List" + Receipt button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_rounded,
                    color: AppTheme.primaryGreen,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Shopping List',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        size: 25,
                        color: AppTheme.textPrimary,
                      ),
                      tooltip: 'Receipt',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ShoppingReceiptScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Search/Add field + Segmented Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Add an item...',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      suffixIcon: query.isNotEmpty
                          ? SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                tooltip: 'Clear search',
                                onPressed: () => _textController.clear(),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                    ),
                  ),

                  if (matchingPantryItem != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusSoonContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF3CF9B),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppTheme.statusSoon,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDuplicateHint(matchingPantryItem),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.statusSoon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (query.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: AppTheme.cardDecoration(radius: 14),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          if (catalogMatches.isNotEmpty)
                            for (int i = 0; i < catalogMatches.length; i++) ...[
                              _buildCatalogMatchTile(catalogMatches[i]),
                              if (i < catalogMatches.length - 1)
                                const Divider(
                                  height: 1,
                                  color: AppTheme.borderSubtle,
                                ),
                            ]
                          else
                            _buildNewItemTile(query),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _buildTabToggle(unbought.length, bought.length),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Content body
            Expanded(
              child: Builder(
                builder: (context) {
                  if (shopping.isLoading && !hasItems) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (shopping.errorMessage != null && !hasItems) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppTheme.statusExpired,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              shopping.errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: () => shopping.loadItems(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final activeList =
                      _activeTab == _ShoppingTab.toBuy ? unbought : bought;

                  if (activeList.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => shopping.loadItems(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 56,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _activeTab == _ShoppingTab.toBuy
                                      ? Icons.shopping_cart_outlined
                                      : Icons.check_circle_outline_rounded,
                                  size: 60,
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _activeTab == _ShoppingTab.toBuy
                                      ? 'Your shopping list is clear.\nSearch above to add what you need.'
                                      : 'No bought items yet.\nItems you mark as purchased will appear here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        shopping.loadItems(),
                        pantry.refreshAll(),
                      ]);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        if (_activeTab == _ShoppingTab.toBuy)
                          for (final entry in groupedUnbought.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    itemEmoji('', entry.key),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < entry.value.length;
                                      i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                        color: AppTheme.borderSubtle,
                                      ),
                                    _buildUnboughtItemRow(
                                      entry.value[i],
                                      shopping,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ]
                        else
                          Container(
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              children: [
                                for (int i = 0; i < bought.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: AppTheme.borderSubtle,
                                    ),
                                  _buildBoughtItemRow(bought[i]),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_activeTab == _ShoppingTab.toBuy && unbought.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _openAddToPantryFlow,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: const Text(
                      'Mark as Purchased',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogMatchTile(CatalogItem item) {
    return InkWell(
      onTap: () => _openAddSheet(
        itemName: item.name,
        category: item.category,
        initialUnit: item.defaultUnit,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(
              itemEmoji(item.name, item.category),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.softMintTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreenDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewItemTile(String query) {
    return InkWell(
      onTap: () => _openAddSheet(
        itemName: query,
        category: categoryFor(query),
        initialUnit: 'pcs',
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primaryGreen,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add "$query" as a new item',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnboughtItemRow(
    ShoppingItem item,
    ShoppingProvider shopping,
  ) {
    final picked = shopping.isPicked(item.id);
    final qty = item.formattedQuantity;

    return Dismissible(
      key: ValueKey('shopping_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.statusExpiredContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.statusExpired,
        ),
      ),
      onDismissed: (_) => _archiveItem(item),
      child: InkWell(
        onTap: () => shopping.togglePicked(item.id),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Checkbox(
                  value: picked,
                  activeColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (_) => shopping.togglePicked(item.id),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  qty != null ? '${item.name} ($qty)' : item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: picked
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    decoration: picked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: AppTheme.textSecondary,
                ),
                tooltip: 'Remove item',
                onPressed: () => _archiveItem(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoughtItemRow(ShoppingItem item) {
    final qty = item.formattedQuantity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Checkbox(
              value: true,
              onChanged: null,
              fillColor: WidgetStateProperty.all(
                AppTheme.primaryGreen.withValues(alpha: 0.55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              qty != null ? '${item.name} ($qty)' : item.name,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
