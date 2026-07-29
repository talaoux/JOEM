import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_text_styles.dart';

/// Custom horizontal stepper for multi-step registration wizards: one
/// 44px circle per step, linked by a line that fills violet as steps
/// complete. Styled for a white background. This is a bespoke widget —
/// it does NOT use Flutter's built-in [Stepper].
class RegistrationStepper extends StatelessWidget {
  const RegistrationStepper({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  /// 0-based index of the active step.
  final int currentStep;

  /// One label per step, shown under its circle.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        children.add(_StepLine(filled: currentStep > i - 1));
      }
      children.add(_StepNode(index: i, currentStep: currentStep, label: labels[i]));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.currentStep,
    required this.label,
  });

  final int index;
  final int currentStep;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < currentStep;
    final isActive = index == currentStep;
    final isHighlighted = isCompleted || isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: isActive ? 1.08 : 1.0,
          duration: AppDurations.stepTransition,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: AppDurations.stepTransition,
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isHighlighted ? AppColors.primary : const Color(0xFFD8D8E2),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : Text(
                    '${index + 1}',
                    style: AppTextStyles.stepperNumber.copyWith(
                      color: isActive ? Colors.white : const Color(0xFF9A9AAE),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: isActive
              ? AppTextStyles.stepperLabelActive
              : AppTextStyles.stepperLabel.copyWith(color: const Color(0xFF9A9AAE)),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 26, left: 4, right: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 3,
            color: const Color(0xFFE3E3EC),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: filled ? 1 : 0),
              duration: AppDurations.stepTransition,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: Container(color: AppColors.primary),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
