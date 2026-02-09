import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ningapi/app_colors.dart';
import 'package:ningapi/models/recognition_result.dart';
import 'package:ningapi/services/tts_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ningapi/scanning_screen.dart';

class ResultsScreen extends StatefulWidget {
  final File imageFile;
  final CurrencyResult currencyResult;

  const ResultsScreen({
    super.key,
    required this.imageFile,
    required this.currencyResult,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TtsService _tts = TtsService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Delai pour laisser la navigation se terminer (augmente a 600ms pour eviter conflit avec dispose)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_isDisposed && mounted) {
        _announceResult();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tts.stop();
    super.dispose();
  }

  Future<void> _announceResult() async {
    if (_isSpeaking || _isDisposed) return;
    _isSpeaking = true;

    try {
      // Annoncer le resultat et attendre la fin
      await _tts.speak(widget.currencyResult.speakableResult);

      if (_isDisposed || !mounted) return;

      // Attendre un peu puis annoncer l'aide (800ms est suffisant car speak attend deja la fin)
      await Future.delayed(const Duration(milliseconds: 800));

      if (_isDisposed || !mounted) return;

      await _tts.speak("Appuyez pour répéter. Balayez pour scanner un autre billet.");
    } finally {
      if (!_isDisposed) {
        _isSpeaking = false;
      }
    }
  }

  Future<void> _repeatResult() async {
    if (_isProcessing || _isSpeaking || _isDisposed) return;

    HapticFeedback.lightImpact();
    _isSpeaking = true;

    try {
      await _tts.speak(widget.currencyResult.speakableResult);
    } finally {
      if (!_isDisposed) {
        _isSpeaking = false;
      }
    }
  }

  Future<void> _scanAgain() async {
    if (_isProcessing || _isDisposed) {
      debugPrint("Scan deja en cours, swipe ignore");
      return;
    }

    _isProcessing = true;
    if (mounted) setState(() {});

    HapticFeedback.mediumImpact();

    try {
      // Arreter le TTS actuel
      await _tts.stop();

      // Utiliser speakAsync car on ne veut pas attendre
      await _tts.speakAsync("Ouverture de la camera");

      // Petit delai pour laisser le TTS commencer
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }

      // Ouvrir directement la camera
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }

      if (pickedFile != null) {
        // Remplacer l'ecran actuel par ScanningScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ScanningScreen(imageFile: File(pickedFile.path)),
          ),
        );
      } else {
        // Utilisateur a annule, rester sur l'ecran des resultats
        _isProcessing = false;
        if (mounted && !_isDisposed) {
          setState(() {});
          await _tts.speak("Scan annule. Balayez pour reessayer.");
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du scan: $e");
      _isProcessing = false;
      if (mounted && !_isDisposed) {
        setState(() {});
        await _tts.speak("Erreur camera. Veuillez reessayer.");
      }
    }
  }

  void _goBack() {
    // Retour a l'ecran d'accueil
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final resultText = widget.currencyResult.isUnknown 
        ? "Inconnu" 
        : widget.currencyResult.denomination;

    final resultSubtext = widget.currencyResult.isUnknown
        ? "Non reconnu"
        : (widget.currencyResult.currency == 'USD' ? "Dollars" : "Francs Congolais");
    
    final color = widget.currencyResult.isUnknown ? Colors.orange : AppColors.accent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: AbsorbPointer(
          absorbing: _isProcessing,
          child: GestureDetector(
            onTap: _repeatResult,
            onVerticalDragEnd: (details) {
              if (!_isProcessing) _scanAgain();
            },
            onHorizontalDragEnd: (details) {
              if (!_isProcessing) _scanAgain();
            },
            child: Semantics(
              label: "$resultText. $resultSubtext",
              hint: "Appuyez pour répéter. Balayez pour scanner un autre billet.",
              button: true,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),

                          // Huge Status Icon
                          Icon(
                            widget.currencyResult.isUnknown
                              ? Icons.help_outline
                              : Icons.check_circle_outline,
                            size: 120,
                            color: color,
                          ),

                          const SizedBox(height: 40),

                          // Huge Result Text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                resultText,
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            resultSubtext,
                            style: TextStyle(
                              fontSize: 30,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          // Bottom Hint Area
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            color: AppColors.backgroundCard,
                            child: Column(
                              children: [
                                Icon(Icons.touch_app, size: 40, color: AppColors.textGray.withOpacity(0.5)),
                                const SizedBox(height: 10),
                                const Text(
                                  "Appuyer pour Répéter",
                                  style: TextStyle(fontSize: 20, color: AppColors.textGray),
                                ),
                                const SizedBox(height: 20),
                                Icon(Icons.swipe, size: 40, color: AppColors.textGray.withOpacity(0.5)),
                                const SizedBox(height: 10),
                                const Text(
                                  "Balayer pour Scanner",
                                  style: TextStyle(fontSize: 20, color: AppColors.textGray),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Loading overlay when processing
                      if (_isProcessing)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
