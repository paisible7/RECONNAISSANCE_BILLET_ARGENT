import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ningapi/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoStart) {
        // Auto-démarrer le scan sans message de bienvenue
        _startScan();
      } else {
        // Message de bienvenue uniquement au premier lancement
        _tts.speak("Bienvenue sur Ni nghapi. Touchez l'écran n'importe où pour scanner un billet.");
      }
    });
  }



  Future<void> _startScan() async {
    if (_isCameraOpen) return;
    _isCameraOpen = true;

    // Haptic feedback
    HapticFeedback.mediumImpact();
    await _tts.speak("Ouverture de la caméra");

    try {
      // Direct camera launch
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      _isCameraOpen = false;

      if (pickedFile != null) {
        if (mounted) {
          // Navigate directly to processing
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanningScreen(imageFile: File(pickedFile.path)),
            ),
          );
        }
      } else {
        await _tts.speak("Aucune photo prise.");
      }
    } catch (e) {
      _isCameraOpen = false;
      debugPrint("Error picking image: $e");
      await _tts.speak("Erreur caméra.");
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