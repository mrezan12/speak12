import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;
  String _selectedLevel = 'A1';
  int _selectedGoal = 10;
  bool _busy = false;
  String? _error;

  static const _levels = <({String code, String title, String subtitle})>[
    (code: 'A1', title: 'A1', subtitle: 'Hiç bilmeyen / yeni başlayan'),
    (code: 'A2', title: 'A2', subtitle: 'Temel günlük ifadeler'),
    (code: 'B1', title: 'B1', subtitle: 'Orta seviye konuşma'),
    (code: 'B2', title: 'B2', subtitle: 'Rahat ve akıcı iletişim'),
    (code: 'C1', title: 'C1', subtitle: 'İleri / profesyonel dil'),
    (code: 'C2', title: 'C2', subtitle: 'Near-native nüans'),
  ];

  static const _goals = <int>[5, 10, 20, 30];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    final user = ref.read(authStateProvider).value;
    if (_pageIndex == 0 && user == null) {
      await _signIn();
      return;
    }

    if (_pageIndex < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _finish();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.invalidate(userProgressProvider);
      if (!mounted) return;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      setState(() => _error = 'Oturum bulunamadı. Tekrar giriş yap.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(userProgressRepositoryProvider).completeOnboarding(
            userId: user.uid,
            level: _selectedLevel,
            dailyGoal: _selectedGoal,
          );
      ref.invalidate(userProgressProvider);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isLastPage = _pageIndex == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: List.generate(3, (index) {
                  final active = index <= _pageIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: [
                  _WelcomePage(isSignedIn: user != null),
                  _LevelPage(
                    selectedLevel: _selectedLevel,
                    levels: _levels,
                    onSelect: (code) => setState(() => _selectedLevel = code),
                  ),
                  _GoalPage(
                    selectedGoal: _selectedGoal,
                    goals: _goals,
                    onSelect: (goal) => setState(() => _selectedGoal = goal),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _goNext,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isLastPage
                              ? 'Başla'
                              : (_pageIndex == 0 && user == null
                                  ? 'Google ile giriş'
                                  : 'Devam'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.isSignedIn,
  });

  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speak12',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.12, end: 0),
          const SizedBox(height: 12),
          Text(
            'Cümlelerle konuşmayı öğren.',
            style: AppTextStyles.headlineLarge,
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'Kelime ezberi değil: seviyenize uygun gerçek cümleler. '
            'Kısa pratik, kalıcı alışkanlık.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          )
              .animate()
              .fadeIn(delay: 140.ms, duration: 400.ms),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/brand/speak12_mascot.png',
                height: 220,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 500.ms)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                  ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              isSignedIn
                  ? 'Giriş tamam. Seviyeni seçmeye hazırsın.'
                  : 'İlerlemeni kaydetmek için Google ile devam et.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .fadeIn(delay: 240.ms, duration: 400.ms),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  const _LevelPage({
    required this.selectedLevel,
    required this.levels,
    required this.onSelect,
  });

  final String selectedLevel;
  final List<({String code, String title, String subtitle})> levels;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seviyen hangisi?', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Sonra istediğin zaman değiştirebilirsin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: levels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final level = levels[index];
                final selected = level.code == selectedLevel;
                return Material(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelect(level.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              level.title,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: selected
                                    ? AppColors.background
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              level.subtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryDark,
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: (40 * index).ms,
                      duration: 280.ms,
                    )
                    .slideX(begin: 0.04, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.selectedGoal,
    required this.goals,
    required this.onSelect,
  });

  final int selectedGoal;
  final List<int> goals;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Günlük hedefin?', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Küçük ve sürdürülebilir bir hedef seç.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                for (var i = 0; i < goals.length; i++)
                  _GoalCard(
                    goal: goals[i],
                    selected: goals[i] == selectedGoal,
                    onTap: () => onSelect(goals[i]),
                  )
                      .animate()
                      .fadeIn(delay: (50 * i).ms, duration: 280.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final int goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondary.withValues(alpha: 0.22)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.cardBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$goal',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'cümle / gün',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
