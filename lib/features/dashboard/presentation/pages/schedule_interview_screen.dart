import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Planification (ou re-planification) d'un entretien avec un candidat qui
/// a postulé — ouvert depuis `CandidateApplicationDetailScreen`. Persiste
/// dans `interviews` via `InterviewRepository` et renvoie l'[Interview]
/// créé/mis à jour au `pop`.
///
/// La date et l'heure peuvent rester "à définir" (interrupteur) : le
/// candidat voit alors "Date à définir", et sera notifié ("Entretien
/// modifié") quand le recruteur la fixera en re-planifiant.
///
/// Avec [acceptApplication], l'écran sert à accepter la candidature :
/// accepter oblige à planifier un entretien (au moins "à définir"), pour
/// que le candidat accepté sache quelle est la suite. L'enregistrement crée
/// l'entretien PUIS accepte la candidature (`JobOfferRepository.acceptApplication`,
/// avec le message facultatif saisi ici).
class ScheduleInterviewScreen extends StatefulWidget {
  const ScheduleInterviewScreen({
    super.key,
    required this.notification,
    this.existing,
    this.acceptApplication = false,
  });

  final JobApplicationNotification notification;

  /// `true` pour "Accepter et planifier l'entretien" (voir la doc de classe).
  final bool acceptApplication;

  /// Entretien déjà planifié pour cette candidature, s'il y en a un — le
  /// formulaire est alors pré-rempli et l'enregistrement met à jour la
  /// ligne existante au lieu d'en créer une nouvelle.
  final Interview? existing;

  @override
  State<ScheduleInterviewScreen> createState() => _ScheduleInterviewScreenState();
}

class _ScheduleInterviewScreenState extends State<ScheduleInterviewScreen> {
  final InterviewRepository _repository = const InterviewRepository();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final AuthService _authService = AuthService();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  /// Message au candidat joint à l'acceptation (mode [ScheduleInterviewScreen.acceptApplication]).
  final _acceptMessageController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;

  /// Date et heure laissées "à définir" (voir la doc de classe).
  bool _dateToBeDefined = false;
  String _mode = InterviewMode.presentiel;
  bool _saving = false;
  String? _dateError;
  String? _timeError;

