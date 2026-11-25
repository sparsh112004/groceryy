import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/grocery_catalog.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/features/shopping/ui/add_shopping_item_sheet.dart';
import 'package:pantry_app/features/shopping/ui/add_to_pantry_flow_screen.dart';
import 'package:pantry_app/features/shopping/ui/shopping_receipt_screen.dart';

/// Shopping list screen:
/// - Header: "Shopping list" with a Receipt icon button
/// - Search field: "Search items to add" showing up to 6 catalog matches
///   (or an "Add [typed text] as a new item" tile when nothing matches)
/// - Gentle non-blocking duplicate hint if typed name matches active pantry item
/// - Unbought items grouped under category headers with local picked checkboxes
///   and swipe/icon remove (archived=true + Undo SnackBar)
/// - Collapsed "Bought recently" section for already-bought items
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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

  /// Finds an active pantry item that matches the input name (case-insensitive).
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

  /// Generates the duplicate hint copy (e.g. 'You already have Milk (expires in 3 days)').
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
    } else if (added == null || added == false) {
      final error = shoppingProvider.errorMessage;
      if (added == false && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 3),
          ),
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
      SnackBar(
        content: Text(label),
        duration: const Duration(seconds: 3),
      ),
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
            // Header: "Shopping list" + Receipt button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shopping list',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        size: 26,
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

            // Search field: "Search items to add"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search items to add',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6B7280),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4B5563),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4B5563),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                  // Duplicate hint (non-blocking, gentle note)
                  if (matchingPantryItem != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFDBA74),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: Color(0xFFC2410C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDuplicateHint(matchingPantryItem),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Catalog search suggestions
                  if (query.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          if (catalogMatches.isNotEmpty)
                            for (int i = 0; i < catalogMatches.length; i++) ...[
                              _buildCatalogMatchTile(catalogMatches[i]),
                              if (i < catalogMatches.length - 1)
                                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            ]
                          else
                            _buildNewItemTile(query),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Content body: Loading, Error, Empty, or List
            Expanded(
              child: Builder(
                builder: (context) {
                  if (shopping.isLoading && !hasItems) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              shopping.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => shopping.loadItems(),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 48),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!hasItems) {
                    return RefreshIndicator(
                      onRefresh: () => shopping.loadItems(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 380,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Your shopping list is clear. Search above to add what you need.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      children: [
                        // Unbought items grouped by category
                        for (final entry in groupedUnbought.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 6),
                            child: Text(
                              entry.key,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          for (final item in entry.value) ...[
                            _buildUnboughtItemRow(item, shopping),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE5E7EB),
                            ),
                          ],
                        ],

                        // Collapsed "Bought recently" section
                        if (bought.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Theme(
                            data: theme.copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              initiallyExpanded: false,
                              title: Text(
                                'Bought recently (${bought.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              children: [
                                for (final item in bought) ...[
                                  _buildBoughtItemRow(item),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            if (unbought.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openAddToPantryFlow,
                    icon: const Icon(Icons.kitchen_outlined, size: 22),
                    label: const Text(
                      'I am back: Add to pantry',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${item.category} • ${item.defaultUnit}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF0F766E),
              size: 24,
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
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF0F766E),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add "$query" as a new item',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Unbought item row: Checkbox toggles local picked state; swipe or icon archives item.
  Widget _buildUnboughtItemRow(
    ShoppingItem item,
    ShoppingProvider shopping,
  ) {
    final isPicked = shopping.isPicked(item.id);
    final qty = item.formattedQuantity;

    return Dismissible(
      key: ValueKey('shopping_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: const Color(0xFFDC2626),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      onDismissed: (_) => _archiveItem(item),
      child: InkWell(
        onTap: () => shopping.togglePicked(item.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  value: isPicked,
                  onChanged: (_) => shopping.togglePicked(item.id),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(
                    color: Color(0xFF4B5563),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: isPicked
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    decoration:
                        isPicked ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              if (qty != null) ...[
                const SizedBox(width: 8),
                Text(
                  qty,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isPicked
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF4B5563),
                    decoration:
                        isPicked ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ],
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: Color(0xFF6B7280),
                  ),
                  tooltip: 'Remove ${item.name}',
                  onPressed: () => _archiveItem(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bought item row: Disabled checked Checkbox + strikethrough name + quantity.
  Widget _buildBoughtItemRow(ShoppingItem item) {
    final qty = item.formattedQuantity;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Checkbox(
              value: true,
              onChanged: null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          if (qty != null) ...[
            const SizedBox(width: 8),
            Text(
              qty,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF9CA3AF),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
