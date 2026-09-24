import 'package:flutter/material.dart';

import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// A labeled input field styled for a wizard's white card: light grey
/// fill, grey hairline border that turns blue on focus, dark text.
/// Fixed 52px height (single line) so every field in a form lines up.
class LightTextField extends StatefulWidget {
  const LightTextField({
    super.key,
    this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.obscurable = false,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixText,
    this.errorText,
    this.accentColor,
  });

  final String? label;
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscurable;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? suffixText;

  /// Message affiché sous le champ, en rouge, avec la bordure assortie.
  /// `null` (ou vide) laisse le champ dans son état normal.
  final String? errorText;

  /// Couleur d'accent (icône, bordure au focus, curseur) — bleu de
  /// l'onboarding par défaut ; les dashboards passent leur bleu océan.
  final Color? accentColor;

  @override
  State<LightTextField> createState() => _LightTextFieldState();
}

class _LightTextFieldState extends State<LightTextField> {
  bool _obscured = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines > 1;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    const errorColor = Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2A2A38),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: isMultiline ? null : 52,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isMultiline ? 14 : 0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? errorColor
                    : (_focused ? (widget.accentColor ?? OnboardingColors.accent) : const Color(0xFFE3E3EC)),
                width: _focused || hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: isMultiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Padding(
                    padding: EdgeInsets.only(top: isMultiline ? 2 : 0),
                    child: Icon(widget.icon, color: widget.accentColor ?? OnboardingColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    obscureText: widget.obscurable && _obscured,
                    keyboardType: widget.keyboardType,
                    maxLines: isMultiline ? widget.maxLines : 1,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C26)),
                    cursorColor: widget.accentColor ?? OnboardingColors.accent,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFA6A6B4)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.suffixText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.suffixText!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A9AAE),
                    ),
                  ),
                ],
                if (widget.obscurable)
                  GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF9A9AAE),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(fontSize: 12, color: errorColor),
          ),
        ],
      ],
    );
  }
}
