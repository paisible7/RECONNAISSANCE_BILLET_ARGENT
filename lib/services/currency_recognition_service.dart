import 'dart:io';
import 'package:flutter/foundation.dart';
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

  // Taille d'entree du modele (MobileNetV2 utilise 224x224)
  int _inputSize = 224;
  static const int numChannels = 3;
  
  /// Initialise le modele et charge les labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      debugPrint('Modele TFLite charge');

      // Detection dynamique de la taille d'entree
      final inputTensor = _interpreter!.getInputTensor(0);
      _inputSize = inputTensor.shape[1];
      debugPrint('Taille entree detectee: $_inputSize x $_inputSize');

      // Labels specifiques au modele (ordre alphabetique comme dans l'entrainement)
      _labels = [
        '1\$', '10\$', '100\$',
        '10000FC', '1000FC', '100FC',
        '20\$', '20000FC', '200FC',
        '5\$', '50\$',
        '5000FC', '500FC', '50FC'
      ];
      debugPrint('Labels charges: $_labels');

      _isInitialized = true;
    } catch (e) {
      debugPrint('Erreur initialisation: $e');
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
      debugPrint('Probabilites: $probabilities');

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      debugPrint('Resultat: ${_labels[maxIndex]} ($maxProb)');

      final allProbs = <String, double>{};
      for (int i = 0; i < _labels.length; i++) {
        allProbs[_labels[i]] = probabilities[i];
      }

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
      debugPrint('Erreur reconnaissance: $e');
      rethrow;
    }
  }

  Future<List<List<List<double>>>> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Impossible de decoder image');
    }

    // Corriger l'orientation (EXIF)
    image = img.bakeOrientation(image);

    img.Image resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Pretraitement MobileNetV2: normalisation dans [-1, 1]
    // Equivalent de tf.keras.applications.mobilenet_v2.preprocess_input
    // Formule: (pixel / 127.5) - 1.0
    List<List<List<double>>> processedImage = List.generate(
      _inputSize,
      (y) => List.generate(
        _inputSize,
        (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
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
