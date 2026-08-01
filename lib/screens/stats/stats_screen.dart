import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_progress.dart';
import '../../providers/progress_providers.dart';
import '../../repositories/sentence_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('İstatistik')),
      body: progressAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(child: Text('Hata: $error')),
        data: (progress) {
          if (progress == null) {
            return const Center(child: Text('İlerleme bulunamadı'));
          }
          return _StatsBody(progress: progress);
        },
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final week = progress.recentActivity(days: 7);
    final maxWeek = week.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final levelEntries = _orderedLevelEntries(progress.learnedByLevel);
    final levelTotal = levelEntries.fold<int>(0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Özet', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.primaryDark,
                label: 'Toplam',
                value: '${progress.totalLearned}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warning,
                label: 'Streak',
                value: '${progress.currentStreak}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.secondary,
                label: 'En uzun',
                value: '${progress.longestStreak}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Bugünkü hedef', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        _GoalCard(progress: progress),
        const SizedBox(height: 24),
        Text('Son 7 gün', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Bu özellikten önceki günler boş görünebilir.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        _WeekStrip(week: week, maxCount: maxWeek),
        const SizedBox(height: 24),
        Text('Seviye dağılımı', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        if (levelEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Henüz seviye bazlı kayıt yok. Flashcard veya Quiz ile pratik yapınca dolacak.',
              style: AppTextStyles.bodyMedium,
            ),
          )
        else
          ...levelEntries.map((entry) {
            final fraction =
                levelTotal == 0 ? 0.0 : (entry.value / levelTotal).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelRow(
                level: entry.key,
                count: entry.value,
                fraction: fraction,
                isCurrent: entry.key == progress.currentLevel,
              ),
            );
          }),
      ],
    );
  }

  List<MapEntry<String, int>> _orderedLevelEntries(Map<String, int> raw) {
    final ordered = <MapEntry<String, int>>[];
    for (final level in SentenceRepository.supportedLevels) {
      final count = raw[level] ?? 0;
      if (count > 0) ordered.add(MapEntry(level, count));
    }
    for (final entry in raw.entries) {
      if (!SentenceRepository.supportedLevels.contains(entry.key) &&
          entry.value > 0) {
        ordered.add(entry);
      }
    }
    return ordered;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.headlineLarge),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
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
                  met ? 'Hedef tamam' : 'Devam et',
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
              value: progress.dailyProgressFraction,
              minHeight: 12,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.week,
    required this.maxCount,
  });

  final List<({DateTime day, int count})> week;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < week.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _DayBar(
                label: StatsScreen._weekdayLabels[week[i].day.weekday - 1],
                count: week[i].count,
                maxCount: maxCount,
                isToday: i == week.length - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.isToday,
  });

  final String label;
  final int count;
  final int maxCount;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 72.0;
    final ratio = maxCount <= 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
    final barHeight = count == 0 ? 6.0 : (12.0 + ratio * (maxHeight - 12));

    return Column(
      children: [
        Text(
          count > 0 ? '$count' : '·',
          style: AppTextStyles.bodySmall.copyWith(
            color: count > 0 ? AppColors.primaryDark : AppColors.textHint,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: maxHeight,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: double.infinity,
            height: barHeight,
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.primary.withValues(alpha: 0.35 + ratio * 0.65)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: AppColors.primaryDark, width: 1.5)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
            color: isToday ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.count,
    required this.fraction,
    required this.isCurrent,
  });

  final String level;
  final int count;
  final double fraction;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(level, style: AppTextStyles.labelLarge),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Text(
                  'aktif',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              Text('$count', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
