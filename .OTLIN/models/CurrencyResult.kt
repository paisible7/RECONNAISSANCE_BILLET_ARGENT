package com.ningapi.models

import java.io.Serializable
import java.time.LocalDateTime

data class CurrencyResult(
    val denomination: String, // Ex: "1000 FC", "20 USD"
    val currency: String,     // "FC" or "USD"
    val confidence: Double,
    val timestamp: LocalDateTime,
    val allProbabilities: Map<String, Double>? = null
) {
    val isHighConfidence: Boolean
        get() = confidence >= 0.70

    val confidencePercentage: String
        get() = String.format("%.1f%%", confidence * 100)

    // Text for TTS announcement
    // Texte pour l'annonce vocale TTS
    val speakableResult: String
        get() {
            var formattedDenomination = denomination

            // Replace symbols with full words in French
            if (formattedDenomination.contains("FC")) {
                formattedDenomination = formattedDenomination.replace("FC", "") + " Francs Congolais"
            } else if (formattedDenomination.contains("$") || formattedDenomination.contains("USD")) {
                formattedDenomination = formattedDenomination.replace("$", "").replace("USD", "") + " Dollars"
            }

            if (isUnknown) {
                return "Je ne reconnais pas cet objet. Veuillez présenter un billet bien éclairé."
            }

            return if (isHighConfidence) {
                "Billet détecté : $formattedDenomination"
            } else {
                "Billet probable : $formattedDenomination. Confiance faible."
            }
        }

    val isUnknown: Boolean
        get() = confidence < 0.45
} : Serializable
