import '../data/a1_sentences.dart';
import '../data/a2_sentences.dart';
import '../data/b1_sentences.dart';
import '../data/b2_sentences.dart';
import '../data/c1_sentences.dart';
import '../data/c2_sentences.dart';
import '../models/sentence.dart';

class SentenceRepository {
  static const supportedLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  List<Sentence> getByLevel(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return List<Sentence>.unmodifiable(a1Sentences);
      case 'A2':
        return List<Sentence>.unmodifiable(a2Sentences);
      case 'B1':
        return List<Sentence>.unmodifiable(b1Sentences);
      case 'B2':
        return List<Sentence>.unmodifiable(b2Sentences);
      case 'C1':
        return List<Sentence>.unmodifiable(c1Sentences);
      case 'C2':
        return List<Sentence>.unmodifiable(c2Sentences);
      default:
        throw ArgumentError.value(level, 'level', 'Unsupported CEFR level');
    }
  }

  List<Sentence> getAll() {
    return List<Sentence>.unmodifiable([
      ...a1Sentences,
      ...a2Sentences,
      ...b1Sentences,
      ...b2Sentences,
      ...c1Sentences,
      ...c2Sentences,
    ]);
  }

  Sentence? getById(String id) {
    for (final sentence in getAll()) {
      if (sentence.id == id) return sentence;
    }
    return null;
  }
}
