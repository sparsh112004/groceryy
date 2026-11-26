import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/grocery_catalog.dart';
import 'package:pantry_app/core/ui_helpers.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';

enum _HistoryPeriod { all, thisWeek, thisMonth }

enum _HistoryGroupMode { name, tag }

/// Purchase History screen showing bought items with quantity, category, and purchase date/time.
class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  _HistoryPeriod _period = _HistoryPeriod.all;
  _HistoryGroupMode _groupMode = _HistoryGroupMode.name;
  String _searchQuery = '';

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonths = [
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

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopping = context.read<ShoppingProvider>();
      if (shopping.items.isEmpty && !shopping.isLoading) {
        shopping.loadItems();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next != _searchQuery) {
      setState(() {
        _searchQuery = next;
      });
    }
  }

  DateTime _purchaseTimestamp(ShoppingItem item) {
    return (item.boughtAt ?? item.updatedAt).toLocal();
  }

  String _formatDateHeader(DateTime date) {
    final month = _months[date.month - 1];
    final weekday = _weekdays[date.weekday - 1];
    return '$month ${date.day}, ${date.year} ($weekday)';
  }

  String _formatShortDate(DateTime date) {
    final month = _shortMonths[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour24 = date.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  List<ShoppingItem> _filteredBoughtItems(List<ShoppingItem> boughtItems) {
    final now = DateTime.now();
    final sorted = List<ShoppingItem>.from(boughtItems)
      ..sort(
        (a, b) => _purchaseTimestamp(b).compareTo(_purchaseTimestamp(a)),
      );

    return sorted.where((item) {
      final ts = _purchaseTimestamp(item);
      if (_period == _HistoryPeriod.thisWeek) {
        final weekAgo = now.subtract(const Duration(days: 7));
        if (ts.isBefore(weekAgo)) return false;
      } else if (_period == _HistoryPeriod.thisMonth) {
        if (ts.year != now.year || ts.month != now.month) return false;
      }

      if (_searchQuery.isEmpty) return true;
      final nameMatch = item.name.toLowerCase().contains(_searchQuery);
      final categoryMatch =
          item.effectiveCategory.toLowerCase().contains(_searchQuery);
      return nameMatch || categoryMatch;
    }).toList();
  }

  Map<DateTime, List<ShoppingItem>> _groupByDate(List<ShoppingItem> items) {
    final grouped = <DateTime, List<ShoppingItem>>{};
    for (final item in items) {
      final dt = _purchaseTimestamp(item);
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      grouped.putIfAbsent(dayKey, () => []).add(item);
    }
    return grouped;
  }

  Map<String, List<ShoppingItem>> _groupByCategory(List<ShoppingItem> items) {
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.effectiveCategory, () => []).add(item);
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Filter by Product Name',
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: AppTheme.textSecondary,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Clear filter',
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
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPeriodChip('All', _HistoryPeriod.all),
              const SizedBox(width: 8),
              _buildPeriodChip('This Week', _HistoryPeriod.thisWeek),
              const SizedBox(width: 8),
              _buildPeriodChip('This Month', _HistoryPeriod.thisMonth),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE7EDE8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSegmentButton(
                label: 'Name',
                selected: _groupMode == _HistoryGroupMode.name,
                onTap: () => setState(() => _groupMode = _HistoryGroupMode.name),
              ),
              _buildSegmentButton(
                label: 'Tag',
                selected: _groupMode == _HistoryGroupMode.tag,
                onTap: () => setState(() => _groupMode = _HistoryGroupMode.tag),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, _HistoryPeriod period) {
    final selected = _period == period;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppTheme.primaryGreen : AppTheme.borderSubtle,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      onSelected: (_) => setState(() => _period = period),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateGroupSection(DateTime day, List<ShoppingItem> items) {
    final countLabel = items.length == 1
        ? '1 item purchased'
        : '${items.length} items purchased';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.softMintTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateHeader(day),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppTheme.borderSubtle,
              ),
            _buildHistoryRow(
              items[i],
              trailingText: _formatTime(_purchaseTimestamp(items[i])),
              subtitleText: items[i].effectiveCategory,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryGroupSection(
    String category,
    List<ShoppingItem> items,
  ) {
    final countLabel =
        items.length == 1 ? '1 item' : '${items.length} items';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  itemEmoji('', category),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppTheme.borderSubtle,
              ),
            _buildHistoryRow(
              items[i],
              trailingText: _formatShortDate(_purchaseTimestamp(items[i])),
              subtitleText: _formatTime(_purchaseTimestamp(items[i])),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    ShoppingItem item, {
    required String trailingText,
    required String subtitleText,
  }) {
    final qty = item.formattedQuantity;
    final title = qty != null ? '$qty ${item.name}' : item.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ItemEmojiBadge(
            name: item.name,
            category: item.effectiveCategory,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.softMintTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailingText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty || _period != _HistoryPeriod.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.search_off_rounded : Icons.history_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No matching purchases'
                  : 'No purchase history yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try another product name or change the filter.'
                  : 'Items you mark as bought on your Shopping list will appear here with their quantity and date.',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final filteredItems = _filteredBoughtItems(shopping.boughtItems);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => shopping.loadItems(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.history_rounded,
                          color: AppTheme.primaryGreen,
                          size: 26,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildFilterRow(),
                  ],
                ),
              ),
              Expanded(
                child: shopping.isLoading && shopping.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [_buildEmptyState()],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            children: _groupMode == _HistoryGroupMode.name
                                ? _groupByDate(filteredItems)
                                    .entries
                                    .map(
                                      (entry) => _buildDateGroupSection(
                                        entry.key,
                                        entry.value,
                                      ),
                                    )
                                    .toList()
                                : _groupByCategory(filteredItems)
                                    .entries
                                    .map(
                                      (entry) => _buildCategoryGroupSection(
                                        entry.key,
                                        entry.value,
                                      ),
                                    )
                                    .toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
