import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';

/// Screen for adding a new pantry item or editing an existing one.
/// Follows Wireframe 1:
/// - Item name (required)
/// - Expires in section with quick chips: 1 week, 2 weeks, 1 month, 3 months, Pick date
/// - Collapsible 'More details (optional)' section (Quantity, Category, Where stored)
/// - Save item button (disabled until name & expiry set)
class AddItemScreen extends StatefulWidget {
  final ItemModel? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _categoryController;
  late TextEditingController _locationController;

  DateTime? _selectedExpiryDate;
  String? _selectedQuickChip;
  bool _isMoreDetailsExpanded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity != null
          ? (item!.quantity! % 1 == 0
              ? item.quantity!.toInt().toString()
              : item.quantity!.toString())
          : '',
    );
    _unitController = TextEditingController(text: item?.unit ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');

    if (item != null) {
      _selectedExpiryDate = item.expiryDate;
      _isMoreDetailsExpanded = item.quantity != null ||
          (item.category != null && item.category!.isNotEmpty) ||
          (item.location != null && item.location!.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _applyQuickChip(String label, int days) {
    setState(() {
      _selectedQuickChip = label;
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
    final unit = _unitController.text.trim();
    final category = _categoryController.text.trim();
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.itemToEdit != null;

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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 17),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Milk',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Expires in Section
                Text(
                  'Expires in',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Chips (Wireframe 1)
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
                      _selectedQuickChip == 'Pick date' && _selectedExpiryDate != null
                          ? _formatDate(_selectedExpiryDate!)
                          : 'Pick date',
                      _pickCustomDate,
                      _selectedQuickChip == 'Pick date',
                    ),
                  ],
                ),
                if (_selectedExpiryDate != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Selected expiry: ${_formatDate(_selectedExpiryDate!)}',
                    style: TextStyle(
                      fontSize: 15,
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      'Quantity · Category · Where stored',
                                      style: TextStyle(
                                        fontSize: 15,
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
                      if (_isMoreDetailsExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Quantity & Unit
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _quantityController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        hintText: 'e.g. 1',
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _unitController,
                                      style: const TextStyle(fontSize: 16),
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        hintText: 'e.g. L, kg, pcs',
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Category
                              TextFormField(
                                controller: _categoryController,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  hintText: 'e.g. Dairy, Produce, Bakery',
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
                              const SizedBox(height: 16),

                              // Where Stored / Location
                              TextFormField(
                                controller: _locationController,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Where stored',
                                  hintText: 'e.g. Fridge, Freezer, Pantry',
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
