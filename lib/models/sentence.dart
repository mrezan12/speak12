class Sentence {
  const Sentence({
    required this.id,
    required this.englishText,
    required this.turkishText,
    required this.level,
    required this.audioPath,
  });

  final String id;
  final String englishText;
  final String turkishText;
  final String level;
  final String audioPath;
}
