class CurrencyResult {
  final String denomination; // Ex: "1000 FC", "20 USD"
  final String currency;     // "FC" ou "USD"
  final double confidence;
  final DateTime timestamp;
  final Map<String, double>? allProbabilities;

  CurrencyResult({
    required this.denomination,
    required this.currency,
    required this.confidence,
    required this.timestamp,
    this.allProbabilities,
  });

  bool get isHighConfidence => confidence >= 0.70;
  
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  /// Text for TTS announcement
  /// Texte pour l'annonce vocale TTS
  String get speakableResult {
    String formattedDenomination = denomination;
    
    // Remplacer les symboles par des mots complets en français
    if (formattedDenomination.contains('FC')) {
      formattedDenomination = formattedDenomination.replaceAll('FC', '') + ' Francs Congolais';
    } else if (formattedDenomination.contains('\$') || formattedDenomination.contains('USD')) {
      formattedDenomination = formattedDenomination.replaceAll('\$', '').replaceAll('USD', '') + ' Dollars';
    }

    if (confidence < 0.45) {
      return "Je ne reconnais pas cet objet. Veuillez présenter un billet bien éclairé.";
    }

    if (isHighConfidence) {
      return 'Billet détecté : $formattedDenomination';
    } else {
      return 'Billet probable : $formattedDenomination. Confiance faible.';
    }
  }

  bool get isUnknown => confidence < 0.45;
}
