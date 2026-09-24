import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

enum GlassButtonVariant { filled, outline }

/// The two navigation buttons ("Retour" / "Suivant" / "Créer mon compte")
/// used across the registration wizard: a pale-tinted pill with dark accent
/// text ("filled"), or a white pill with a grey hairline border ("outline")
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
  /// specific screen's palette (login follows the onboarding ocean blue).
  final Color? color;

  bool get _isFilled => variant == GlassButtonVariant.filled;

  @override
  Widget build(BuildContext context) {
    // "Nouveau design" : plus de pilule pleine lumineuse — la variante
    // pleine devient une pilule à teinte pâle + texte foncé de la couleur
    // d'accent (comme le bouton "Envoyer" de la maquette), la variante
    // contour une pilule blanche à fine bordure grise.
    final accent = color ?? AppColors.primary;
    final ink = Color.lerp(accent, Colors.black, 0.28)!;
    final isDisabled = onTap == null;
    final foreground = isDisabled
        ? const Color(0xFF94A3B8)
        : (_isFilled ? ink : accent);
    final background = isDisabled
        ? const Color(0xFFE9EDF3)
        : (_isFilled ? accent.withValues(alpha: 0.12) : Colors.white);

    return PressableScale(enabled: !isDisabled, child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: _isFilled || isDisabled
            ? null
            : Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
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
                    style: AppTypography.buttonLabel.copyWith(color: foreground),
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
    ));
  }
}
