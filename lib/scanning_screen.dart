import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ningapi/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ningapi/services/currency_recognition_service.dart';
import 'package:ningapi/services/face_detection_service.dart';
import 'package:ningapi/services/tts_service.dart';
import 'package:ningapi/results_screen.dart';

class ScanningScreen extends StatefulWidget {
  final File imageFile;

  const ScanningScreen({super.key, required this.imageFile});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _tts.speak("Analyse en cours");
    _performRecognition();
  }

  Future<void> _performRecognition() async {
    try {
      // 1. D'abord, vérifier s'il s'agit d'un visage
      final hasFace = await FaceDetectionService().hasFace(widget.imageFile);
      
      if (hasFace) {
        // Si c'est un visage, on avertit l'utilisateur
        await Future.delayed(const Duration(seconds: 1)); // Petit délai pour l'UX
        await _tts.speak("Attention. Ceci n'est pas un billet, c'est un visage. Veuillez scanner un billet.");
        
        if (mounted) {
          // Retour à l'écran précédent après l'annonce
          await Future.delayed(const Duration(seconds: 4)); 
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      // 2. Si pas de visage, on lance la reconnaissance de billet
      final result = await CurrencyRecognitionService().recognizeCurrency(widget.imageFile);
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Navigation avec Navigator au lieu de go_router pour ne pas reconstruire HomeScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              imageFile: widget.imageFile,
              currencyResult: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await _tts.speak("Erreur lors de l'analyse. Veuillez réessayer.");
        debugPrint('Erreur: $e');
        Navigator.pop(context); // Return to Home
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Image with scan effect
              Container(
                constraints: const BoxConstraints(maxWidth: 320, maxHeight: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),

                    // Light overlay
                    Container(color: Colors.white.withOpacity(0.1)),

                    // Turquoise scan line
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: 420 * _animation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.accent,
                                  AppColors.accentLight,
                                  AppColors.accent,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent,
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 50),

              // Status card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Animated icon
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: AppColors.textLight, size: 28),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 600.ms)
                        .then()
                        .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 600.ms),

                    const SizedBox(height: 20),

                    const Text(
                      "Analyse...",
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Veuillez patienter",
                      style: TextStyle(color: AppColors.textGray, fontSize: 18),
                    ),
                    const SizedBox(height: 32),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: AppColors.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        value: null,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Cancel
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Annuler",
                  style: TextStyle(color: AppColors.textGray, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
