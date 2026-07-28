import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_progress.dart';
import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/sentence_providers.dart';
import '../../repositories/sentence_repository.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _totalSentenceCount() {
    final repo = ref.read(sentenceRepositoryProvider);
    var total = 0;
    for (final level in SentenceRepository.supportedLevels) {
      total += repo.getByLevel(level).length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final a1Count = ref.watch(sentencesByLevelProvider('A1')).length;
    final totalSentences = _totalSentenceCount();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Speak12'),
        backgroundColor: AppColors.surface,
      ),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Auth error: $error')),
        data: (user) {
          final progressAsync = ref.watch(userProgressProvider);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user == null
                      ? 'Google ile giriş yaparak ilerlemeyi senkronize et.'
                      : 'Merhaba, ${user.displayName ?? user.email ?? 'öğrenen'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Local cümleler: A1=$a1Count · tüm seviyeler=$totalSentences',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                if (user == null)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () => ref
                                  .read(authRepositoryProvider)
                                  .signInWithGoogle(),
                            ),
                    child: const Text('Google ile giriş'),
                  )
                else ...[
                  progressAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Progress: $error'),
                    data: (progress) {
                      if (progress == null) {
                        return const Text('Progress yok');
                      }
                      return Text(
                        'Seviye: ${progress.currentLevel} · '
                        'Streak: ${progress.currentStreak} · '
                        'Öğrenilen: ${progress.totalLearned} · '
                        'Hedef: ${progress.dailyGoal}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              final repo =
                                  ref.read(userProgressRepositoryProvider);
                              final current =
                                  await repo.getUserProgress(user.uid);
                              await repo.saveUserProgress(
                                UserProgress(
                                  userId: current.userId,
                                  currentLevel: current.currentLevel,
                                  dailyGoal: current.dailyGoal,
                                  currentStreak: current.currentStreak,
                                  longestStreak: current.longestStreak,
                                  lastStudyDate: DateTime.now(),
                                  totalLearned: current.totalLearned + 1,
                                ),
                              );
                              ref.invalidate(userProgressProvider);
                              setState(
                                () => _message = 'Progress Firestore’a yazıldı',
                              );
                            }),
                    child: const Text('Progress +1 (duman testi)'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () => ref.read(authRepositoryProvider).signOut(),
                            ),
                    child: const Text('Çıkış yap'),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
