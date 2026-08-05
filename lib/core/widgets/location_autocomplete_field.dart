import 'package:flutter/material.dart';

import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// A free-text "Localisation" field styled like [LightTextField] that
/// suggests matching cities (from [options]) as soon as at least 2
/// characters are typed — tapping a suggestion fills the field.
class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    this.label = 'Localisation',
    this.hint = 'Ex : Antananarivo',
    this.icon = Icons.location_on_outlined,
    required this.controller,
    required this.options,
    this.errorText,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> options;

  /// Message affiché sous le champ, en rouge, avec la bordure assortie.
  final String? errorText;

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  static const _errorColor = Color(0xFFE53935);
  static const _minQueryLength = 2;

  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final hint = widget.hint;
    final icon = widget.icon;
    final controller = widget.controller;
    final options = widget.options;
    final errorText = widget.errorText;
    final hasError = errorText != null && errorText.isNotEmpty;

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
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              textEditingController: controller,
              focusNode: _focusNode,
              optionsMaxHeight: 220,
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.length < _minQueryLength) {
                  return const Iterable<String>.empty();
                }
                return options.where((city) => city.toLowerCase().contains(query));
              },
              fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                return AnimatedBuilder(
                  animation: focusNode,
                  builder: (context, _) {
                    final focused = focusNode.hasFocus;
                    return Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError
                              ? _errorColor
                              : (focused ? OnboardingColors.violet : const Color(0xFFE3E3EC)),
                          width: focused || hasError ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: OnboardingColors.violet, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: fieldController,
                              focusNode: focusNode,
                              onSubmitted: (_) => onFieldSubmitted(),
                              style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C26)),
                              cursorColor: OnboardingColors.violet,
                              decoration: InputDecoration(
                                hintText: hint,
                                hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFA6A6B4)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, viewOptions) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: viewOptions.length,
                          itemBuilder: (context, index) {
                            final city = viewOptions.elementAt(index);
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: OnboardingColors.violet,
                                size: 18,
                              ),
                              title: Text(
                                city,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C26)),
                              ),
                              onTap: () => onSelected(city),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(fontSize: 12, color: _errorColor),
          ),
        ],
      ],
    );
  }
}