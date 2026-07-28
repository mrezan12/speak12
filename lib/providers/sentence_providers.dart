import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sentence.dart';
import '../repositories/sentence_repository.dart';

final sentenceRepositoryProvider = Provider<SentenceRepository>((ref) {
  return SentenceRepository();
});

final sentencesByLevelProvider =
    Provider.family<List<Sentence>, String>((ref, level) {
  return ref.watch(sentenceRepositoryProvider).getByLevel(level);
});
