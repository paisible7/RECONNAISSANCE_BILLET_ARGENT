import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check available languages (debugging only)
      final languages = await _flutterTts.getLanguages;
      debugPrint('🔊 TTS Languages disponibles: $languages');

      // Force French language regardless of what getLanguages returns
      // (sometimes getLanguages is empty or incomplete on Android)
      await _flutterTts.setLanguage('fr-FR');
      debugPrint('🔊 TTS Langue forcée: fr-FR');

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set up handlers for debugging
      _flutterTts.setStartHandler(() {
        debugPrint('🔊 TTS Started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('🔊 TTS Completed');
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('❌ TTS Error: $msg');
      });

      _isInitialized = true;
      debugPrint('✅ TTS Service initialized');
    } catch (e) {
      debugPrint('❌ TTS Init error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    debugPrint('🔊 TTS Speaking: $text');
    
    // Stop any current speech first
    await _flutterTts.stop();
    
    final result = await _flutterTts.speak(text);
    debugPrint('🔊 TTS speak() result: $result');
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
