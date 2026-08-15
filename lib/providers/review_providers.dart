import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sentence.dart';
import '../models/sentence_review.dart';
import '../repositories/review_repository.dart';
import '../services/srs_service.dart';
import 'sentence_providers.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final srsServiceProvider = Provider<SrsService>((ref) {
  return SrsService();
});

/// Applies SM-2 and persists review state for a sentence.
Future<SentenceReview> applySentenceReview({
  required WidgetRef ref,
  required String userId,
  required Sentence sentence,
  required int quality,
}) async {
  final reviews = ref.read(reviewRepositoryProvider);
  final srs = ref.read(srsServiceProvider);
  final existing = await reviews.getReview(userId, sentence.id);
  final base = existing ??
      SentenceReview.fresh(
        sentenceId: sentence.id,
        level: sentence.level,
      );
  final next = srs.schedule(base, quality);
  await reviews.saveReview(userId, next);
  return next;
}

Future<List<Sentence>> loadDueSentences({
  required WidgetRef ref,
  required String userId,
  int limit = 20,
}) async {
  final due = await ref.read(reviewRepositoryProvider).getDueReviews(
        userId,
        limit: limit,
      );
  final sentences = ref.read(sentenceRepositoryProvider);
  final result = <Sentence>[];
  for (final review in due) {
    final sentence = sentences.getById(review.sentenceId);
    if (sentence != null) result.add(sentence);
  }
  return result;
}
