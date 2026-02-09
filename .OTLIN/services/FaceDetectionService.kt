package com.ningapi.services

import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import java.io.File
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class FaceDetectionService private constructor() {

    companion object {
        private const val TAG = "FaceDetectionService"
        
        @Volatile
        private var INSTANCE: FaceDetectionService? = null

        fun getInstance(): FaceDetectionService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: FaceDetectionService().also { INSTANCE = it }
            }
        }
    }

    private val faceDetector: FaceDetector

    init {
        val options = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .build()
        
        faceDetector = FaceDetection.getClient(options)
    }

    /**
     * Returns true if a face is detected in the image
     */
    suspend fun hasFace(context: Context, imageFile: File): Boolean {
        return suspendCoroutine { continuation ->
            try {
                val inputImage = InputImage.fromFilePath(context, Uri.fromFile(imageFile))
                
                faceDetector.process(inputImage)
                    .addOnSuccessListener { faces ->
                        continuation.resume(faces.isNotEmpty())
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "Erreur detection visage: $e", e)
                        continuation.resume(false)
                    }
            } catch (e: IOException) {
                Log.e(TAG, "Erreur detection visage: $e", e)
                continuation.resume(false)
            }
        }
    }

    fun dispose() {
        faceDetector.close()
    }
}
