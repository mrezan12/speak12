import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  const UserProgress({
    required this.userId,
    required this.currentLevel,
    required this.dailyGoal,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastStudyDate,
    required this.totalLearned,
    this.onboardingCompleted = false,
  });

  final String userId;
  final String currentLevel;
  final int dailyGoal;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final int totalLearned;
  final bool onboardingCompleted;

  UserProgress copyWith({
    String? userId,
    String? currentLevel,
    int? dailyGoal,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    int? totalLearned,
    bool? onboardingCompleted,
    bool clearLastStudyDate = false,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      currentLevel: currentLevel ?? this.currentLevel,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate:
          clearLastStudyDate ? null : (lastStudyDate ?? this.lastStudyDate),
      totalLearned: totalLearned ?? this.totalLearned,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentLevel': currentLevel,
      'dailyGoal': dailyGoal,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': lastStudyDate == null
          ? null
          : Timestamp.fromDate(lastStudyDate!),
      'totalLearned': totalLearned,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    final lastStudyTimestamp = map['lastStudyDate'] as Timestamp?;

    return UserProgress(
      userId: map['userId'] as String,
      currentLevel: map['currentLevel'] as String? ?? 'A1',
      dailyGoal: (map['dailyGoal'] as num?)?.toInt() ?? 10,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: lastStudyTimestamp?.toDate(),
      totalLearned: (map['totalLearned'] as num?)?.toInt() ?? 0,
      onboardingCompleted: map['onboardingCompleted'] == true,
    );
  }
}
