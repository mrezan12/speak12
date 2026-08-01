import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_progress.dart';

class UserProgressRepository {
  UserProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  UserProgress defaultProgress(String userId) {
    return UserProgress(
      userId: userId,
      currentLevel: 'A1',
      dailyGoal: 10,
      currentStreak: 0,
      longestStreak: 0,
      lastStudyDate: null,
      totalLearned: 0,
      todayLearned: 0,
      onboardingCompleted: false,
    );
  }

  Future<UserProgress> getUserProgress(String userId) async {
    final snapshot = await _userDoc(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      final created = defaultProgress(userId);
      await saveUserProgress(created);
      return created;
    }

    final data = Map<String, dynamic>.from(snapshot.data()!);
    data.putIfAbsent('userId', () => userId);
    var progress = UserProgress.fromMap(data);
    progress = _normalizeForToday(progress);
    if (progress.todayLearned != (data['todayLearned'] as num?)?.toInt() ||
        progress.currentStreak != (data['currentStreak'] as num?)?.toInt()) {
      await saveUserProgress(progress);
    }
    return progress;
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    await _userDoc(progress.userId).set(
      progress.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<UserProgress> completeOnboarding({
    required String userId,
    required String level,
    required int dailyGoal,
  }) async {
    final current = await getUserProgress(userId);
    final updated = current.copyWith(
      currentLevel: level,
      dailyGoal: dailyGoal,
      onboardingCompleted: true,
    );
    await saveUserProgress(updated);
    return updated;
  }

  Future<UserProgress> updateCurrentLevel({
    required String userId,
    required String level,
  }) async {
    final current = await getUserProgress(userId);
    final updated = current.copyWith(currentLevel: level);
    await saveUserProgress(updated);
    return updated;
  }

  /// Increments today's practice count and updates streak when appropriate.
  Future<UserProgress> recordSentenceLearned(String userId) async {
    final current = _normalizeForToday(await getUserProgress(userId));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = current.lastStudyDate == null
        ? null
        : DateTime(
            current.lastStudyDate!.year,
            current.lastStudyDate!.month,
            current.lastStudyDate!.day,
          );

    var streak = current.currentStreak;
    if (last == null) {
      streak = 1;
    } else if (last == today) {
      // already practiced today — keep streak
    } else if (last == today.subtract(const Duration(days: 1))) {
      streak = current.currentStreak + 1;
    } else {
      streak = 1;
    }

    final longest =
        streak > current.longestStreak ? streak : current.longestStreak;

    final dayKey = UserProgress.dayKey(today);
    final activity = Map<String, int>.from(current.activityByDay);
    activity[dayKey] = (activity[dayKey] ?? 0) + 1;

    final byLevel = Map<String, int>.from(current.learnedByLevel);
    byLevel[current.currentLevel] = (byLevel[current.currentLevel] ?? 0) + 1;

    final updated = current.copyWith(
      lastStudyDate: now,
      totalLearned: current.totalLearned + 1,
      todayLearned: current.todayLearned + 1,
      currentStreak: streak,
      longestStreak: longest,
      activityByDay: activity,
      learnedByLevel: byLevel,
    );
    await saveUserProgress(updated);
    return updated;
  }

  Stream<UserProgress?> watchUserProgress(String userId) {
    return _userDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      data.putIfAbsent('userId', () => userId);
      return _normalizeForToday(UserProgress.fromMap(data));
    });
  }

  /// If last study was not today, reset todayLearned for display/persistence.
  UserProgress _normalizeForToday(UserProgress progress) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = progress.lastStudyDate == null
        ? null
        : DateTime(
            progress.lastStudyDate!.year,
            progress.lastStudyDate!.month,
            progress.lastStudyDate!.day,
          );

    if (last == today) return progress;
    if (progress.todayLearned == 0) return progress;
    return progress.copyWith(todayLearned: 0);
  }
}
