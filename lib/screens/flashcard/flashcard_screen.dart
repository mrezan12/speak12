import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sentence.dart';
import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/sentence_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// In-session flashcard practice (T12). Bilmedim re-queues; SRS is T17.
class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  static const _maxSessionSize = 20;
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
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
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
      )..shuffle();

      final size = progress.dailyGoal.clamp(1, _maxSessionSize);
      final session = pool.take(math.min(size, pool.length)).toList();

      setState(() {
        _queue
          ..clear()
          ..addAll(session);
        _sessionSize = session.length;
        _loading = false;
        if (session.isEmpty) {
          _error = 'Bu seviyede cümle yok';
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

  void _onDidNotKnow() {
    final card = _current;
    if (card == null || _busy) return;

    final misses = (_missCounts[card.id] ?? 0) + 1;
    _missCounts[card.id] = misses;
    _didNotKnow += 1;
    _queue.removeAt(0);

    // Re-queue a few cards later, unless we've already retried enough.
    if (misses < _maxRequeuesPerCard) {
      final insertAt = math.min(2, _queue.length);
      _queue.insert(insertAt, card);
    }

    setState(() {
      _flipped = false;
      if (_queue.isEmpty) _finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Flashcard'),
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
                    ? _SessionSummary(
                        knew: _knew,
                        didNotKnow: _didNotKnow,
                        sessionSize: _sessionSize,
                        onDone: () => Navigator.of(context).pop(),
                      )
                    : _SessionBody(
                        current: _current!,
                        isRetry: (_missCounts[_current!.id] ?? 0) > 0,
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

class _SessionBody extends StatelessWidget {
  const _SessionBody({
    required this.current,
    required this.isRetry,
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
  final bool isRetry;
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
              Text(
                '$knew / $sessionSize',
                style: AppTextStyles.labelLarge,
              ),
              const Spacer(),
              Text(
                'Kalan $remaining',
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
          const SizedBox(height: 24),
          Expanded(
            child: _FlipCard(
              key: ValueKey('${current.id}-$isRetry'),
              flipped: flipped,
              isRetry: isRetry,
              english: current.englishText,
              turkish: current.turkishText,
              onTap: onFlip,
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

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    super.key,
    required this.flipped,
    required this.isRetry,
    required this.english,
    required this.turkish,
    required this.onTap,
  });

  final bool flipped;
  final bool isRetry;
  final String english;
  final String turkish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: 320.ms,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: math.pi / 2, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotate.value),
                child: child,
              );
            },
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        child: _CardFace(
          key: ValueKey(flipped),
          label: flipped ? 'Türkçe' : 'English',
          text: flipped ? turkish : english,
          textStyle: flipped
              ? AppTextStyles.translationText
              : AppTextStyles.sentenceText,
          accent: flipped ? AppColors.primaryDark : AppColors.warning,
          isRetry: isRetry,
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.label,
    required this.text,
    required this.textStyle,
    required this.accent,
    required this.isRetry,
  });

  final String label;
  final String text;
  final TextStyle textStyle;
  final Color accent;
  final bool isRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRetry
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.cardBorder,
          width: isRetry ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(color: accent),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  text,
                  style: textStyle.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (isRetry)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.replay_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tekrar',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({
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
              )
              .then(delay: 80.ms)
              .shake(hz: 2.5, rotation: 0.03, duration: 420.ms),
          const SizedBox(height: 16),
          Text('Harika iş!', style: AppTextStyles.headlineLarge)
              .animate()
              .fadeIn(delay: 120.ms, duration: 280.ms),
          const SizedBox(height: 8),
          Text(
            'Tilki seni tebrik ediyor — $sessionSize kartlık pratik tamam.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _SummaryRow(label: 'Bildim', value: '$knew', color: AppColors.primaryDark),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Bilemedim (deneme)',
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
