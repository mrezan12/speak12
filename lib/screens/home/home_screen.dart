import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_progress.dart';
import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature yakında gelecek'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _recordTestProgress(WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref
        .read(userProgressRepositoryProvider)
        .recordSentenceLearned(user.uid);
    ref.invalidate(userProgressProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final progressAsync = ref.watch(userProgressProvider);
    final name = user?.displayName?.split(' ').first ?? 'öğrenen';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(child: Text('Hata: $error')),
          data: (progress) {
            if (progress == null) {
              return const Center(child: Text('İlerleme bulunamadı'));
            }
            return _HomeBody(
              name: name,
              progress: progress,
              onComingSoon: (feature) => _comingSoon(context, feature),
              onTestIncrement: () => _recordTestProgress(ref),
            );
          },
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.name,
    required this.progress,
    required this.onComingSoon,
    required this.onTestIncrement,
  });

  final String name;
  final UserProgress progress;
  final void Function(String feature) onComingSoon;
  final VoidCallback onTestIncrement;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Merhaba, $name', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün biraz pratik yapalım.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/brand/speak12_mascot.png',
              height: 64,
              fit: BoxFit.contain,
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 20),
        _StreakCard(streak: progress.currentStreak)
            .animate()
            .fadeIn(delay: 60.ms, duration: 280.ms)
            .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _DailyProgressCard(progress: progress)
            .animate()
            .fadeIn(delay: 100.ms, duration: 280.ms)
            .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _LevelBadge(level: progress.currentLevel)
            .animate()
            .fadeIn(delay: 140.ms, duration: 280.ms),
        const SizedBox(height: 28),
        Text('Hızlı başla', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        _QuickAction(
          icon: Icons.style_rounded,
          title: 'Flashcard',
          subtitle: 'Cümle kartlarıyla pratik',
          onTap: () => onComingSoon('Flashcard'),
        ),
        const SizedBox(height: 10),
        _QuickAction(
          icon: Icons.quiz_rounded,
          title: 'Quiz',
          subtitle: 'Kısa bilgi kontrolü',
          onTap: () => onComingSoon('Quiz'),
        ),
        const SizedBox(height: 10),
        _QuickAction(
          icon: Icons.replay_rounded,
          title: 'Tekrar',
          subtitle: 'Öğrendiklerini pekiştir',
          onTap: () => onComingSoon('Tekrar'),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onTestIncrement,
          child: Text(
            'Günlük +1 (geçici test)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak gün streak',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  streak > 0
                      ? 'Seriyi bozma — bugün de devam et.'
                      : 'İlk gününü başlat, seriyi yak.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.dailyProgressFraction;
    final met = progress.isDailyGoalMet;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Günlük hedef',
                  style: AppTextStyles.headlineMedium,
                ),
              ),
              Text(
                '${progress.todayLearned} / ${progress.dailyGoal}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: met ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 12,
              backgroundColor: AppColors.surfaceVariant,
              color: met ? AppColors.primary : AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            met
                ? 'Hedef tamam — harika iş!'
                : 'Kalan: ${(progress.dailyGoal - progress.todayLearned).clamp(0, progress.dailyGoal)} cümle',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          'Seviye $level',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headlineMedium),
                    Text(subtitle, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
