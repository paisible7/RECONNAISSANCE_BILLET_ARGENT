import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ningapi/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ningapi/services/tts_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'scanning_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool autoStart;
  
  const HomeScreen({super.key, this.autoStart = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _tts = TtsService();
  final ImagePicker _picker = ImagePicker();
  bool _isCameraOpen = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Reinitialiser les flags au demarrage
    _isCameraOpen = false;
    _isNavigating = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.autoStart) {
        // Auto-demarrer le scan sans message de bienvenue
        _startScan();
      } else {
        // Message de bienvenue uniquement au premier lancement
        _tts.speakAsync("Bienvenue sur Ni nghapi. Touchez l'ecran n'importe ou pour scanner un billet.");
      }
    });
  }

  @override
  void dispose() {
    // Arreter le TTS si on quitte l'ecran
    _tts.stop();
    super.dispose();
  }

  Future<void> _startScan() async {
    // Double protection contre les appels multiples
    if (_isCameraOpen || _isNavigating) {
      debugPrint("Scan deja en cours, ignore");
      return;
    }

    _isCameraOpen = true;
    if (mounted) setState(() {});

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Utiliser speakAsync pour ne pas bloquer l'ouverture de la camera
      await _tts.speakAsync("Ouverture de la camera");

      // Petit delai pour laisser le TTS commencer
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) {
        _isCameraOpen = false;
        return;
      }

      // Direct camera launch
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Reinitialiser le flag camera
      _isCameraOpen = false;

      if (pickedFile != null && mounted) {
        _isNavigating = true;

        // Navigate directly to processing
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanningScreen(imageFile: File(pickedFile.path)),
          ),
        );

        // Quand on revient de la navigation, reinitialiser
        if (mounted) {
          _isNavigating = false;
          setState(() {});
        }
      } else if (mounted) {
        await _tts.speakAsync("Aucune photo prise.");
      }
    } catch (e) {
      _isCameraOpen = false;
      _isNavigating = false;
      debugPrint("Error picking image: $e");
      if (mounted) {
        await _tts.speakAsync("Erreur camera. Veuillez reessayer.");
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Material(
        color: Colors.transparent,
        child: Semantics(
          label: "Scanner un billet",
          hint: "Appuyez deux fois pour ouvrir la caméra",
          button: true,
          excludeSemantics: true, // We provide our own label, ignore child texts if redundant or merge them
          child: InkWell(
            onTap: _startScan,
            highlightColor: AppColors.accent.withOpacity(0.2),
            splashColor: AppColors.accent.withOpacity(0.4),
            child: SizedBox.expand(
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     // Huge Icon
                    Container(
                      width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 100,
                      color: AppColors.textLight,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms),

                  const SizedBox(height: 60),

                  // Huge Text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "APPUYER\nPOUR SCANNER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.2,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Hint Text
                  const Text(
                    "Touchez n'importe où",
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
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