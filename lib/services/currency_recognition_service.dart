import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:ningapi/models/recognition_result.dart';

class CurrencyRecognitionService {
  static final CurrencyRecognitionService _instance = CurrencyRecognitionService._internal();
  factory CurrencyRecognitionService() => _instance;
  CurrencyRecognitionService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Taille d'entrée du modèle (sera mise à jour dynamiquement)
  int _inputSize = 250; 
  static const int numChannels = 3;
  
  /// Initialise le modèle et charge les labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      print('✅ Modèle TFLite chargé');

      // Détection dynamique de la taille d'entrée
      final inputTensor = _interpreter!.getInputTensor(0);
      _inputSize = inputTensor.shape[1]; // [1, height, width, 3] -> on prend height (ou width, supposé carré)
      print('📏 Taille d\'entrée détectée: $_inputSize x $_inputSize');

      // Labels spécifiques au nouveau modèle (ordre alphabétique / défini par l'entraînement)
      _labels = [
        '1\$', '10\$', '100\$', 
        '10000FC', '1000FC', '100FC', 
        '20\$', '20000FC', '200FC', 
        '5\$', '50\$', 
        '5000FC', '500FC', '50FC'
      ];
      print('✅ Labels chargés en mémoire: $_labels');

      _isInitialized = true;
    } catch (e) {
      print('❌ Erreur d\'initialisation: $e');
      rethrow;
    }
  }

  /// Effectue la reconnaissance de billet sur une image
  Future<CurrencyResult> recognizeCurrency(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final processedImage = await _preprocessImage(imageFile);
      final input = [processedImage];
      final output = List.filled(1, List.filled(_labels.length, 0.0)).cast<List<double>>();

      _interpreter!.run(input, output);

      final probabilities = output[0];
      
      int maxIndex = 0;
      double maxProb = probabilities[0];
      print('🔍 Probabilités: $probabilities');

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      print('🏆 Résultat: ${_labels[maxIndex]} ($maxProb)');

      final allProbs = <String, double>{};
      for (int i = 0; i < _labels.length; i++) {
        allProbs[_labels[i]] = probabilities[i];
      }

      // Parse denomination and currency from label (e.g., "1000 FC" or "20 USD")
      final label = _labels[maxIndex];
      String currency = 'FC';
      if (label.toUpperCase().contains('USD') || label.contains('\$')) {
        currency = 'USD';
      }

      return CurrencyResult(
        denomination: label,
        currency: currency,
        confidence: maxProb,
        timestamp: DateTime.now(),
        allProbabilities: allProbs,
      );
    } catch (e) {
      print('❌ Erreur lors de la reconnaissance: $e');
      rethrow;
    }
  }

  Future<List<List<List<double>>>> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Impossible de décoder l\'image');
    }

    // Corriger l'orientation (EXIF)
    image = img.bakeOrientation(image);


    img.Image resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    List<List<List<double>>> processedImage = List.generate(
      _inputSize,
      (y) => List.generate(
        _inputSize,
        (x) {
          final pixel = resized.getPixel(x, y);
          // Normalisation [0, 1] pour correspondre au script d'entraînement (Rescaling 1./255)
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        },
      ),
    );

    return processedImage;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
