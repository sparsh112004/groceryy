import 'package:flutter/material.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';

/// Modal bottom sheet for confirming a bought shopping item and assigning its expiry date.
/// Follows Wireframe 4:
/// - Title: "{item.name} bought. Add to pantry?"
/// - Expires in quick chips: 1 month, 3 months, 6 months, Pick date
/// - Primary button: "Add to pantry" (disabled until an expiry date is selected)
/// - Cancel option: Leaves item unticked
class BoughtBottomSheet extends StatefulWidget {
  final ShoppingItem item;
  final Future<MarkBoughtResult> Function(DateTime expiryDate) onConfirm;

  const BoughtBottomSheet({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  /// Helper to display this modal bottom sheet.
  static Future<MarkBoughtResult?> show(
    BuildContext context, {
    required ShoppingItem item,
    required Future<MarkBoughtResult> Function(DateTime expiryDate) onConfirm,
  }) {
    return showModalBottomSheet<MarkBoughtResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BoughtBottomSheet(
        item: item,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<BoughtBottomSheet> createState() => _BoughtBottomSheetState();
}

class _BoughtBottomSheetState extends State<BoughtBottomSheet> {
  DateTime? _selectedExpiryDate;
  String? _selectedChip;
  bool _isSubmitting = false;

  void _applyQuickChip(String label, int days) {
    setState(() {
      _selectedChip = label;
      _selectedExpiryDate = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initial = _selectedExpiryDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _selectedChip = 'Pick date';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_selectedExpiryDate == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final result = await widget.onConfirm(_selectedExpiryDate!);

    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Widget _buildChip(String label, VoidCallback onTap, bool isSelected) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 80),
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
        alignment: Alignment.center,
        child: Text(
          label,
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
    final canSave = _selectedExpiryDate != null && !_isSubmitting;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with title and close button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${widget.item.name} bought. Add to pantry?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  tooltip: 'Cancel',
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expires in label
            Text(
              'Expires in',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Chips: 1 month, 3 months, 6 months, Pick date
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildChip(
                  '1 month',
                  () => _applyQuickChip('1 month', 30),
                  _selectedChip == '1 month',
                ),
                _buildChip(
                  '3 months',
                  () => _applyQuickChip('3 months', 90),
                  _selectedChip == '3 months',
                ),
                _buildChip(
                  '6 months',
                  () => _applyQuickChip('6 months', 180),
                  _selectedChip == '6 months',
                ),
                _buildChip(
                  _selectedChip == 'Pick date' && _selectedExpiryDate != null
                      ? _formatDate(_selectedExpiryDate!)
                      : 'Pick date',
                  _pickCustomDate,
                  _selectedChip == 'Pick date',
                ),
              ],
            ),

            if (_selectedExpiryDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Expiry date: ${_formatDate(_selectedExpiryDate!)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Add to pantry primary button (at least 48dp)
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: canSave ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSave
                      ? theme.colorScheme.primary
                      : const Color(0xFFE5E7EB),
                  foregroundColor: canSave
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
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
                        'Add to pantry',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel button
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
