package com.ningapi.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.ningapi.models.CurrencyResult
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.time.LocalDateTime

class CurrencyRecognitionService private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: CurrencyRecognitionService? = null

        fun getInstance(context: Context): CurrencyRecognitionService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: CurrencyRecognitionService(context).also { INSTANCE = it }
            }
        }
        
        private const val TAG = "CurrencyRecognition"
    }

    private var interpreter: Interpreter? = null
    // Labels specifiques au modele (ordre alphabetique comme dans l'entrainement)
    private val labels = listOf(
        "1$", "10$", "100$",
        "10000FC", "1000FC", "100FC",
        "20$", "20000FC", "200FC",
        "5$", "50$",
        "5000FC", "500FC", "50FC"
    )
    
    private var isInitialized = false
    private var inputSize = 224

    suspend fun initialize() {
        if (isInitialized) return

        try {
            // Load model
            // Assuming model.tflite is in assets/models/
            val mappedByteBuffer = FileUtil.loadMappedFile(context, "models/model.tflite")
            interpreter = Interpreter(mappedByteBuffer)
            Log.d(TAG, "Modele TFLite charge")

            // Detection dynamique de la taille d'entree
            val inputTensor = interpreter!!.getInputTensor(0)
            inputSize = inputTensor.shape()[1]
            Log.d(TAG, "Taille entree detectee: $inputSize x $inputSize")
            Log.d(TAG, "Labels charges: $labels")

            isInitialized = true
        } catch (e: Exception) {
            Log.e(TAG, "Erreur initialisation: $e", e)
            throw e
        }
    }

    suspend fun recognizeCurrency(imageFile: File): CurrencyResult {
        if (!isInitialized) {
            initialize()
        }

        try {
            val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                ?: throw Exception("Impossible de decoder image")

            // Preprocess
            val inputBuffer = preprocessImage(bitmap)
            
            // Output buffer: [1, labels.size]
            val outputBuffer = Array(1) { FloatArray(labels.size) }
            
            interpreter!!.run(inputBuffer, outputBuffer)

            val probabilities = outputBuffer[0]
            
            var maxIndex = 0
            var maxProb = probabilities[0]
            
            Log.d(TAG, "Probabilites: ${probabilities.joinToString()}")

            for (i in 1 until probabilities.size) {
                if (probabilities[i] > maxProb) {
                    maxProb = probabilities[i]
                    maxIndex = i
                }
            }

            Log.d(TAG, "Resultat: ${labels[maxIndex]} ($maxProb)")

            val allProbs = mutableMapOf<String, Double>()
            for (i in labels.indices) {
                allProbs[labels[i]] = probabilities[i].toDouble()
            }

            val label = labels[maxIndex]
            var currency = "FC"
            if (label.uppercase().contains("USD") || label.contains("$")) {
                currency = "USD"
            }

            return CurrencyResult(
                denomination = label,
                currency = currency,
                confidence = maxProb.toDouble(),
                timestamp = LocalDateTime.now(),
                allProbabilities = allProbs
            )

        } catch (e: Exception) {
            Log.e(TAG, "Erreur reconnaissance: $e", e)
            throw e
        }
    }

    private fun preprocessImage(bitmap: Bitmap): ByteBuffer {
        // Resize
        val resized = Bitmap.createScaledBitmap(bitmap, inputSize, inputSize, true)

        // Allocate ByteBuffer
        // 4 bytes per float * 3 channels * width * height
        val byteBuffer = ByteBuffer.allocateDirect(4 * 3 * inputSize * inputSize)
        byteBuffer.order(ByteOrder.nativeOrder())

        val intValues = IntArray(inputSize * inputSize)
        resized.getPixels(intValues, 0, resized.width, 0, 0, resized.width, resized.height)

        // Normalize [-1, 1]
        // (pixel / 127.5) - 1.0
        for (pixelValue in intValues) {
            // Extract RGB
            val r = (pixelValue shr 16) and 0xFF
            val g = (pixelValue shr 8) and 0xFF
            val b = pixelValue and 0xFF

            // MobileNetV2 preprocessing
            byteBuffer.putFloat((r / 127.5f) - 1.0f)
            byteBuffer.putFloat((g / 127.5f) - 1.0f)
            byteBuffer.putFloat((b / 127.5f) - 1.0f)
        }
        
        return byteBuffer
    }

    fun dispose() {
        interpreter?.close()
        isInitialized = false
    }
}
