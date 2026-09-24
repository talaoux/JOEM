import 'package:flutter/material.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/category_card.dart';
import 'category_offers_screen.dart';
import 'job_notifications_screen.dart';
import 'job_profile_screen.dart';
import 'portfolio_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

class JobCategoriesScreen extends StatefulWidget {
  const JobCategoriesScreen({super.key});

  @override
  State<JobCategoriesScreen> createState() => _JobCategoriesScreenState();
}

class _JobCategoriesScreenState extends State<JobCategoriesScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final InterviewRepository _interviewRepository = const InterviewRepository();

  /// Pastille de la nav basse — même calcul que sur le dashboard.
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final offersMuted = _authService.currentUser?.notificationsEnabled == false;
    final offerCount = offersMuted
        ? 0
        : await _jobOfferRepository.countUnreadNotificationsForJobSeeker(userId);
    final interviewCount =
        await _interviewRepository.countUnreadNotificationsForJobSeeker(userId);
    final decisionCount =
        await _jobOfferRepository.countUnreadDecisionNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() => _notificationCount = offerCount + interviewCount + decisionCount);
  }

  /// Navigation de la barre basse : remplace l'écran courant par l'écran
  /// cible (comportement d'onglets, pas d'empilement) ou revient au
  /// dashboard ("Accueil", toujours la racine de la pile de navigation
  /// après connexion).
  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    late final Widget screen;
    switch (index) {
      case 2:
        screen = const PortfolioScreen();
        break;
      case 3:
        screen = const JobNotificationsScreen();
        break;
      default:
        screen = const JobProfileScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  static const List<Map<String, dynamic>> _categories = [
    {'title': 'Informatique', 'icon': Icons.computer_rounded},
    {'title': 'Commerce', 'icon': Icons.shopping_bag_rounded},
    {'title': 'Santé', 'icon': Icons.medical_services_rounded},
    {'title': 'BTP', 'icon': Icons.construction_rounded},
    {'title': 'Finance', 'icon': Icons.account_balance_rounded},
    {'title': 'Marketing', 'icon': Icons.campaign_rounded},
    {'title': 'Education', 'icon': Icons.school_rounded},
    {'title': 'Industrie', 'icon': Icons.precision_manufacturing_rounded},
    {'title': 'Transport', 'icon': Icons.local_shipping_rounded},
    {'title': 'Tourisme', 'icon': Icons.hotel_rounded},
    {'title': 'Agriculture', 'icon': Icons.agriculture_rounded},
    {'title': 'Juridique', 'icon': Icons.gavel_rounded},
    {'title': 'Ressources Humaines', 'icon': Icons.groups_rounded},
    {'title': 'Communication', 'icon': Icons.record_voice_over_rounded},
    {'title': 'Artisanat', 'icon': Icons.handyman_rounded},
    {'title': 'Sécurité', 'icon': Icons.security_rounded},
    {'title': 'Restauration', 'icon': Icons.restaurant_rounded},
    {'title': 'Textile', 'icon': Icons.checkroom_rounded},
    {'title': 'Logistique', 'icon': Icons.inventory_2_rounded},
    {'title': 'Télécommunications', 'icon': Icons.cell_tower_rounded},
    {'title': 'Mines & Énergie', 'icon': Icons.bolt_rounded},
    {'title': "BPO & Centres d'appels", 'icon': Icons.headset_mic_rounded},
    {'title': 'ONG & Humanitaire', 'icon': Icons.volunteer_activism_rounded},
    {'title': 'Immobilier', 'icon': Icons.apartment_rounded},
    // Toujours en dernier : offres dont le secteur ne figure pas ci-dessus
    // (secteur précisé par le recruteur, `kOtherJobCategory`).
    {'title': kOtherJobCategory, 'icon': Icons.more_horiz_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
                vertical: AppSpacing.headerPadding,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SerifSectionTitle('Catégories'),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return FadeSlideIn(delay: staggerDelayFor(index, maxSteps: 12, step: const Duration(milliseconds: 35)), child: CategoryCard(
                    title: category['title'],
                    icon: category['icon'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryOffersScreen(category: category['title'] as String),
                        ),
                      );
                    },
                  ));
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        onTap: _onNavTap,
        notificationCount: _notificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
        thirdItemIcon: Icons.collections_bookmark_rounded,
        thirdItemLabel: 'Portfolio',
      ),
    );
  }
}