import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sentence.dart';
import '../../models/sentence_review.dart';
import '../../providers/audio_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/review_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/speak_button.dart';

class SentenceDetailScreen extends ConsumerStatefulWidget {
  const SentenceDetailScreen({
    super.key,
    required this.sentence,
  });

  final Sentence sentence;

  @override
  ConsumerState<SentenceDetailScreen> createState() =>
      _SentenceDetailScreenState();
}

class _SentenceDetailScreenState extends ConsumerState<SentenceDetailScreen> {
  SentenceReview? _review;
  bool _loadingReview = true;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadReview);
  }

  @override
  void deactivate() {
    ref.read(audioServiceProvider).stop();
    super.deactivate();
  }

  Future<void> _loadReview() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      setState(() {
        _loadingReview = false;
        _review = null;
      });
      return;
    }

    try {
      final review = await ref
          .read(reviewRepositoryProvider)
          .getReview(user.uid, widget.sentence.id);
      if (!mounted) return;
      setState(() {
        _review = review;
        _loadingReview = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        _reviewError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentence;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cümle detayı'),
        actions: [
          SpeakButton(text: sentence.englishText),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'Seviye ${sentence.level}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'English',
            titleColor: AppColors.warning,
            child: Text(
              sentence.englishText,
              style: AppTextStyles.sentenceText.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Türkçe',
            titleColor: AppColors.primaryDark,
            child: Text(
              sentence.turkishText,
              style: AppTextStyles.translationText.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Not / örnek',
            titleColor: AppColors.textSecondary,
            child: Text(
              'Bu cümle için ek not henüz yok.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Tekrar (SRS)',
            titleColor: AppColors.textPrimary,
            child: _loadingReview
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(color: AppColors.primary),
                  )
                : _reviewError != null
                    ? Text(
                        'SRS yüklenemedi: $_reviewError',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      )
                    : _review == null
                        ? Text(
                            'Henüz SRS kaydı yok. Flashcard veya Quiz’de cevaplayınca oluşur.',
                            style: AppTextStyles.bodyMedium,
                          )
                        : Column(
                            children: [
                              _SrsRow(
                                label: 'Sonraki tekrar',
                                value: _formatDate(_review!.dueAt),
                              ),
                              const SizedBox(height: 10),
                              _SrsRow(
                                label: 'Ease factor',
                                value: _review!.easeFactor.toStringAsFixed(2),
                              ),
                              const SizedBox(height: 10),
                              _SrsRow(
                                label: 'Tekrar sayısı',
                                value: '${_review!.repetitions}',
                              ),
                              const SizedBox(height: 10),
                              _SrsRow(
                                label: 'Aralık (gün)',
                                value: '${_review!.intervalDays}',
                              ),
                              const SizedBox(height: 10),
                              _SrsRow(
                                label: 'Lapses',
                                value: '${_review!.lapses}',
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.titleColor,
    required this.child,
  });

  final String title;
  final Color titleColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(color: titleColor),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SrsRow extends StatelessWidget {
  const _SrsRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Text(value, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

Future<void> openSentenceDetail(
  BuildContext context,
  Sentence sentence,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SentenceDetailScreen(sentence: sentence),
    ),
  );
}
