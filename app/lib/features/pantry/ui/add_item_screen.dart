import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/grocery_catalog.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';

/// Screen for adding a new pantry item or editing an existing one.
/// Supports catalog name suggestions, quick/suggested expiry selection,
/// and collapsible optional details (unit, quantity, category, location).
class AddItemScreen extends StatefulWidget {
  final ItemModel? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  static const List<String> _units = [
    'pcs',
    'kg',
    'g',
    'L',
    'ml',
    'packet',
    'dozen',
  ];

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _locationController;

  DateTime? _selectedExpiryDate;
  String? _selectedQuickChip;
  int? _suggestedShelfLifeDays;
  String? _lastAppliedSuggestionName;

  String? _selectedUnit;
  String? _selectedQuantityChip;
  bool _isCustomQuantity = false;

  String? _selectedCategory;
  bool _categoryManuallyChosen = false;

  bool _isMoreDetailsExpanded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    final initialQtyText = item?.quantity != null
        ? (item!.quantity! % 1 == 0
            ? item.quantity!.toInt().toString()
            : item.quantity!.toString())
        : '';
    _quantityController = TextEditingController(text: initialQtyText);
    _locationController = TextEditingController(text: item?.location ?? '');

    if (item != null) {
      _selectedExpiryDate = item.expiryDate;
      if (item.unit != null && item.unit!.trim().isNotEmpty) {
        _selectedUnit = item.unit!.trim();
      }
      if (initialQtyText.isNotEmpty) {
        final options = _quantityOptionsForUnit(_selectedUnit);
        if (options.contains(initialQtyText)) {
          _selectedQuantityChip = initialQtyText;
        } else {
          _selectedQuantityChip = 'Other';
          _isCustomQuantity = true;
        }
      }
      if (item.category != null && item.category!.trim().isNotEmpty) {
        _selectedCategory = item.category!.trim();
        _categoryManuallyChosen = true;
      }
      _isMoreDetailsExpanded = item.quantity != null ||
          (item.unit != null && item.unit!.isNotEmpty) ||
          (item.category != null && item.category!.isNotEmpty) ||
          (item.location != null && item.location!.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<String> _quantityOptionsForUnit(String? unit) {
    switch (unit) {
      case 'kg':
        return const ['0.5', '1', '2', '5'];
      case 'g':
        return const ['100', '250', '500'];
      case 'L':
        return const ['0.5', '1', '2'];
      case 'ml':
        return const ['250', '500', '1000'];
      case 'pcs':
      case 'packet':
      case 'dozen':
      default:
        return const ['1', '2', '3', '4', '6', '12'];
    }
  }

  void _onNameChanged(String value) {
    setState(() {
      if (_lastAppliedSuggestionName != null &&
          value.trim().toLowerCase() !=
              _lastAppliedSuggestionName!.toLowerCase()) {
        _lastAppliedSuggestionName = null;
        if (!_categoryManuallyChosen) {
          _selectedCategory = null;
        }
      }
    });
  }

  void _applyCatalogSuggestion(CatalogItem item) {
    setState(() {
      _nameController.text = item.name;
      _nameController.selection = TextSelection.collapsed(
        offset: item.name.length,
      );
      _lastAppliedSuggestionName = item.name;

      // Pre-select unit and keep quantity consistent with new unit.
      _selectUnitInternal(item.defaultUnit);

      // Pre-select category unless the user already chose one manually.
      if (!_categoryManuallyChosen) {
        _selectedCategory = item.category;
      }

      // Pre-select suggested expiry (today + shelfLifeDays).
      _selectedExpiryDate = suggestedExpiry(item, DateTime.now());
      _suggestedShelfLifeDays = item.shelfLifeDays;
      _selectedQuickChip = null;
    });
  }

  void _selectUnitInternal(String unit) {
    _selectedUnit = unit;
    if (!_isCustomQuantity && _selectedQuantityChip != null) {
      final validOptions = _quantityOptionsForUnit(unit);
      if (!validOptions.contains(_selectedQuantityChip)) {
        _selectedQuantityChip = null;
        _quantityController.clear();
      }
    }
  }

  void _onUnitChipTapped(String unit) {
    setState(() {
      if (_selectedUnit == unit) {
        _selectedUnit = null;
      } else {
        _selectUnitInternal(unit);
      }
    });
  }

  void _onQuantityChipTapped(String value) {
    setState(() {
      if (value == 'Other') {
        if (_selectedQuantityChip == 'Other') {
          _selectedQuantityChip = null;
          _isCustomQuantity = false;
          _quantityController.clear();
        } else {
          _selectedQuantityChip = 'Other';
          _isCustomQuantity = true;
          if (_quantityOptionsForUnit(_selectedUnit)
              .contains(_quantityController.text.trim())) {
            _quantityController.clear();
          }
        }
      } else {
        if (_selectedQuantityChip == value) {
          _selectedQuantityChip = null;
          _isCustomQuantity = false;
          _quantityController.clear();
        } else {
          _selectedQuantityChip = value;
          _isCustomQuantity = false;
          _quantityController.text = value;
        }
      }
    });
  }

  void _onCategoryChipTapped(String category) {
    setState(() {
      if (_categoryManuallyChosen && _selectedCategory == category) {
        _selectedCategory = null;
        _categoryManuallyChosen = false;
      } else {
        _selectedCategory = category;
        _categoryManuallyChosen = true;
      }
    });
  }

  void _applyQuickChip(String label, int days) {
    setState(() {
      _selectedQuickChip = label;
      _suggestedShelfLifeDays = null;
      _selectedExpiryDate = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _selectedQuickChip = 'Pick date';
        _suggestedShelfLifeDays = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get _canSave {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final expiryValid = _selectedExpiryDate != null;
    return nameValid && expiryValid && !_isSubmitting;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final expiry = _selectedExpiryDate!;
    final qty = double.tryParse(_quantityController.text.trim());
    final unit = _selectedUnit?.trim() ?? '';
    final category = _categoryManuallyChosen
        ? (_selectedCategory ?? categoryFor(name))
        : (_selectedCategory ?? categoryFor(name));
    final location = _locationController.text.trim();

    try {
      final itemsProvider = context.read<ItemsProvider>();

      if (widget.itemToEdit == null) {
        await itemsProvider.addItem(
          name: name,
          expiryDate: expiry,
          quantity: qty,
          unit: unit.isNotEmpty ? unit : null,
          category: category.isNotEmpty ? category : null,
          location: location.isNotEmpty ? location : null,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name added'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await itemsProvider.updateItem(
          widget.itemToEdit!.id,
          name: name,
          expiryDate: expiry,
          quantity: qty,
          unit: unit,
          category: category,
          location: location,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name updated'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  Widget _buildChip(String label, VoidCallback onTap, bool isSelected) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : const Color(0xFFF9FAFB),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.itemToEdit != null;

    final nameQuery = _nameController.text.trim();
    final showSuggestions = nameQuery.isNotEmpty &&
        (_lastAppliedSuggestionName == null ||
            nameQuery.toLowerCase() !=
                _lastAppliedSuggestionName!.toLowerCase());
    final suggestions = showSuggestions
        ? searchCatalog(nameQuery, limit: 5)
        : const <CatalogItem>[];

    final quantityOptions = _quantityOptionsForUnit(_selectedUnit);
    final autoCategory = nameQuery.isNotEmpty ? categoryFor(nameQuery) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit item' : 'Add item'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Item Name Label & Field
                Text(
                  'Item name',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  textInputAction: TextInputAction.next,
                  onChanged: _onNameChanged,
                  style: const TextStyle(fontSize: 17),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Milk',
                    hintStyle: TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: suggestions
                        .map(
                          (item) => _buildChip(
                            item.name,
                            () => _applyCatalogSuggestion(item),
                            false,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // Expires in Section
                Text(
                  'Expires in',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChip(
                      '1 week',
                      () => _applyQuickChip('1 week', 7),
                      _selectedQuickChip == '1 week',
                    ),
                    _buildChip(
                      '2 weeks',
                      () => _applyQuickChip('2 weeks', 14),
                      _selectedQuickChip == '2 weeks',
                    ),
                    _buildChip(
                      '1 month',
                      () => _applyQuickChip('1 month', 30),
                      _selectedQuickChip == '1 month',
                    ),
                    _buildChip(
                      '3 months',
                      () => _applyQuickChip('3 months', 90),
                      _selectedQuickChip == '3 months',
                    ),
                    _buildChip(
                      _selectedQuickChip == 'Pick date' &&
                              _selectedExpiryDate != null
                          ? _formatDate(_selectedExpiryDate!)
                          : 'Pick date',
                      _pickCustomDate,
                      _selectedQuickChip == 'Pick date',
                    ),
                  ],
                ),
                if (_suggestedShelfLifeDays != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Suggested: $_suggestedShelfLifeDays days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                if (_selectedExpiryDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Selected expiry: ${_formatDate(_selectedExpiryDate!)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Collapsible 'More details (optional)' Section
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isMoreDetailsExpanded = !_isMoreDetailsExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'More details (optional)',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unit · Quantity · Category · Where stored',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _isMoreDetailsExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: const Color(0xFF4B5563),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_isMoreDetailsExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Unit (first)
                              const Text(
                                'Unit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _units
                                    .map(
                                      (unit) => _buildChip(
                                        unit,
                                        () => _onUnitChipTapped(unit),
                                        _selectedUnit == unit,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 20),

                              // Quantity (depends on unit)
                              const Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  ...quantityOptions.map(
                                    (qty) => _buildChip(
                                      qty,
                                      () => _onQuantityChipTapped(qty),
                                      _selectedQuantityChip == qty,
                                    ),
                                  ),
                                  _buildChip(
                                    'Other',
                                    () => _onQuantityChipTapped('Other'),
                                    _selectedQuantityChip == 'Other',
                                  ),
                                ],
                              ),
                              if (_isCustomQuantity) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                  decoration: const InputDecoration(
                                    labelText: 'Custom quantity',
                                    labelStyle: TextStyle(fontSize: 16),
                                    hintText: 'e.g. 1.5',
                                    hintStyle: TextStyle(fontSize: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),

                              // Category
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: kCategories
                                    .map(
                                      (category) => _buildChip(
                                        category,
                                        () => _onCategoryChipTapped(category),
                                        _selectedCategory == category,
                                      ),
                                    )
                                    .toList(),
                              ),
                              if (!_categoryManuallyChosen &&
                                  autoCategory != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Auto: $autoCategory',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),

                              // Where Stored / Location
                              TextFormField(
                                controller: _locationController,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Where stored',
                                  labelStyle: TextStyle(fontSize: 16),
                                  hintText: 'e.g. Fridge, Freezer, Pantry',
                                  hintStyle: TextStyle(fontSize: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
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
                const SizedBox(height: 32),

                // Save Item Button (Disabled until name & expiry date are filled)
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update item' : 'Save item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
