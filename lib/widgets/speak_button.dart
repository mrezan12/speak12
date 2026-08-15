import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_providers.dart';
import '../theme/app_colors.dart';

/// Compact play control for English sentence TTS.
class SpeakButton extends ConsumerStatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.tooltip = 'Dinle',
  });

  final String text;
  final String tooltip;

  @override
  ConsumerState<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends ConsumerState<SpeakButton> {
  bool _busy = false;

  Future<void> _play() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(audioServiceProvider).speakEnglish(widget.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses oynatılamadı'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _busy ? null : _play,
      icon: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryDark,
              ),
            )
          : const Icon(
              Icons.volume_up_rounded,
              color: AppColors.primaryDark,
            ),
    );
  }
}
