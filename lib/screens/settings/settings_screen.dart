import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _initial(String? displayName, String? email) {
    final source = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (email?.trim().isNotEmpty == true ? email!.trim() : '?');
    return source.substring(0, 1).toUpperCase();
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
            trailing: Text(
              progress?.currentLevel ?? '—',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
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
