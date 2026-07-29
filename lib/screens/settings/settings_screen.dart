import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../repositories/sentence_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
            trailing: Text(
              progress == null ? '—' : '${progress.dailyGoal} cümle',
              style: AppTextStyles.labelLarge,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bugün öğrenilen'),
            trailing: Text(
              progress == null ? '—' : '${progress.todayLearned}',
              style: AppTextStyles.labelLarge,
            ),
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
            'Tam ayarlar ekranı T16’da genişletilecek.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
