import 'package:flutter_tts/flutter_tts.dart';

/// Speaks English sentence text via on-device TTS.
/// Later: try `just_audio` assets first, fall back to TTS.
class AudioService {
  AudioService() {
    _tts = FlutterTts();
    _ready = _configure();
  }

  late final FlutterTts _tts;
  late final Future<void> _ready;
  bool _disposed = false;

  Future<void> _configure() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speakEnglish(String text) async {
    if (_disposed) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _ready;
    if (_disposed) return;

    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore stop errors during teardown.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
