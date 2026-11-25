import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/grocery_catalog.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/data/shopping_repository.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';

/// Full-screen 2-step flow for reviewing bought shopping items and adding them
/// to the pantry in a single bulk request.
class AddToPantryFlowScreen extends StatefulWidget {
  const AddToPantryFlowScreen({super.key});

  @override
  State<AddToPantryFlowScreen> createState() => _AddToPantryFlowScreenState();
}

class _AddToPantryFlowScreenState extends State<AddToPantryFlowScreen> {
  static const List<String> _baseUnits = [
    'pcs',
    'kg',
    'g',
    'L',
    'ml',
    'packet',
    'dozen',
  ];

  static const Map<String, List<double>> _unitQuantities = {
    'pcs': [1, 2, 3, 4, 6, 12],
    'packet': [1, 2, 3, 4, 6, 12],
    'dozen': [1, 2, 3, 4, 6, 12],
    'kg': [0.5, 1, 2, 5],
    'g': [100, 250, 500],
    'L': [0.5, 1, 2],
    'ml': [250, 500, 1000],
  };

  late final List<ShoppingItem> _unboughtItems;
  late final Set<String> _selectedIds;
  int _step = 1;
  List<_PantryDraftItem> _drafts = [];
  bool _isSubmitting = false;
  bool _isRetryMode = false;
  String? _bannerError;

