import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  Completer<void>? _speakCompleter;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final languages = await _flutterTts.getLanguages;
      debugPrint('TTS Languages disponibles: $languages');

      await _flutterTts.setLanguage('fr-FR');
      debugPrint('TTS Langue forcee: fr-FR');

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Activer l'attente de completion
      await _flutterTts.awaitSpeakCompletion(true);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS Started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS Completed');
        _speakCompleter?.complete();
        _speakCompleter = null;
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('TTS Cancelled');
        _speakCompleter?.complete();
        _speakCompleter = null;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
        _speakCompleter?.completeError(msg);
        _speakCompleter = null;
      });

      _isInitialized = true;
      debugPrint('TTS Service initialized');
    } catch (e) {
      debugPrint('TTS Init error: $e');
    }
  }

  /// Parle le texte et attend la fin de l'annonce
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
      // Si toujours pas initialise apres tentative, on abandonne (ou on log)
      if (!_isInitialized) {
        debugPrint('TTS Erreur: Impossible d\'initialiser le service avant speak');
        return;
      }
    }
    
    debugPrint('TTS Speaking: $text');

    // Arreter toute parole en cours
    await stop();

    // Petit delai pour s'assurer que stop est termine
    await Future.delayed(const Duration(milliseconds: 50));

    _isSpeaking = true;
    _speakCompleter = Completer<void>();

    try {
      await _flutterTts.speak(text);
      // Attendre la fin de la parole
      await _speakCompleter?.future;
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  /// Parle le texte sans attendre (fire and forget)
  Future<void> speakAsync(String text) async {
    if (!_isInitialized) await initialize();

    debugPrint('TTS Speaking async: $text');

    await stop();
    await Future.delayed(const Duration(milliseconds: 50));

    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    try {
      if (_isSpeaking || _speakCompleter != null) {
        await _flutterTts.stop();
        _isSpeaking = false;
        _speakCompleter?.complete();
        _speakCompleter = null;
        debugPrint('TTS Stopped');
      }
    } catch (e) {
      debugPrint('TTS Stop Error: $e');
    }
  }

  bool get isSpeaking => _isSpeaking;
}