  JobApplicationNotification get _notification => widget.notification;

  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  /// Fond des champs : violet très pâle + fine bordure, comme la zone de
  /// saisie de la maquette.
  Color get _fieldFill => SoftUi.isDark(_colors)
      ? _colors.surface
      : DashboardColors.accent.withValues(alpha: 0.035);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _dateToBeDefined = existing.isDateToBeDefined;
      _date = existing.date;
      final existingTime = existing.time;
      if (existingTime != null) {
        final parts = existingTime.split(':');
        _time = TimeOfDay(
          hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
      }
      _mode = existing.mode;
      _locationController.text = existing.location ?? '';
      _notesController.text = existing.notes ?? '';
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _acceptMessageController.dispose();
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
      _dateError = !_dateToBeDefined && _date == null ? 'Choisissez une date' : null;
      _timeError = !_dateToBeDefined && _time == null ? 'Choisissez une heure' : null;
    });
    if (_dateError != null || _timeError != null || _saving) return;

    final employerUserId = int.tryParse(_authService.currentUser?.id ?? '');
    if (employerUserId == null) return;

    setState(() => _saving = true);
    final date = _dateToBeDefined ? null : _date;
    final time = _dateToBeDefined ? null : _formatTime(_time!);

    Interview result;
    if (widget.existing != null) {
      await _repository.update(
        id: widget.existing!.id,
        date: date,
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
        date: date == null ? null : DateTime(date.year, date.month, date.day),
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
        date: date,
        time: time,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        mode: _mode,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    if (widget.acceptApplication) {
      await _jobOfferRepository.acceptApplication(
        _notification.applicationId,
        message: _acceptMessageController.text,
      );
    }

    if (!mounted) return;
    final String confirmation;
    if (widget.acceptApplication) {
      confirmation = 'Candidature acceptée et entretien planifié. $_candidateName a été informé(e).';
    } else if (widget.existing != null) {
      confirmation = 'Entretien mis à jour.';
    } else {
      confirmation = 'Entretien planifié avec $_candidateName.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmation)));
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isVisio = _mode == InterviewMode.visio;
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(_colors),
      appBar: SoftAppBar(
        title: widget.acceptApplication
            ? 'Accepter la candidature'
            : (widget.existing != null ? "Modifier l'entretien" : 'Planifier un entretien'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.safeAreaHorizontal,
            AppSpacing.sm,
            AppSpacing.safeAreaHorizontal,
            AppSpacing.xl,
          ),
          children: [
            SoftCard(
              padding: const EdgeInsets.all(18),
              radius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: staggered([
                  Row(
                    children: [
                      SoftAvatar(name: _candidateName, size: 42),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _candidateName,
                              style: AppTypography.interSemiBold.copyWith(
                                fontSize: 15,
                                color: _colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Pour "${_notification.offer.title}"',
                              style: AppTypography.interRegular.copyWith(
                                fontSize: 12,
                                color: _colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.acceptApplication) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildAcceptInfo(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _label('Type d\'entretien'),
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
                  const SerifSectionTitle('Quand vous rencontrez-vous ?', fontSize: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Le candidat est prévenu dès que l\'entretien est enregistré.',
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 13,
                      color: _colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildToBeDefinedSwitch(),
                  const SizedBox(height: AppSpacing.sm),
                  SmoothSwitcher(
                    child: _dateToBeDefined
                        ? null
                        : Row(
                      key: const ValueKey('pickers'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPickerField(
                          label: 'Date',
                          value: _date != null ? _formatDate(_date!) : 'Choisir',
                          icon: Icons.calendar_today_rounded,
                          isPlaceholder: _date == null,
                          error: _dateError,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildPickerField(
                          label: 'Heure',
                          value: _time != null ? _formatTime(_time!) : 'Choisir',
                          icon: Icons.access_time_rounded,
                          isPlaceholder: _time == null,
                          error: _timeError,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                  if (widget.acceptApplication) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _acceptMessageController,
                      label: 'Message au candidat (facultatif)',
                      hint: 'Ex : Félicitations, nous avons hâte de vous rencontrer !',
                      icon: Icons.chat_bubble_outline_rounded,
                      maxLines: 3,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SoftPrimaryButton(
                    label: widget.acceptApplication
                        ? 'Accepter et planifier'
                        : (widget.existing != null ? 'Enregistrer' : "Planifier l'entretien"),
                    icon: widget.acceptApplication ? Icons.check_rounded : Icons.send_rounded,
                    color: widget.acceptApplication ? const Color(0xFF0F8A6E) : null,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Encadré vert du mode acceptation : explique pourquoi un entretien est
  /// demandé avant d'accepter.
  Widget _buildAcceptInfo() {
    const green = Color(0xFF0F8A6E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SoftUi.tint(_colors, green),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: SoftUi.accentInk(_colors, green)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Pour accepter cette candidature, proposez un entretien : le candidat "
              "saura ainsi quelle est la suite. La date peut rester à définir.",
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                height: 1.4,
                color: _colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interrupteur "Date et heure à définir plus tard".
  Widget _buildToBeDefinedSwitch() {
    return Material(
      color: _fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: _dateToBeDefined,
        onChanged: (value) => setState(() {
          _dateToBeDefined = value;
          _dateError = null;
          _timeError = null;
        }),
        activeThumbColor: SoftUi.brandInk(_colors),
        title: Text(
          'Date et heure à définir plus tard',
          style: AppTypography.interSemiBold.copyWith(fontSize: 13.5, color: _colors.textPrimary),
        ),
        subtitle: Text(
          _dateToBeDefined
              ? 'Le candidat verra « Date à définir ». Fixez-la plus tard via « Modifier l\'entretien ».'
              : 'Activez si vous ne connaissez pas encore le créneau.',
          style: AppTypography.interRegular.copyWith(fontSize: 12, color: _colors.textSecondary),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.interSemiBold.copyWith(fontSize: 13.5, color: _colors.textPrimary),
      );

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
        _label(label),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: _fieldFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: error != null ? AppColors.error : _colors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: SoftUi.brandInk(_colors)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 14,
                        color: isPlaceholder ? _colors.textTertiary : _colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
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

  /// Option du sélecteur segmenté (comme "Plainte / Suggestion /
  /// Compliment" de la maquette) : bordure + fond violets une fois choisie.
  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ink = SoftUi.brandInk(_colors);
    return Expanded(
      child: Material(
        color: selected
            ? SoftUi.tint(_colors, DashboardColors.accent)
            : (SoftUi.isDark(_colors) ? _colors.surface : DashboardColors.segment),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? ink : Colors.transparent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 20, color: selected ? ink : _colors.textSecondary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.interSemiBold.copyWith(
                    fontSize: 13,
                    color: selected ? ink : _colors.textSecondary,
                  ),
                ),
              ],
            ),
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
        _label(label),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.interRegular.copyWith(fontSize: 14, color: _colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.interRegular.copyWith(color: _colors.textTertiary, fontSize: 13),
            prefixIcon: maxLines == 1 ? Icon(icon, size: 18, color: SoftUi.brandInk(_colors)) : null,
            filled: true,
            fillColor: _fieldFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: SoftUi.brandInk(_colors)),
            ),
          ),
        ),
      ],
    );
  }
}
