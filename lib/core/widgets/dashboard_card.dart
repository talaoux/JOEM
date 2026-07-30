import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_shadows.dart';

/// The white, softly-shadowed rounded card used everywhere on the Espace
/// Employeur dashboard (KPI cards, job cards, candidate cards, sidebar
/// cards...). Centralizes the 28px radius + soft shadow so every card
/// stays visually identical.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = AppRadii.dashboardCard,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.dashboardCard,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}