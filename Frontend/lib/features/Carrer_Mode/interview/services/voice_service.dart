import 'dart:ui';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isListening = false;

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  String _lastTranscript = "";

  /// Speak text and wait until completion
  Future<void> speak(String text, VoidCallback onComplete) async {
    _tts.setCompletionHandler(onComplete);
    await _tts.speak(text);
  }

 Future<void> startListening(Function(String) onResult) async {
    final available = await _stt.initialize();
    if (!available) return;

    _lastTranscript = ""; // reset previous answer
    _isListening = true;

    await _stt.listen(
      onResult: (result) {
        _lastTranscript = result.recognizedWords;
        onResult(_lastTranscript); // optional: live preview
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }


  
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }






  /// Stop STT and return final transcript
  Future<String> stopListening() async {
    if (!_isListening) return _lastTranscript;

    _isListening = false;
    await _stt.stop();

    return _lastTranscript.trim();
  }

  bool get isListening => _isListening;
}
