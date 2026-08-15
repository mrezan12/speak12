import '../models/sentence_review.dart';

/// SM-2 spaced repetition (binary grades mapped to quality 1 / 4).
class SrsService {
  static const int qualityAgain = 1;
  static const int qualityGood = 4;

  SentenceReview schedule(
    SentenceReview current,
    int quality, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    var ease = current.easeFactor;
    var repetitions = current.repetitions;
    var interval = current.intervalDays;
    var lapses = current.lapses;
    late DateTime dueAt;

    if (quality < 3) {
      repetitions = 0;
      interval = 0;
      lapses += 1;
      // Due immediately so Tekrar can show it again soon.
      dueAt = at;
    } else {
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round().clamp(1, 3650);
      }
      repetitions += 1;
      ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (ease < 1.3) ease = 1.3;
      final today = DateTime(at.year, at.month, at.day);
      dueAt = today.add(Duration(days: interval));
    }

    return current.copyWith(
      dueAt: dueAt,
      intervalDays: interval,
      easeFactor: double.parse(ease.toStringAsFixed(2)),
      repetitions: repetitions,
      lapses: lapses,
      updatedAt: at,
    );
  }
}
