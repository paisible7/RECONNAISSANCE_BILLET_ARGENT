import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ningapi/app_colors.dart';
import 'package:ningapi/models/recognition_result.dart';
import 'package:ningapi/services/tts_service.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _announceResult();
  }

  Future<void> _announceResult() async {
    // If unknown, slightly different message or behavior
    // But speakableResult handles it
    await _tts.speak(widget.currencyResult.speakableResult);
    
    // Hint for interaction
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
       await _tts.speak("Appuyez pour répéter. Balayez pour terminer.");
    }
  }

  void _scanAgain() {
    // Utiliser un timestamp unique pour forcer la reconstruction de HomeScreen
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    context.go('/?autoStart=true&t=$timestamp');
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
        _scanAgain();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: GestureDetector(
          onTap: () {
            // Tap anywhere to repeat
            _tts.speak(widget.currencyResult.speakableResult);
          },
          onVerticalDragEnd: (details) {
              _scanAgain();
          },
          onHorizontalDragEnd: (details) {
              _scanAgain();
          },
          child: Semantics(
            label: "$resultText. $resultSubtext",
            hint: "Appuyez pour répéter. Balayez pour scanner un autre billet.",
            button: true,
            child: Container(
              color: Colors.transparent, // Capture taps
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: Column(
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
            ),
          ),
        ),
        ),
      ),
    );
  }
}
