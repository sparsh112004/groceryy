import 'package:flutter/material.dart';

/// Bottom sheet for selecting unit and quantity before adding an item
/// to the shopping list.
class AddShoppingItemSheet extends StatefulWidget {
  final String itemName;
  final String category;
  final String initialUnit;
  final Future<bool> Function(double quantity, String unit, String category)
      onConfirm;

  const AddShoppingItemSheet({
    super.key,
    required this.itemName,
    required this.category,
    required this.initialUnit,
    required this.onConfirm,
  });

  /// Displays the modal bottom sheet and returns `true` if the item was added.
  static Future<bool?> show(
    BuildContext context, {
    required String itemName,
    required String category,
    required String initialUnit,
    required Future<bool> Function(double quantity, String unit, String category)
        onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddShoppingItemSheet(
        itemName: itemName,
        category: category,
        initialUnit: initialUnit,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AddShoppingItemSheet> createState() => _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends State<AddShoppingItemSheet> {
  static const List<String> _units = [
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

  late String _selectedUnit;
  double? _selectedQuantity;
  bool _isOtherSelected = false;
  bool _isSubmitting = false;
  final TextEditingController _otherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedUnit =
        _units.contains(widget.initialUnit) ? widget.initialUnit : 'pcs';
    _selectDefaultQuantityForUnit(_selectedUnit);
    _otherController.addListener(() {
      if (_isOtherSelected) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _selectDefaultQuantityForUnit(String unit) {
    final options = _unitQuantities[unit] ?? const [1.0];
    _isOtherSelected = false;
    _otherController.clear();
    _selectedQuantity = options.contains(1.0) ? 1.0 : options.first;
  }

  double? get _resolvedQuantity {
    if (_isOtherSelected) {
      final parsed = double.tryParse(_otherController.text.trim());
      if (parsed == null || parsed <= 0) return null;
      return parsed;
    }
    return _selectedQuantity;
  }

  String _formatChipNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Future<void> _submit() async {
    final qty = _resolvedQuantity;
    if (qty == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final success = await widget.onConfirm(qty, _selectedUnit, widget.category);
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    final quantities = _unitQuantities[_selectedUnit] ?? const [1.0];
    final canSubmit = _resolvedQuantity != null && !_isSubmitting;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to shopping list',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.itemName} • ${widget.category}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 24),
                      tooltip: 'Close',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unit selection
              const Text(
                'Unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _units.map((unit) {
                  return _buildChip(
                    label: unit,
                    isSelected: _selectedUnit == unit,
                    onTap: () {
                      setState(() {
                        _selectedUnit = unit;
                        _selectDefaultQuantityForUnit(unit);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Quantity selection
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...quantities.map((qty) {
                    return _buildChip(
                      label: _formatChipNumber(qty),
                      isSelected: !_isOtherSelected && _selectedQuantity == qty,
                      onTap: () {
                        setState(() {
                          _isOtherSelected = false;
                          _selectedQuantity = qty;
                        });
                      },
                    );
                  }),
                  _buildChip(
                    label: 'Other',
                    isSelected: _isOtherSelected,
                    onTap: () {
                      setState(() {
                        _isOtherSelected = true;
                      });
                    },
                  ),
                ],
              ),

              if (_isOtherSelected) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otherController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Enter quantity ($_selectedUnit)',
                    labelStyle: const TextStyle(fontSize: 16),
                    hintText: 'e.g. 1.5',
                    hintStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Primary button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add to shopping list',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
