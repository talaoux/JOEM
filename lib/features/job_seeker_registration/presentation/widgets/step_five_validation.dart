import 'package:flutter/material.dart';

import 'package:joem/features/welcome/presentation/welcome_palette.dart';

import 'step_four_daily_rate.dart';
import 'step_three_professional_profile.dart';

/// Étape 5 — "Validation" : relecture des informations saisies aux
/// étapes précédentes avant la création du compte.
class StepFiveValidation extends StatelessWidget {
  const StepFiveValidation({
    super.key,
    required this.email,
    required this.photoPicked,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.localisation,
    required this.titreProfessionnel,
    required this.presentation,
    required this.skills,
    required this.cvPicked,
    required this.rate,
    required this.availability,
    required this.workModes,
  });

  final String email;
  final bool photoPicked;
  final String nom;
  final String prenom;
  final String telephone;
  final String localisation;
  final String titreProfessionnel;
  final String presentation;
  final List<SkillEntry> skills;
  final bool cvPicked;
  final String rate;
  final String? availability;
  final Set<WorkMode> workModes;

  String _orPlaceholder(String value) => value.trim().isEmpty ? 'Non renseigné' : value;

  @override
  Widget build(BuildContext context) {
    final namedSkills = skills.where((s) => s.nameController.text.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vérifiez vos informations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C26),
          ),
        ),
        const SizedBox(height: 20),

        _SummarySection(
          title: 'Compte',
          rows: [
            _SummaryRow(icon: Icons.mail_outline_rounded, label: 'Email', value: _orPlaceholder(email)),
          ],
        ),
        const SizedBox(height: 16),

        _SummarySection(
          title: 'Informations personnelles',
          rows: [
            _SummaryRow(
              icon: Icons.person_outline_rounded,
              label: 'Photo de profil',
              value: photoPicked ? 'Ajoutée' : 'Non ajoutée',
            ),
            _SummaryRow(icon: Icons.person_outline_rounded, label: 'Nom', value: _orPlaceholder(nom)),
            _SummaryRow(icon: Icons.person_outline_rounded, label: 'Prénom', value: _orPlaceholder(prenom)),
            _SummaryRow(icon: Icons.call_rounded, label: 'Téléphone', value: _orPlaceholder(telephone)),
            _SummaryRow(
              icon: Icons.location_on_outlined,
              label: 'Localisation',
              value: _orPlaceholder(localisation),
            ),
            _SummaryRow(
              icon: Icons.badge_outlined,
              label: 'Titre professionnel',
              value: _orPlaceholder(titreProfessionnel),
            ),
            _SummaryRow(icon: Icons.notes_rounded, label: 'Présentation', value: _orPlaceholder(presentation)),
          ],
        ),
        const SizedBox(height: 16),

        _SummarySection(
          title: 'Profil professionnel',
          rows: [
            _SummaryRow(
              icon: Icons.star_border_rounded,
              label: 'Compétences',
              value: namedSkills.isEmpty
                  ? 'Non renseigné'
                  : namedSkills
                      .map((s) => '${s.nameController.text.trim()} (${s.rating}/5)')
                      .join(', '),
            ),
            _SummaryRow(
              icon: Icons.picture_as_pdf_outlined,
              label: 'CV',
              value: cvPicked ? 'Ajouté' : 'Non ajouté',
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SummarySection(
          title: 'Tarif journalier',
          rows: [
            _SummaryRow(
              icon: Icons.payments_outlined,
              label: 'Tarif souhaité',
              value: rate.trim().isEmpty ? 'Non renseigné' : '${rate.trim()} Ar',
            ),
            _SummaryRow(
              icon: Icons.event_available_outlined,
              label: 'Disponibilité',
              value: availability ?? 'Non renseigné',
            ),
            _SummaryRow(
              icon: Icons.work_outline_rounded,
              label: 'Mode de travail',
              value: workModes.isEmpty
                  ? 'Non renseigné'
                  : workModes.map((m) => m.label).join(', '),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.rows});

  final String title;
  final List<_SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E3EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A9AAE),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: OnboardingColors.violet, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFFA6A6B4)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1C26),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
