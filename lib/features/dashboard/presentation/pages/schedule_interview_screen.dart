import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';

/// Planification (ou re-planification) d'un entretien avec un candidat qui
/// a postulé — ouvert depuis `CandidateApplicationDetailScreen`. Persiste
/// dans `interviews` via `InterviewRepository` et renvoie l'[Interview]
/// créé/mis à jour au `pop`.
class ScheduleInterviewScreen extends StatefulWidget {
  const ScheduleInterviewScreen({
    super.key,
    required this.notification,
    this.existing,
  });

  final JobApplicationNotification notification;

  /// Entretien déjà planifié pour cette candidature, s'il y en a un — le
  /// formulaire est alors pré-rempli et l'enregistrement met à jour la
  /// ligne existante au lieu d'en créer une nouvelle.
  final Interview? existing;

  @override
  State<ScheduleInterviewScreen> createState() => _ScheduleInterviewScreenState();
}

class _ScheduleInterviewScreenState extends State<ScheduleInterviewScreen> {
  final InterviewRepository _repository = const InterviewRepository();
  final AuthService _authService = AuthService();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  String _mode = InterviewMode.presentiel;
  bool _saving = false;
  String? _dateError;
  String? _timeError;

  JobApplicationNotification get _notification => widget.notification;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _date = existing.date;
      final parts = existing.time.split(':');
      _time = TimeOfDay(
        hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      );
      _mode = existing.mode;
      _locationController.text = existing.location ?? '';
      _notesController.text = existing.notes ?? '';
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _candidateName {
    final stored = _notification.candidateName.trim();
    return stored.isNotEmpty ? stored : 'Candidat';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _timeError = null;
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() {
      _dateError = _date == null ? 'Choisissez une date' : null;
      _timeError = _time == null ? 'Choisissez une heure' : null;
    });
    if (_date == null || _time == null || _saving) return;

    final employerUserId = int.tryParse(_authService.currentUser?.id ?? '');
    if (employerUserId == null) return;

    setState(() => _saving = true);
    final time = _formatTime(_time!);

    Interview result;
    if (widget.existing != null) {
      await _repository.update(
        id: widget.existing!.id,
        date: _date!,
        time: time,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        mode: _mode,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      result = Interview(
        id: widget.existing!.id,
        employerUserId: employerUserId,
        jobApplicationId: _notification.applicationId,
        jobOfferId: _notification.offer.id,
        jobSeekerUserId: _notification.jobSeekerUserId,
        candidateName: _candidateName,
        offerTitle: _notification.offer.title,
        date: DateTime(_date!.year, _date!.month, _date!.day),
        time: time,
        location: _locationController.text.trim(),
        mode: _mode,
        notes: _notesController.text.trim(),
        status: InterviewStatus.scheduled,
        createdAt: widget.existing!.createdAt,
      );
    } else {
      result = await _repository.schedule(
        employerUserId: employerUserId,
        jobApplicationId: _notification.applicationId,
        jobOfferId: _notification.offer.id,
        jobSeekerUserId: _notification.jobSeekerUserId,
        candidateName: _candidateName,
        offerTitle: _notification.offer.title,
        date: _date!,
        time: time,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        mode: _mode,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existing != null
              ? 'Entretien mis à jour.'
              : 'Entretien planifié avec $_candidateName.',
        ),
      ),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isVisio = _mode == InterviewMode.visio;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.existing != null ? 'Modifier l\'entretien' : 'Planifier un entretien',
          style: AppTypography.sectionTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: OnboardingColors.lavender.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: OnboardingColors.violet),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_candidateName, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                        Text(
                          'Pour "${_notification.offer.title}"',
                          style: AppTypography.cardDescription.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPickerField(
              label: 'Date',
              value: _date != null ? _formatDate(_date!) : 'Choisir une date',
              icon: Icons.calendar_today_rounded,
              isPlaceholder: _date == null,
              error: _dateError,
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPickerField(
              label: 'Heure',
              value: _time != null ? _formatTime(_time!) : 'Choisir une heure',
              icon: Icons.access_time_rounded,
              isPlaceholder: _time == null,
              error: _timeError,
              onTap: _pickTime,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mode', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildModeChip(
                  label: 'Présentiel',
                  icon: Icons.location_on_outlined,
                  selected: !isVisio,
                  onTap: () => setState(() => _mode = InterviewMode.presentiel),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildModeChip(
                  label: 'Visio',
                  icon: Icons.videocam_outlined,
                  selected: isVisio,
                  onTap: () => setState(() => _mode = InterviewMode.visio),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _locationController,
              label: isVisio ? 'Lien ou plateforme' : 'Adresse / lieu',
              hint: isVisio ? 'https://meet... ou "Google Meet"' : 'Bureau, salle, adresse...',
              icon: isVisio ? Icons.link_rounded : Icons.map_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _notesController,
              label: 'Notes (facultatif)',
              hint: 'Points à aborder, documents à apporter...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OnboardingColors.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.existing != null ? 'Enregistrer' : 'Planifier l\'entretien',
                        style: AppTypography.primaryButton.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required bool isPlaceholder,
    required String? error,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? AppColors.error : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: OnboardingColors.violet),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: isPlaceholder ? const Color(0xFF9CA3AF) : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error, style: TextStyle(color: AppColors.error, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? OnboardingColors.violet.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? OnboardingColors.violet : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? OnboardingColors.violet : const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? OnboardingColors.violet : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.interRegular.copyWith(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon: maxLines == 1 ? Icon(icon, size: 18, color: OnboardingColors.violet) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OnboardingColors.violet),
            ),
          ),
        ),
      ],
    );
  }
}
