import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_progress.dart';
import '../repositories/user_progress_repository.dart';
import 'auth_providers.dart';

final userProgressRepositoryProvider = Provider<UserProgressRepository>((ref) {
  return UserProgressRepository();
});

final userProgressProvider = FutureProvider<UserProgress?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  return ref.watch(userProgressRepositoryProvider).getUserProgress(user.uid);
});
