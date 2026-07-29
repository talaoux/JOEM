import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Carte de sélection de rôle avec glassmorphism
/// Design premium avec effets visuels avancés
class RoleSelectionCardWidget extends StatefulWidget {
  final IconData leftIcon;
  final String title;
  final String description;
  final IconData rightIcon;
  final VoidCallback onTap;
  final Animation<double> animation;
  final int delayIndex;

  const RoleSelectionCardWidget({
    super.key,
    required this.leftIcon,
    required this.title,
    required this.description,
    required this.rightIcon,
    required this.onTap,
    required this.animation,
    this.delayIndex = 0,
  });

  @override
  State<RoleSelectionCardWidget> createState() =>
      _RoleSelectionCardWidgetState();
}

class _RoleSelectionCardWidgetState extends State<RoleSelectionCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tapAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _tapController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _tapController.reverse();
  }

  void _handleTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        // Animation d'entrée décalée pour chaque carte
        final delayedAnimation = CurvedAnimation(
          parent: widget.animation,
          curve: Interval(
            widget.delayIndex * 0.2,
            0.6 + widget.delayIndex * 0.2,
            curve: Curves.easeOutCubic,
          ),
        );

        final slideValue = delayedAnimation.drive(
          Tween<double>(begin: 50, end: 0),
        );

        final fadeValue = delayedAnimation.drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );

        return FadeTransition(
          opacity: fadeValue,
          child: Transform.translate(
            offset: Offset(0, slideValue.value),
            child: ScaleTransition(
              scale: _tapAnimation,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            // Glassmorphism effect
            color: const Color(0x26FFFFFF), // rgba(255,255,255,0.16)
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x40FFFFFF), // rgba(255,255,255,0.25)
              width: 1,
            ),
            // Shadow noire légère
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // BackdropFilter pour l'effet de flou
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Icône gauche - plate, sans fond
                    Icon(
                      widget.leftIcon,
                      color: AppColors.primaryLight,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    // Texte
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.description,
                            style: AppTextStyles.cardDescription.copyWith(fontSize: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Icône droite - chevron simple
                    Icon(
                      widget.rightIcon,
                      color: AppColors.primaryLight,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}