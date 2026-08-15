import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sentence.dart';
import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/review_providers.dart';
import '../../providers/sentence_providers.dart';
import '../../services/srs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  static const _maxSessionSize = 20;
  static const _optionCount = 4;
  static const _feedbackDelay = Duration(milliseconds: 900);

  final List<_QuizQuestion> _questions = [];

  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int? _selectedIndex;
  bool _revealed = false;
  bool _busy = false;
  bool _loading = true;
  bool _finished = false;
  String? _error;
  String? _streakBanner;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final progress = await ref.read(userProgressProvider.future);
      if (progress == null) {
        setState(() {
          _loading = false;
          _error = 'İlerleme bulunamadı';
        });
        return;
      }

      final pool = List<Sentence>.from(
        ref.read(sentencesByLevelProvider(progress.currentLevel)),
      );

      if (pool.length < _optionCount) {
        setState(() {
          _loading = false;
          _error = 'Quiz için bu seviyede en az $_optionCount cümle gerekir';
        });
        return;
      }

      final size = progress.dailyGoal.clamp(1, _maxSessionSize);
      final sessionPool = List<Sentence>.from(pool)..shuffle();
      final session = sessionPool.take(math.min(size, sessionPool.length)).toList();

      final questions = <_QuizQuestion>[];
      for (final sentence in session) {
        final built = _QuizQuestion.fromPool(sentence, pool);
        if (built != null) questions.add(built);
      }

      setState(() {
        _questions
          ..clear()
          ..addAll(questions);
        _loading = false;
        if (questions.isEmpty) {
          _error = 'Quiz soruları oluşturulamadı';
        }
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  _QuizQuestion? get _current =>
      _questions.isEmpty || _index >= _questions.length
          ? null
          : _questions[_index];

  String? _messageForStreak(int streak) {
    if (streak >= 6) return 'Durdurulamaz!';
    return switch (streak) {
      2 => 'İyi gidiyorsun!',
      3 => 'Harika!',
      4 => 'Süpersin!',
      5 => 'Muazzam!',
      _ => null,
    };
  }

  Future<void> _onSelect(int optionIndex) async {
    final question = _current;
    final user = ref.read(authStateProvider).value;
    if (question == null || _revealed || _busy || user == null) return;

    final isCorrect = optionIndex == question.correctIndex;

    setState(() {
      _busy = true;
      _selectedIndex = optionIndex;
      _revealed = true;
      if (isCorrect) {
        _correct += 1;
        _streak += 1;
        _streakBanner = _messageForStreak(_streak);
      } else {
        _wrong += 1;
        _streak = 0;
        _streakBanner = null;
      }
    });

    try {
      await applySentenceReview(
        ref: ref,
        userId: user.uid,
        sentence: question.sentence,
        quality: isCorrect ? SrsService.qualityGood : SrsService.qualityAgain,
      );
      if (isCorrect) {
        await ref
            .read(userProgressRepositoryProvider)
            .recordSentenceLearned(user.uid);
        ref.invalidate(userProgressProvider);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt hatası: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _advanceTimer?.cancel();
    _advanceTimer = Timer(_feedbackDelay, () {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selectedIndex = null;
        _revealed = false;
        _streakBanner = null;
        if (_index + 1 >= _questions.length) {
          _finished = true;
        } else {
          _index += 1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : _finished
                    ? _QuizSummary(
                        correct: _correct,
                        wrong: _wrong,
                        total: _questions.length,
                        onDone: () => Navigator.of(context).pop(),
                      )
                    : _QuizBody(
                        question: _current!,
                        index: _index,
                        total: _questions.length,
                        correctCount: _correct,
                        selectedIndex: _selectedIndex,
                        revealed: _revealed,
                        streakBanner: _streakBanner,
                        onSelect: _onSelect,
                      ),
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.sentence,
    required this.options,
    required this.correctIndex,
  });

  final Sentence sentence;
  final List<String> options;
  final int correctIndex;

  static _QuizQuestion? fromPool(Sentence sentence, List<Sentence> pool) {
    final correct = sentence.turkishText;
    final targetTokens = _tokens(correct);

    final candidates = pool
        .where(
          (s) => s.id != sentence.id && s.turkishText != correct,
        )
        .map((s) => s.turkishText)
        .toSet()
        .toList()
      ..shuffle();

    if (candidates.length < 3) return null;

    candidates.sort((a, b) {
      final scoreCmp = _similarity(b, correct, targetTokens)
          .compareTo(_similarity(a, correct, targetTokens));
      if (scoreCmp != 0) return scoreCmp;
      return a.length.compareTo(b.length);
    });

    final options = <String>[
      correct,
      ...candidates.take(3),
    ]..shuffle();

    return _QuizQuestion(
      sentence: sentence,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  /// Word overlap (Jaccard) + length closeness → more plausible distractors.
  static double _similarity(
    String candidate,
    String correct,
    Set<String> targetTokens,
  ) {
    final candidateTokens = _tokens(candidate);
    final union = targetTokens.union(candidateTokens);
    final intersection = targetTokens.intersection(candidateTokens);
    final jaccard = union.isEmpty ? 0.0 : intersection.length / union.length;

    final maxLen = math.max(correct.length, candidate.length).clamp(1, 100000);
    final lengthScore = 1.0 - ((correct.length - candidate.length).abs() / maxLen);

    // Overlap weighs more; length helps when few shared words.
    return (jaccard * 3.0) + lengthScore;
  }

  static Set<String> _tokens(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r"[^\wğüşıöçâîû]", caseSensitive: false), ''))
        .where((word) => word.length > 1)
        .toSet();
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.question,
    required this.index,
    required this.total,
    required this.correctCount,
    required this.selectedIndex,
    required this.revealed,
    required this.streakBanner,
    required this.onSelect,
  });

  final _QuizQuestion question;
  final int index;
  final int total;
  final int correctCount;
  final int? selectedIndex;
  final bool revealed;
  final String? streakBanner;
  final Future<void> Function(int optionIndex) onSelect;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (index / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${index + 1} / $total',
                style: AppTextStyles.labelLarge,
              ),
              const Spacer(),
              Text(
                'Doğru $correctCount',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: streakBanner == null
                ? const SizedBox.shrink()
                : Center(
                    child: Container(
                      key: ValueKey(streakBanner),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        streakBanner!,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 180.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          curve: Curves.easeOutBack,
                        ),
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'English',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  question.sentence.englishText,
                  style: AppTextStyles.sentenceText.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                return _OptionTile(
                  text: question.options[i],
                  state: _optionState(
                    index: i,
                    correctIndex: question.correctIndex,
                    selectedIndex: selectedIndex,
                    revealed: revealed,
                  ),
                  onTap: revealed ? null : () => onSelect(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _OptionVisualState _optionState({
    required int index,
    required int correctIndex,
    required int? selectedIndex,
    required bool revealed,
  }) {
    if (!revealed || selectedIndex == null) return _OptionVisualState.idle;
    if (index == correctIndex) return _OptionVisualState.correct;
    if (index == selectedIndex) return _OptionVisualState.wrong;
    return _OptionVisualState.dimmed;
  }
}

enum _OptionVisualState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionVisualState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _OptionVisualState.idle => (
          AppColors.surface,
          AppColors.cardBorder,
          AppColors.textPrimary,
        ),
      _OptionVisualState.correct => (
          AppColors.primary.withValues(alpha: 0.14),
          AppColors.primary,
          AppColors.primaryDark,
        ),
      _OptionVisualState.wrong => (
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
          AppColors.error,
        ),
      _OptionVisualState.dimmed => (
          AppColors.surface,
          AppColors.cardBorder,
          AppColors.textHint,
        ),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizSummary extends StatelessWidget {
  const _QuizSummary({
    required this.correct,
    required this.wrong,
    required this.total,
    required this.onDone,
  });

  final int correct;
  final int wrong;
  final int total;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Image.asset(
            'assets/brand/speak12_mascot.png',
            height: 140,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(duration: 320.ms)
              .scale(
                begin: const Offset(0.82, 0.82),
                curve: Curves.easeOutBack,
              )
              .then(delay: 80.ms)
              .shake(hz: 2.5, rotation: 0.03, duration: 420.ms),
          const SizedBox(height: 16),
          Text('Quiz bitti!', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Tilki seni tebrik ediyor — $correct / $total doğru.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _SummaryRow(
            label: 'Doğru',
            value: '$correct',
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Yanlış',
            value: '$wrong',
            color: AppColors.error,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onDone,
            child: const Text('Ana sayfaya dön'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
