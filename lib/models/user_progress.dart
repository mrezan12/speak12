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
    this.todayLearned = 0,
    this.onboardingCompleted = false,
    this.activityByDay = const {},
    this.learnedByLevel = const {},
    this.reminderEnabled = true,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  final String userId;
  final String currentLevel;
  final int dailyGoal;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final int totalLearned;
  final int todayLearned;
  final bool onboardingCompleted;

  /// `yyyy-MM-dd` → sentences learned that day.
  final Map<String, int> activityByDay;

  /// CEFR level → sentences learned while on that level.
  final Map<String, int> learnedByLevel;

  /// Daily reminder switch (Ayarlar).
  final bool reminderEnabled;

  /// 0–23
  final int reminderHour;

  /// 0–59
  final int reminderMinute;

  String get reminderTimeLabel {
    final h = reminderHour.toString().padLeft(2, '0');
    final m = reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get isDailyGoalMet => todayLearned >= dailyGoal && dailyGoal > 0;

  double get dailyProgressFraction {
    if (dailyGoal <= 0) return 0;
    return (todayLearned / dailyGoal).clamp(0.0, 1.0);
  }

  /// Activity counts for the last [days] ending today (oldest → newest).
  List<({DateTime day, int count})> recentActivity({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final key = dayKey(day);
      return (day: day, count: activityByDay[key] ?? 0);
    });
  }

  static String dayKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  UserProgress copyWith({
    String? userId,
    String? currentLevel,
    int? dailyGoal,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    int? totalLearned,
    int? todayLearned,
    bool? onboardingCompleted,
    Map<String, int>? activityByDay,
    Map<String, int>? learnedByLevel,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
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
      todayLearned: todayLearned ?? this.todayLearned,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      activityByDay: activityByDay ?? this.activityByDay,
      learnedByLevel: learnedByLevel ?? this.learnedByLevel,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
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
      'todayLearned': todayLearned,
      'onboardingCompleted': onboardingCompleted,
      'activityByDay': activityByDay,
      'learnedByLevel': learnedByLevel,
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
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
      todayLearned: (map['todayLearned'] as num?)?.toInt() ?? 0,
      onboardingCompleted: map['onboardingCompleted'] == true,
      activityByDay: _stringIntMap(map['activityByDay']),
      learnedByLevel: _stringIntMap(map['learnedByLevel']),
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      reminderHour: (map['reminderHour'] as num?)?.toInt() ?? 20,
      reminderMinute: (map['reminderMinute'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, int> _stringIntMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    };
  }
}
