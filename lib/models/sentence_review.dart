import 'package:cloud_firestore/cloud_firestore.dart';

class SentenceReview {
  const SentenceReview({
    required this.sentenceId,
    required this.level,
    required this.dueAt,
    required this.intervalDays,
    required this.easeFactor,
    required this.repetitions,
    required this.lapses,
    this.updatedAt,
  });

  final String sentenceId;
  final String level;
  final DateTime dueAt;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;
  final DateTime? updatedAt;

  factory SentenceReview.fresh({
    required String sentenceId,
    required String level,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return SentenceReview(
      sentenceId: sentenceId,
      level: level,
      dueAt: at,
      intervalDays: 0,
      easeFactor: 2.5,
      repetitions: 0,
      lapses: 0,
      updatedAt: at,
    );
  }

  SentenceReview copyWith({
    String? sentenceId,
    String? level,
    DateTime? dueAt,
    int? intervalDays,
    double? easeFactor,
    int? repetitions,
    int? lapses,
    DateTime? updatedAt,
  }) {
    return SentenceReview(
      sentenceId: sentenceId ?? this.sentenceId,
      level: level ?? this.level,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sentenceId': sentenceId,
      'level': level,
      'dueAt': Timestamp.fromDate(dueAt),
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
      'lapses': lapses,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  factory SentenceReview.fromMap(Map<String, dynamic> map) {
    return SentenceReview(
      sentenceId: map['sentenceId'] as String,
      level: map['level'] as String? ?? 'A1',
      dueAt: (map['dueAt'] as Timestamp).toDate(),
      intervalDays: (map['intervalDays'] as num?)?.toInt() ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,
      lapses: (map['lapses'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
