import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

enum GlassButtonVariant { filled, outline }

/// The two navigation buttons ("Retour" / "Suivant" / "Créer mon compte")
/// used across the registration wizard: a violet filled pill with a glow,
/// or a transparent outline pill with a violet-tinted hairline border
/// (kept subtle enough to read on both light and dark surfaces).
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = GlassButtonVariant.filled,
    this.leadingIcon,
    this.trailingIcon,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final GlassButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  /// Overrides the default [AppColors.primary] tint, e.g. to match a
  /// specific screen's palette (login follows the onboarding violet).
  final Color? color;

  bool get _isFilled => variant == GlassButtonVariant.filled;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    final foreground = _isFilled ? Colors.white : (color ?? AppColors.primaryLight);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _isFilled ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: _isFilled
            ? null
            : Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: _isFilled ? AppShadows.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: foreground, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.buttonLabel.copyWith(color: foreground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: foreground, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
