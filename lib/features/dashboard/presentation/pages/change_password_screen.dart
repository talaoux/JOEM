import 'package:flutter/material.dart';

import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/widgets/glass_button.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Changement de mot de passe du compte connecté, ouvert depuis
/// `JobSeekerSettingsScreen`. Vérifie d'abord le mot de passe actuel
/// (`AuthService.verifyCurrentPassword`) avant d'écraser le nouveau via
/// `AuthService.resetPassword` — contrairement à `ForgotPasswordScreen`
/// (qui ne connaît pas l'ancien mot de passe puisqu'il est justement
/// oublié), on est ici déjà dans une session ouverte.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _currentPasswordError =
          currentPassword.isEmpty ? 'Renseignez votre mot de passe actuel' : null;
      _newPasswordError = newPassword.length < 6
          ? 'Le nouveau mot de passe doit contenir au moins 6 caractères'
          : (newPassword != confirmPassword
              ? 'Les deux mots de passe ne correspondent pas'
              : null);
    });
    if (_currentPasswordError != null || _newPasswordError != null) return;

    setState(() => _isSubmitting = true);

    final isCurrentPasswordValid = await _authService.verifyCurrentPassword(currentPassword);
    if (!isCurrentPasswordValid) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _currentPasswordError = 'Mot de passe actuel incorrect';
      });
      return;
    }

    final user = _authService.currentUser!;
    final success = await _authService.resetPassword(email: user.email, newPassword: newPassword);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour.')),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _currentPasswordError = 'Les comptes de démonstration ne peuvent pas changer de mot de passe';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        title: Text(
          'Changer le mot de passe',
          style: colors.dashboardTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          physics: const BouncingScrollPhysics(),
          child: Container(
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
                LightTextField(
                  label: 'Mot de passe actuel',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  controller: _currentPasswordController,
                  obscurable: true,
                  errorText: _currentPasswordError,
                ),
                const SizedBox(height: 18),
                LightTextField(
                  label: 'Nouveau mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_reset_rounded,
                  controller: _newPasswordController,
                  obscurable: true,
                  errorText: _newPasswordError,
                ),
                const SizedBox(height: 18),
                LightTextField(
                  label: 'Confirmer le nouveau mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_reset_rounded,
                  controller: _confirmPasswordController,
                  obscurable: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: _isSubmitting ? 'Mise à jour...' : 'Mettre à jour le mot de passe',
                    onTap: _isSubmitting ? null : _onSubmit,
                    color: OnboardingColors.violet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
