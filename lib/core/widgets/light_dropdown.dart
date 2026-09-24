import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';

/// A tap-to-select field styled like [LightTextField] but opening a
/// bottom sheet with the option list — used for "Localisation".
class LightDropdown extends StatelessWidget {
  const LightDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  /// Couleur d'accent (icône, option choisie) — mauve `AppColors.primary`
  /// par défaut ; les dashboards passent leur bleu océan.
  final Color? accentColor;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3EC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C26),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == value;
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? (accentColor ?? AppColors.primary) : const Color(0xFF1C1C26),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: accentColor ?? AppColors.primary)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A38),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E3EC), width: 1),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accentColor ?? AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 15,
                      color: value == null ? const Color(0xFFA6A6B4) : const Color(0xFF1C1C26),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9A9AAE),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