  @override
  void initState() {
    super.initState();
    final shopping = context.read<ShoppingProvider>();
    _unboughtItems = List<ShoppingItem>.from(shopping.unboughtItems);
    final pickedIds = shopping.pickedItemIds;
    final prePicked = _unboughtItems
        .where((item) => pickedIds.contains(item.id))
        .map((item) => item.id)
        .toSet();

    // If user picked items in the list, pre-tick those; otherwise pre-tick all.
    if (prePicked.isNotEmpty) {
      _selectedIds = prePicked;
    } else {
      _selectedIds = _unboughtItems.map((item) => item.id).toSet();
    }
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_unboughtItems.map((item) => item.id));
    });
  }

  void _selectNone() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _goToStep2() {
    if (_selectedIds.isEmpty) return;

    for (final draft in _drafts) {
      draft.dispose();
    }

    final today = _todayDate();
    final selectedItems = _unboughtItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();

    _drafts = selectedItems
        .map((item) => _buildDraft(item, today))
        .toList();

    setState(() {
      _step = 2;
      _isRetryMode = false;
      _bannerError = null;
    });
  }

  _PantryDraftItem _buildDraft(ShoppingItem item, DateTime today) {
    final match = matchCatalogItem(item.name);

    final rawUnit = item.unit?.trim();
    final String unit = (rawUnit != null && rawUnit.isNotEmpty)
        ? rawUnit
        : (match?.defaultUnit ?? 'pcs');

    final presetQuantities = _unitQuantities[unit] ?? const [1.0, 2.0, 3.0];
    final double quantity = (item.quantity != null && item.quantity! > 0)
        ? item.quantity!
        : (presetQuantities.contains(1.0) ? 1.0 : presetQuantities.first);

    final String category = item.effectiveCategory;

    DateTime? expiryDate;
    bool isSuggestedExpiry = false;
    int? suggestedDays;
    if (match != null) {
      expiryDate = suggestedExpiry(match, today);
      isSuggestedExpiry = true;
      suggestedDays = match.shelfLifeDays;
    }

    return _PantryDraftItem(
      shoppingItem: item,
      unit: unit,
      quantity: quantity,
      category: category,
      expiryDate: expiryDate,
      isSuggestedExpiry: isSuggestedExpiry,
      suggestedDays: suggestedDays,
    );
  }

  bool get _canSubmitAll {
    if (_drafts.isEmpty || _isSubmitting) return false;
    return _drafts.every(
      (draft) => draft.expiryDate != null && draft.resolvedQuantity != null,
    );
  }

  Future<void> _submitBulk() async {
    if (!_canSubmitAll) return;

    setState(() {
      _isSubmitting = true;
      _bannerError = null;
      for (final draft in _drafts) {
        draft.errorMessage = null;
      }
    });

    final shoppingProvider = context.read<ShoppingProvider>();
    final itemsProvider = context.read<ItemsProvider>();

    final inputs = _drafts
        .map(
          (draft) => BulkBoughtItemInput(
            id: draft.shoppingItem.id,
            expiryDate: draft.expiryDate!,
            quantity: draft.resolvedQuantity,
            unit: draft.unit,
            category: draft.category,
          ),
        )
        .toList();

    final outcome = await shoppingProvider.markItemsBoughtBulk(inputs);

    if (!mounted) return;

    if (outcome.unauthorized) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      return;
    }

    if (outcome.errorMessage != null) {
      setState(() {
        _isSubmitting = false;
        _isRetryMode = true;
        _bannerError = outcome.errorMessage;
      });
      return;
    }

    final succeededCount = outcome.succeeded.length;
    final failedResults = outcome.failed;

    if (succeededCount > 0) {
      await itemsProvider.refreshAll();
    }

    if (!mounted) return;

    if (failedResults.isEmpty) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(succeededCount);
      return;
    }

    final failedById = {
      for (final result in failedResults) result.id: result.message,
    };

    final remainingDrafts = <_PantryDraftItem>[];
    for (final draft in _drafts) {
      final errMsg = failedById[draft.shoppingItem.id];
      if (errMsg != null) {
        draft.errorMessage = errMsg;
        remainingDrafts.add(draft);
      } else {
        draft.dispose();
      }
    }

    setState(() {
      _drafts = remainingDrafts;
      _isSubmitting = false;
      _isRetryMode = true;
      _bannerError = succeededCount > 0
          ? '$succeededCount ${_itemWord(succeededCount)} added. Please retry the failed ${_itemWord(remainingDrafts.length)} below.'
          : 'Some items could not be added. Please check the errors and retry.';
    });
  }

  String _itemWord(int count) => count == 1 ? 'item' : 'items';

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickCustomDate(_PantryDraftItem draft) async {
    if (_isSubmitting) return;
    final today = _todayDate();
    final initial = draft.expiryDate ?? today.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today.subtract(const Duration(days: 7)),
      lastDate: today.add(const Duration(days: 365 * 10)),
    );

    if (picked != null && mounted) {
      setState(() {
        draft.expiryDate = picked;
        draft.isSuggestedExpiry = false;
        draft.selectedExpiryChip = 'Pick date';
      });
    }
  }

  void _applyQuickExpiry(_PantryDraftItem draft, String label, int days) {
    if (_isSubmitting) return;
    final today = _todayDate();
    setState(() {
      draft.expiryDate = today.add(Duration(days: days));
      draft.isSuggestedExpiry = false;
      draft.selectedExpiryChip = label;
    });
  }

  void _handleBackNavigation() {
    if (_isSubmitting) return;
    if (_step == 2 && !_isRetryMode) {
      setState(() {
        _step = 1;
        _bannerError = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting && (_step == 1 || _isRetryMode),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 2 && !_isRetryMode && !_isSubmitting) {
          setState(() {
            _step = 1;
            _bannerError = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: _isSubmitting ? null : _handleBackNavigation,
            ),
          ),
          title: Text(
            _step == 1 ? 'Select bought items' : 'Add to pantry',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: _step == 1 ? _buildStep1(context) : _buildStep2(context),
        ),
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedIds.length;
    final nextLabel = 'Next: $selectedCount ${_itemWord(selectedCount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Check items you bought',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: _selectAll,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Select all',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectNone,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Select none',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _unboughtItems.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, index) {
              final item = _unboughtItems[index];
              final isChecked = _selectedIds.contains(item.id);
              final qty = item.formattedQuantity;

              return InkWell(
                onTap: () => _toggleSelected(item.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Checkbox(
                          value: isChecked,
                          onChanged: (_) => _toggleSelected(item.id),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (qty != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          qty,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: selectedCount > 0 ? _goToStep2 : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCount > 0
                    ? theme.colorScheme.primary
                    : const Color(0xFFE5E7EB),
                foregroundColor:
                    selectedCount > 0 ? Colors.white : const Color(0xFF9CA3AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                nextLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final theme = Theme.of(context);
    final count = _drafts.length;
    final canSubmit = _canSubmitAll;
    final buttonLabel = _isRetryMode
        ? 'Retry'
        : 'Add $count ${_itemWord(count)} to pantry';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              if (_bannerError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _bannerError!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Suggested dates are estimates. Check the date printed on packaged items.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              for (final draft in _drafts) ...[
                _buildItemCard(context, draft),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? _submitBulk : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? theme.colorScheme.primary
                    : const Color(0xFFE5E7EB),
                foregroundColor:
                    canSubmit ? Colors.white : const Color(0xFF9CA3AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, _PantryDraftItem draft) {
    final theme = Theme.of(context);
    final unitOptions = <String>[
      ..._baseUnits,
      if (!_baseUnits.contains(draft.unit)) draft.unit,
    ];

    final baseQuantities = _unitQuantities[draft.unit] ?? const [1.0, 2.0, 3.0];
    final quantityOptions = <double>[
      ...baseQuantities,
      if (!draft.isOtherQuantity &&
          draft.selectedQuantity != null &&
          !baseQuantities.contains(draft.selectedQuantity))
        draft.selectedQuantity!,
    ]..sort();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: draft.errorMessage != null
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Item name + expiry badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.shoppingItem.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        draft.category,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildExpiryBadge(theme, draft),
              ],
            ),

            if (draft.errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  draft.errorMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Unit chips
            const Text(
              'Unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unitOptions.map((unit) {
                return _buildOptionChip(
                  context: context,
                  label: unit,
                  isSelected: draft.unit == unit,
                  onTap: () {
                    setState(() {
                      draft.unit = unit;
                      final nextPresets =
                          _unitQuantities[unit] ?? const [1.0, 2.0, 3.0];
                      draft.isOtherQuantity = false;
                      draft.otherController.clear();
                      draft.selectedQuantity = nextPresets.contains(1.0)
                          ? 1.0
                          : nextPresets.first;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Quantity chips
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...quantityOptions.map((qty) {
                  return _buildOptionChip(
                    context: context,
                    label: ShoppingItem.formatQuantityNumber(qty),
                    isSelected:
                        !draft.isOtherQuantity && draft.selectedQuantity == qty,
                    onTap: () {
                      setState(() {
                        draft.isOtherQuantity = false;
                        draft.selectedQuantity = qty;
                      });
                    },
                  );
                }),
                _buildOptionChip(
                  context: context,
                  label: 'Other',
                  isSelected: draft.isOtherQuantity,
                  onTap: () {
                    setState(() {
                      draft.isOtherQuantity = true;
                      if (draft.otherController.text.isEmpty &&
                          draft.selectedQuantity != null) {
                        draft.otherController.text =
                            ShoppingItem.formatQuantityNumber(
                          draft.selectedQuantity!,
                        );
                      }
                    });
                  },
                ),
              ],
            ),

            if (draft.isOtherQuantity) ...[
              const SizedBox(height: 10),
              TextField(
                controller: draft.otherController,
                enabled: !_isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter quantity (${draft.unit})',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Expiry quick chips & date picker
            const Text(
              'Expiry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptionChip(
                  context: context,
                  label: '3 days',
                  isSelected: draft.selectedExpiryChip == '3 days',
                  onTap: () => _applyQuickExpiry(draft, '3 days', 3),
                ),
                _buildOptionChip(
                  context: context,
                  label: '1 week',
                  isSelected: draft.selectedExpiryChip == '1 week',
                  onTap: () => _applyQuickExpiry(draft, '1 week', 7),
                ),
                _buildOptionChip(
                  context: context,
                  label: '2 weeks',
                  isSelected: draft.selectedExpiryChip == '2 weeks',
                  onTap: () => _applyQuickExpiry(draft, '2 weeks', 14),
                ),
                _buildOptionChip(
                  context: context,
                  label: '1 month',
                  isSelected: draft.selectedExpiryChip == '1 month',
                  onTap: () => _applyQuickExpiry(draft, '1 month', 30),
                ),
                _buildOptionChip(
                  context: context,
                  label: '3 months',
                  isSelected: draft.selectedExpiryChip == '3 months',
                  onTap: () => _applyQuickExpiry(draft, '3 months', 90),
                ),
                _buildOptionChip(
                  context: context,
                  label: draft.selectedExpiryChip == 'Pick date' &&
                          draft.expiryDate != null
                      ? _formatDate(draft.expiryDate!)
                      : 'Pick date',
                  isSelected: draft.selectedExpiryChip == 'Pick date',
                  onTap: () => _pickCustomDate(draft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(ThemeData theme, _PantryDraftItem draft) {
    if (draft.expiryDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: const Text(
          'Set expiry',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFC2410C),
          ),
        ),
      );
    }

    final text = draft.isSuggestedExpiry && draft.suggestedDays != null
        ? 'Suggested: ${draft.suggestedDays} days'
        : _formatDate(draft.expiryDate!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : const Color(0xFFD1D5DB),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryDraftItem {
  final ShoppingItem shoppingItem;
  String unit;
  double? selectedQuantity;
  bool isOtherQuantity = false;
  final TextEditingController otherController = TextEditingController();
  final String category;
  DateTime? expiryDate;
  bool isSuggestedExpiry;
  int? suggestedDays;
  String? selectedExpiryChip;
  String? errorMessage;

  _PantryDraftItem({
    required this.shoppingItem,
    required this.unit,
    required double quantity,
    required this.category,
    required this.expiryDate,
    required this.isSuggestedExpiry,
    required this.suggestedDays,
  }) : selectedQuantity = quantity;

  double? get resolvedQuantity {
    if (isOtherQuantity) {
      final parsed = double.tryParse(otherController.text.trim());
      if (parsed == null || parsed <= 0) return null;
      return parsed;
    }
    return selectedQuantity;
  }

  void dispose() {
    otherController.dispose();
  }
}
