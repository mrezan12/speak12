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
  });

  final String userId;
  final String currentLevel;
  final int dailyGoal;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final int totalLearned;

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
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    final lastStudyTimestamp = map['lastStudyDate'] as Timestamp?;

    return UserProgress(
      userId: map['userId'] as String,
      currentLevel: map['currentLevel'] as String,
      dailyGoal: map['dailyGoal'] as int,
      currentStreak: map['currentStreak'] as int,
      longestStreak: map['longestStreak'] as int,
      lastStudyDate: lastStudyTimestamp?.toDate(),
      totalLearned: map['totalLearned'] as int,
    );
  }
}
