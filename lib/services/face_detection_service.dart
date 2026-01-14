import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  static final FaceDetectionService _instance = FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;
  FaceDetectionService._internal();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast, // We just want to know if there is a face
    ),
  );

  /// Returns true if a face is detected in the image
  Future<bool> hasFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      print('❌ Erreur détection visage: $e');
      return false; // Assume no face on error to allow currency detection to proceed
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
