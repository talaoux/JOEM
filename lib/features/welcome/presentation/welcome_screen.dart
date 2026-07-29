import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/background_image_widget.dart';
import 'package:joem/core/widgets/dark_overlay_widget.dart';
import 'package:joem/core/widgets/logo_section_widget.dart';
import 'package:joem/features/job_seeker_registration/presentation/job_seeker_registration_screen.dart';
import 'package:joem/features/login/presentation/login_screen.dart';
import 'package:joem/features/recruiter_registration/presentation/recruiter_registration_screen.dart';
import 'package:joem/features/welcome/presentation/widgets/hero_text_widget.dart';
import 'package:joem/features/welcome/presentation/widgets/role_selection_card_widget.dart';

/// Écran d'accueil principal de JOEM
/// Design fidèle à la maquette de référence
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _mainAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // Démarrer l'animation au lancement
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onRecruiterTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecruiterRegistrationScreen()),
    );
  }

  void _onJobSeekerTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobSeekerRegistrationScreen()),
    );
  }

  void _onLoginTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dimensions responsives
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    // Tailles responsives
    final isLargeScreen = screenWidth > 600;
    final isTablet = screenWidth > 768;

    final horizontalPadding = isTablet ? 48.0 : (isLargeScreen ? 40.0 : 24.0);

    return Scaffold(
      body: Stack(
        children: [
          // Image de fond avec alignment spécifique pour le portrait
          const BackgroundImageWidget(
            imagePath: 'assets/images/pexels-mizunokozuki-13929421.jpg',
            alignment: Alignment.topCenter,
            zoom: 1.15,
          ),

          // Overlay sombre avec dégradé (45% haut, 25% centre, 90% bas)
          const DarkOverlayWidget(
            topOpacity: 0.45,
            centerOpacity: 0.25,
            bottomOpacity: 0.90,
          ),

          // Léger assombrissement supplémentaire en bandeau plein-largeur
          // tout en haut de l'écran (les deux côtés sont donc couverts),
          // qui s'estompe vers le bas.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.22,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo Section - repoussé jusqu'au bord gauche de
                        // l'écran via un décalage de peinture (Padding ne
                        // supporte pas les valeurs négatives), sans affecter
                        // le reste du contenu.
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Transform.translate(
                            offset: Offset(-horizontalPadding, 0),
                            child: LogoSectionWidget(animation: _mainAnimation),
                          ),
                        ),

                        // Espace flexible : pousse tout le contenu suivant
                        // (titre -> lien de connexion) vers le bas de l'écran,
                        // en laissant le logo à sa place et l'image bien visible.
                        const Spacer(),

                        // Hero Text - titre + description + tagline
                        HeroTextWidget(animation: _mainAnimation),

                        SizedBox(height: 28),

                        // Cartes de sélection de rôle
                        RoleSelectionCardWidget(
                          leftIcon: Icons.business_rounded,
                          rightIcon: Icons.chevron_right_rounded,
                          title: 'Je suis un recruteur',
                          description: 'Publiez des offres et trouvez les meilleurs talents',
                          onTap: _onRecruiterTap,
                          animation: _mainAnimation,
                          delayIndex: 0,
                        ),

                        SizedBox(height: 18),

                        RoleSelectionCardWidget(
                          leftIcon: Icons.person_rounded,
                          rightIcon: Icons.chevron_right_rounded,
                          title: 'Je cherche un emploi',
                          description: 'Trouvez l\'opportunité qui vous correspond',
                          onTap: _onJobSeekerTap,
                          animation: _mainAnimation,
                          delayIndex: 1,
                        ),

                        // Espacement avant footer
                        SizedBox(height: screenHeight * 0.03),

                        // Footer - Déjà inscrit ?
                        _buildFooter(),

                        SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _mainAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Déjà inscrit ?',
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _onLoginTap,
            child: Text(
              'Se connecter',
              style: AppTextStyles.interSemiBold.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}