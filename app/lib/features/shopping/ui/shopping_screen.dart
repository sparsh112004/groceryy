import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/features/shopping/ui/bought_bottom_sheet.dart';

/// Shopping list screen following Wireframe 4:
/// - Heading: "Shopping list"
/// - Text field: "Add to list" with Enter or Add button submission
/// - Duplicate hint: Gentle non-blocking note if name matches active pantry item
/// - Unbought items with checkboxes (tapping opens Bought bottom sheet)
/// - Bought section with crossed-out items and disabled checkboxes
/// - Pull to refresh, loading state, retry on error, and empty state
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingProvider>().loadItems();
      // Ensure pantry inventory is loaded for duplicate detection
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

  /// Finds an active pantry item that matches the input name (case-insensitive, trimmed).
  ItemModel? _findMatchingPantryItem(
    String input,
    List<ItemModel> activePantryItems,
  ) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    final matches = activePantryItems.where(
      (item) => item.name.trim().toLowerCase() == trimmed,
    ).toList();

    if (matches.isEmpty) return null;

    // Return the match expiring soonest
    matches.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return matches.first;
  }

  /// Generates the duplicate hint copy per SPEC (e.g. 'You already have Milk (expires in 3 days)').
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

  Future<void> _addItem() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);

    final shoppingProvider = context.read<ShoppingProvider>();
    final success = await shoppingProvider.addItem(text);

    if (mounted) {
      setState(() => _isAdding = false);
      if (success) {
        _textController.clear();
      } else {
        final error = shoppingProvider.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleItemTap(ShoppingItem item) async {
    if (item.bought) return;

    final shoppingProvider = context.read<ShoppingProvider>();
    final itemsProvider = context.read<ItemsProvider>();

    final result = await BoughtBottomSheet.show(
      context,
      item: item,
      onConfirm: (expiryDate) async {
        return await shoppingProvider.markItemBought(
          item.id,
          expiryDate: expiryDate,
        );
      },
    );

    if (result != null && mounted) {
      // Refresh pantry & home data on successful transition or 409 already bought
      if (result.status == MarkBoughtStatus.success ||
          result.status == MarkBoughtStatus.alreadyBought) {
        itemsProvider.refreshAll();
      }

      final message = result.status == MarkBoughtStatus.success
          ? '${item.name} added to pantry'
          : result.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopping = context.watch<ShoppingProvider>();
    final pantry = context.watch<ItemsProvider>();

    final matchingItem = _findMatchingPantryItem(
      _textController.text,
      pantry.activeItems,
    );

    final unbought = shopping.unboughtItems;
    final bought = shopping.boughtItems;
    final hasItems = unbought.isNotEmpty || bought.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: "Shopping list"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Shopping list',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: const Color(0xFF111827),
                ),
              ),
            ),

            // Input field: "Add to list"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addItem(),
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: 'Add to list',
                      hintStyle: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF9CA3AF),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
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
                      suffixIcon: _isAdding
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: _textController.text.trim().isNotEmpty
                                    ? theme.colorScheme.primary
                                    : const Color(0xFF9CA3AF),
                                size: 28,
                              ),
                              tooltip: 'Add to list',
                              onPressed: _textController.text.trim().isNotEmpty
                                  ? _addItem
                                  : null,
                            ),
                    ),
                  ),

                  // Duplicate hint (non-blocking, gentle note)
                  if (matchingItem != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                            size: 18,
                            color: Color(0xFFC2410C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDuplicateHint(matchingItem),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

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
                                'Your shopping list is clear. Add what you need.',
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
                        // Unbought items list (newest first)
                        for (int i = 0; i < unbought.length; i++) ...[
                          _buildUnboughtItemRow(unbought[i]),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE5E7EB),
                          ),
                        ],

                        // Bought items section
                        if (bought.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Bought',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          for (int i = 0; i < bought.length; i++) ...[
                            _buildBoughtItemRow(bought[i]),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE5E7EB),
                            ),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Unbought item row: Checkbox + Name, tapping triggers Bought flow bottom sheet
  Widget _buildUnboughtItemRow(ShoppingItem item) {
    return InkWell(
      onTap: () => _handleItemTap(item),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                value: false,
                onChanged: (_) => _handleItemTap(item),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(
                  color: Color(0xFF4B5563),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.displayTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bought item row: Disabled checked Checkbox + strikethrough name
  Widget _buildBoughtItemRow(ShoppingItem item) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.displayTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
