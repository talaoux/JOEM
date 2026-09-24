import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surface_colors.dart';

/// Fait balayer un reflet lumineux sur [child] en boucle — l'effet
/// "shimmer" classique des états de chargement, posé une seule fois autour
/// d'un groupe de [SkeletonBox] (une seule animation pour tout le groupe,
/// le reflet traverse alors toute la carte/liste plutôt que chaque bloc
/// séparément).
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (2 * _controller.value - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0x00FFFFFF),
                Color(0x80FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds.shift(Offset(dx, 0)));
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bloc de squelette (rectangle gris arrondi) — brique de base des
/// placeholders de chargement, à assembler à la main pour imiter la forme
/// d'une vraie carte (voir [JobOfferCardSkeleton]/[EmployerOfferCardSkeleton]).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.divider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Squelette animé d'une liste de cartes — enveloppe [count] cartes
/// [cardBuilder] dans un seul [ShimmerLoading] partagé, espacées de
/// [spacing]. Utilisé pendant le chargement des offres/candidatures/
/// entretiens, à la place d'un simple `CircularProgressIndicator` centré.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    required this.count,
    required this.cardBuilder,
    this.spacing = AppSpacing.md,
  });

  final int count;
  final Widget Function(BuildContext context, int index) cardBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            cardBuilder(context, i),
          ],
        ],
      ),
    );
  }
}

/// Placeholder de chargement à la forme de `JobOfferPostCard` (fil "offres
/// recommandées" du candidat, `CategoryOffersScreen`...).
class JobOfferCardSkeleton extends StatelessWidget {
  const JobOfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 44, height: 44, radius: 12),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 130, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(width: 190, height: 16),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          const SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          const SkeletonBox(width: 220, height: 12),
          const SizedBox(height: AppSpacing.lg),
          SkeletonBox(width: double.infinity, height: 44, radius: 14),
        ],
      ),
    );
  }
}

/// Placeholder de chargement à la forme de `EmployerOfferCard` (liste "Mes
/// offres d'emploi" du dashboard recruteur, `EmployerOffersScreen`...).
class EmployerOfferCardSkeleton extends StatelessWidget {
  const EmployerOfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 52, height: 52, radius: 15),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 150, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 10),
                SizedBox(height: 10),
                SkeletonBox(width: 100, height: 18, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder de chargement compact (avatar + 2 lignes) — candidats
/// suggérés, résultats de recherche, entretiens du jour...
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key, this.avatarRadius = 22});

  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          SkeletonBox(width: avatarRadius * 2, height: avatarRadius * 2, radius: avatarRadius),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
