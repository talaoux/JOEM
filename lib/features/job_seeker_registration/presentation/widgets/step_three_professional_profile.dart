import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/widgets/light_text_field.dart';

/// One "compétence" row: a skill name plus a 1-5 star rating.
class SkillEntry {
  SkillEntry() : nameController = TextEditingController();

  final TextEditingController nameController;
  int rating = 0;

  void dispose() => nameController.dispose();
}

/// Étape 3 — "Profil professionnel" : compétences notées sur 5 étoiles
/// et dépôt du CV (PDF).
class StepThreeProfessionalProfile extends StatelessWidget {
  const StepThreeProfessionalProfile({
    super.key,
    required this.skills,
    required this.onAddSkill,
    required this.onRemoveSkill,
    required this.onRatingChanged,
    required this.cvFileName,
    required this.onCvTap,
  });

  final List<SkillEntry> skills;
  final VoidCallback onAddSkill;
  final ValueChanged<int> onRemoveSkill;
  final void Function(int index, int rating) onRatingChanged;

  /// Nom du fichier CV choisi (PDF ou image), `null` si aucun.
  final String? cvFileName;
  final VoidCallback onCvTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profil professionnel',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C26),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Compétences',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A38),
          ),
        ),
        const SizedBox(height: 8),

        for (int i = 0; i < skills.length; i++) ...[
          _SkillRow(
            skill: skills[i],
            onChanged: (rating) => onRatingChanged(i, rating),
            onRemove: skills.length > 1 ? () => onRemoveSkill(i) : null,
          ),
          const SizedBox(height: 12),
        ],

        TextButton.icon(
          onPressed: onAddSkill,
          icon: const Icon(Icons.add_rounded, color: OnboardingColors.violet, size: 20),
          label: const Text(
            'Ajouter une compétence',
            style: TextStyle(color: OnboardingColors.violet, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'CV (PDF ou image)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A38),
          ),
        ),
        const SizedBox(height: 8),
        _CvDropZone(fileName: cvFileName, onTap: onCvTap),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.onChanged,
    required this.onRemove,
  });

  final SkillEntry skill;
  final ValueChanged<int> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LightTextField(
            hint: 'Ex: Maçonnerie, Comptabilité...',
            icon: Icons.star_border_rounded,
            controller: skill.nameController,
          ),
        ),
        const SizedBox(width: 12),
        _StarRating(rating: skill.rating, onChanged: onChanged),
        if (onRemove != null) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9A9AAE), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? AppColors.warning : const Color(0xFFD8D8E2),
              size: 22,
            ),
          ),
        );
      }),
    );
  }
}

class _CvDropZone extends StatelessWidget {
  const _CvDropZone({required this.fileName, required this.onTap});

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: Color(0xFFD8D8E2)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: OnboardingColors.violet,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  selected ? fileName! : 'Choisir votre CV (PDF ou image)',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFA6A6B4)),
                ),
                if (selected) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Toucher pour remplacer',
                    style: TextStyle(fontSize: 11, color: Color(0xFFC2C2CE)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
