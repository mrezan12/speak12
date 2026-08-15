import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sentence.dart';
import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/review_providers.dart';
import '../../services/srs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Due-queue review session (T17 SRS).
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  static const _maxRequeuesPerCard = 3;

  final List<Sentence> _queue = [];
  final Map<String, int> _missCounts = {};

  int _sessionSize = 0;
  int _knew = 0;
  int _didNotKnow = 0;
  bool _flipped = false;
  bool _busy = false;
  bool _loading = true;
  bool _finished = false;
  bool _empty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Giriş gerekli';
        });
        return;
      }

      final due = await loadDueSentences(ref: ref, userId: user.uid);
      setState(() {
        _queue
          ..clear()
          ..addAll(due);
        _sessionSize = due.length;
        _loading = false;
        _empty = due.isEmpty;
        if (due.isEmpty) {
          // stay on empty state, not finished summary
        }
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Sentence? get _current => _queue.isEmpty ? null : _queue.first;

  Future<void> _onKnew() async {
    final card = _current;
    final user = ref.read(authStateProvider).value;
    if (card == null || user == null || _busy) return;

    setState(() => _busy = true);
    try {
      await applySentenceReview(
        ref: ref,
        userId: user.uid,
        sentence: card,
        quality: SrsService.qualityGood,
      );
      await ref
          .read(userProgressRepositoryProvider)
          .recordSentenceLearned(user.uid);
      if (!mounted) return;
      setState(() {
        _knew += 1;
        _queue.removeAt(0);
        _flipped = false;
        _busy = false;
        if (_queue.isEmpty) _finished = true;
      });
      ref.invalidate(userProgressProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt hatası: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onDidNotKnow() async {
    final card = _current;
    final user = ref.read(authStateProvider).value;
    if (card == null || user == null || _busy) return;

    setState(() => _busy = true);
    try {
      await applySentenceReview(
        ref: ref,
        userId: user.uid,
        sentence: card,
        quality: SrsService.qualityAgain,
      );

      final misses = (_missCounts[card.id] ?? 0) + 1;
      _missCounts[card.id] = misses;
      _didNotKnow += 1;
      _queue.removeAt(0);
      if (misses < _maxRequeuesPerCard) {
        final insertAt = math.min(2, _queue.length);
        _queue.insert(insertAt, card);
      }

      if (!mounted) return;
      setState(() {
        _flipped = false;
        _busy = false;
        if (_queue.isEmpty) _finished = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt hatası: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tekrar'),
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
                : _empty
                    ? const _EmptyDueState()
                    : _finished
                        ? _ReviewSummary(
                            knew: _knew,
                            didNotKnow: _didNotKnow,
                            sessionSize: _sessionSize,
                            onDone: () => Navigator.of(context).pop(),
                          )
                        : _ReviewBody(
                            current: _current!,
                            flipped: _flipped,
                            knew: _knew,
                            sessionSize: _sessionSize,
                            remaining: _queue.length,
                            busy: _busy,
                            onFlip: () => setState(() => _flipped = !_flipped),
                            onKnew: _onKnew,
                            onDidNotKnow: _onDidNotKnow,
                          ),
      ),
    );
  }
}

class _EmptyDueState extends StatelessWidget {
  const _EmptyDueState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/brand/speak12_mascot.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text('Bugün tekrar yok', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Flashcard veya Quiz ile yeni cümle öğren; '
            'zamanı gelenler burada listelenir.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ana sayfaya dön'),
          ),
        ],
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.current,
    required this.flipped,
    required this.knew,
    required this.sessionSize,
    required this.remaining,
    required this.busy,
    required this.onFlip,
    required this.onKnew,
    required this.onDidNotKnow,
  });

  final Sentence current;
  final bool flipped;
  final int knew;
  final int sessionSize;
  final int remaining;
  final bool busy;
  final VoidCallback onFlip;
  final VoidCallback onKnew;
  final VoidCallback onDidNotKnow;

  @override
  Widget build(BuildContext context) {
    final progress =
        sessionSize == 0 ? 0.0 : (knew / sessionSize).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('$knew / $sessionSize', style: AppTextStyles.labelLarge),
              const Spacer(),
              Text('Kalan $remaining', style: AppTextStyles.bodyMedium),
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
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: onFlip,
              child: AnimatedSwitcher(
                duration: 320.ms,
                child: Container(
                  key: ValueKey('${current.id}-$flipped'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (flipped
                                  ? AppColors.primaryDark
                                  : AppColors.warning)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          flipped ? 'Türkçe' : 'English',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: flipped
                                ? AppColors.primaryDark
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        flipped ? current.turkishText : current.englishText,
                        style: (flipped
                                ? AppTextStyles.translationText
                                : AppTextStyles.sentenceText)
                            .copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!flipped)
            Text(
              'Çeviriyi görmek için karta dokun',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            )
          else ...[
            FilledButton(
              onPressed: busy ? null : onKnew,
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Bildim'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: busy ? null : onDidNotKnow,
              child: const Text('Bilemedim'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.knew,
    required this.didNotKnow,
    required this.sessionSize,
    required this.onDone,
  });

  final int knew;
  final int didNotKnow;
  final int sessionSize;
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
              ),
          const SizedBox(height: 16),
          Text('Tekrar bitti', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            '$sessionSize kartlık tekrar tamamlandı.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _SummaryRow(
            label: 'Bildim',
            value: '$knew',
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Bilemedim',
            value: '$didNotKnow',
            color: AppColors.warning,
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
