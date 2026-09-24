import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Tuile de chiffre clé du "Tableau de bord" recruteur — gros chiffre en
/// serif (Fraunces) teinté de [accentColor], puis un point de la même
/// couleur + le libellé, et une légende discrète. Pas d'icône : la couleur
/// porte à elle seule le type de donnée (offres, candidatures...). Conçue
/// pour être posée sur un fond teinté (voir [StatCardGroup]).
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final String? caption;

  /// Ouvre l'écran de détail du chiffre (`EmployerDashboard` : "Tableau de
  /// bord"). `null` = carte non cliquable.
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.accentColor,
    this.caption,
    this.onTap,
  });

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final isDark = colors.background.computeLuminance() < 0.2;
    // En mode nuit, les teintes foncées manquent de contraste sur la carte
    // sombre : on les éclaircit plutôt que de définir une 2e palette.
    final accent = isDark
        ? Color.lerp(accentColor, Colors.white, 0.35)!
        : accentColor;
    final isSmall = MediaQuery.of(context).size.width < 360;

    return PressableScale(
      enabled: onTap != null,
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  // Le chiffre défile jusqu'à sa valeur à l'apparition.
                  child: AnimatedCountText(
                    value,
                    style: AppTypography.frauncesBold.copyWith(
                      fontSize: isSmall ? 30 : 36,
                      color: accent,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.interMedium.copyWith(
                              fontSize: isSmall ? 12 : 13,
                              color: colors.textPrimary,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 13),
                        child: Text(
                          caption!,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: isSmall ? 10 : 11,
                            color: colors.textTertiary,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc teinté (violet JOEM très pâle) qui regroupe les [StatCard] — les
/// tuiles blanches ressortent dessus sans ombre, comme dans la maquette
/// `nouveau_design.jpeg`.
class StatCardGroup extends StatelessWidget {
  final Widget child;
  final Color tint;

  const StatCardGroup({super.key, required this.child, required this.tint});

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final isDark = colors.background.computeLuminance() < 0.2;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}
