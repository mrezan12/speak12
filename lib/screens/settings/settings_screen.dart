import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/review_providers.dart';
import '../../repositories/sentence_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _goals = <int>[5, 10, 20, 30];

  static const _levelSubtitles = <String, String>{
    'A1': 'Hiç bilmeyen / yeni başlayan',
    'A2': 'Temel günlük ifadeler',
    'B1': 'Orta seviye konuşma',
    'B2': 'Rahat ve akıcı iletişim',
    'C1': 'İleri / profesyonel dil',
    'C2': 'Near-native nüans',
  };

  String _initial(String? displayName, String? email) {
    final source = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (email?.trim().isNotEmpty == true ? email!.trim() : '?');
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _pickLevel(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    final progress = ref.read(userProgressProvider).value;
    if (user == null || progress == null) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text('Seviye seç', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    children: [
                      for (final level in SentenceRepository.supportedLevels)
                        ListTile(
                          title: Text(
                            level,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: level == progress.currentLevel
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _levelSubtitles[level] ?? '',
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: level == progress.currentLevel
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(level),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == progress.currentLevel) return;

    await ref.read(userProgressRepositoryProvider).updateCurrentLevel(
          userId: user.uid,
          level: selected,
        );
    ref.invalidate(userProgressProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seviye $selected olarak güncellendi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDailyGoal(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    final progress = ref.read(userProgressProvider).value;
    if (user == null || progress == null) return;

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Günlük hedef', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                for (final goal in _goals)
                  ListTile(
                    title: Text(
                      '$goal cümle',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: goal == progress.dailyGoal
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      goal <= 10
                          ? 'Hafif tempo'
                          : goal <= 20
                              ? 'Dengeli tempo'
                              : 'Yoğun tempo',
                      style: AppTextStyles.bodyMedium,
                    ),
                    trailing: goal == progress.dailyGoal
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(goal),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == progress.dailyGoal) return;

    await ref.read(userProgressRepositoryProvider).updateDailyGoal(
          userId: user.uid,
          dailyGoal: selected,
        );
    ref.invalidate(userProgressProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Günlük hedef $selected cümle olarak güncellendi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlerlemeyi sıfırla?'),
          content: const Text(
            'Streak, toplam öğrenilen ve aktivite geçmişi silinir. '
            'Seviye ve günlük hedef aynı kalır. Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Sıfırla'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(userProgressRepositoryProvider).resetProgress(user.uid);
    await ref.read(reviewRepositoryProvider).deleteAllReviews(user.uid);
    ref.invalidate(userProgressProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İlerleme sıfırlandı'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final progress = ref.watch(userProgressProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primaryDark,
              child: Text(_initial(user?.displayName, user?.email)),
            ),
            title: Text(
              user?.displayName ?? 'Kullanıcı',
              style: AppTextStyles.headlineMedium,
            ),
            subtitle: Text(
              user?.email ?? '',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Seviye'),
            subtitle: const Text('Flashcard ve Quiz bu seviyeyi kullanır'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  progress?.currentLevel ?? '—',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
            onTap: () => _pickLevel(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Günlük hedef'),
            subtitle: const Text('Her gün kaç cümle pratik yapmak istersin'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  progress == null ? '—' : '${progress.dailyGoal} cümle',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
            onTap: () => _pickDailyGoal(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bugün öğrenilen'),
            trailing: Text(
              progress == null ? '—' : '${progress.todayLearned}',
              style: AppTextStyles.labelLarge,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'İlerlemeyi sıfırla',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
            subtitle: const Text(
              'Streak ve istatistikleri temizler',
            ),
            onTap: () => _confirmReset(context, ref),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text('Çıkış yap'),
          ),
          const SizedBox(height: 12),
          Text(
            'Bildirim saati T19’da eklenecek.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
