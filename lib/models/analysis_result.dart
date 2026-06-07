class SkinScores {
  final double hydration;
  final double wrinkles;
  final double pores;
  final double spots;
  final double texture;
  final double acne;
  final double elasticity;
  final double darkCircles;

  SkinScores({
    this.hydration = 0,
    this.wrinkles = 0,
    this.pores = 0,
    this.spots = 0,
    this.texture = 0,
    this.acne = 0,
    this.elasticity = 0,
    this.darkCircles = 0,
  });

  factory SkinScores.fromJson(Map<String, dynamic> json) {
    return SkinScores(
      hydration: (json['hydration'] as num?)?.toDouble() ?? 0,
      wrinkles: (json['wrinkles'] as num?)?.toDouble() ?? 0,
      pores: (json['pores'] as num?)?.toDouble() ?? 0,
      spots: (json['spots'] as num?)?.toDouble() ?? 0,
      texture: (json['texture'] as num?)?.toDouble() ?? 0,
      acne: (json['acne'] as num?)?.toDouble() ?? 0,
      elasticity: (json['elasticity'] as num?)?.toDouble() ?? 0,
      darkCircles: (json['dark_circles'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hydration': hydration,
      'wrinkles': wrinkles,
      'pores': pores,
      'spots': spots,
      'texture': texture,
      'acne': acne,
      'elasticity': elasticity,
      'dark_circles': darkCircles,
    };
  }

  double get average {
    final values = [
      hydration,
      wrinkles,
      pores,
      spots,
      texture,
      acne,
      elasticity,
      darkCircles,
    ];
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, double> toMap() {
    return {
      'hydration': hydration,
      'wrinkles': wrinkles,
      'pores': pores,
      'spots': spots,
      'texture': texture,
      'acne': acne,
      'elasticity': elasticity,
      'dark_circles': darkCircles,
    };
  }
}

class ProductRecommendation {
  final String productId;
  final String reason;
  final int priority;

  ProductRecommendation({
    required this.productId,
    required this.reason,
    required this.priority,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      productId: json['product_id'] as String,
      reason: json['reason'] as String,
      priority: json['priority'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {'product_id': productId, 'reason': reason, 'priority': priority};
  }
}

class SpectrumImage {
  final String label;
  final String url;

  SpectrumImage({required this.label, required this.url});

  factory SpectrumImage.fromJson(Map<String, dynamic> json) {
    return SpectrumImage(
      label: json['label'] as String? ?? 'Scanner',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'url': url,
    };
  }
}

class AnalysisResult {
  final String id;
  final String? rapportRaw;
  final String rapportSource;
  final String? clientName;
  final int? clientAge;
  final int? skinAge;
  final String skinType;
  final SkinScores skinScores;
  final List<String> concerns;
  final String summary;
  final List<ProductRecommendation> recommendations;
  final String? routineSuggestion;
  final String? faceImage;
  final List<SpectrumImage> spectrumImages;
  final DateTime createdAt;

  AnalysisResult({
    required this.id,
    this.rapportRaw,
    this.rapportSource = 'M7',
    this.clientName,
    this.clientAge,
    this.skinAge,
    required this.skinType,
    required this.skinScores,
    this.concerns = const [],
    required this.summary,
    this.recommendations = const [],
    this.routineSuggestion,
    this.faceImage,
    this.spectrumImages = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final aiAnalysis = json['ai_analysis'] as Map<String, dynamic>? ?? {};

    return AnalysisResult(
      id: json['id'] as String,
      rapportRaw: json['rapport_raw'] as String?,
      rapportSource: json['rapport_source'] as String? ?? 'M7',
      clientName: json['client_name'] as String?,
      clientAge: json['client_age'] as int?,
      skinAge: json['skin_age'] as int?,
      skinType:
          aiAnalysis['skin_type'] as String? ??
          json['skin_type'] as String? ??
          'Desconhecido',
      skinScores: json['skin_scores'] != null
          ? SkinScores.fromJson(json['skin_scores'] as Map<String, dynamic>)
          : SkinScores(),
      concerns: aiAnalysis['concerns'] != null
          ? List<String>.from(aiAnalysis['concerns'] as List)
          : [],
      summary: aiAnalysis['summary'] as String? ?? '',
      recommendations: aiAnalysis['recommendations'] != null
          ? (aiAnalysis['recommendations'] as List)
                .map(
                  (r) =>
                      ProductRecommendation.fromJson(r as Map<String, dynamic>),
                )
                .toList()
          : [],
      routineSuggestion: aiAnalysis['routine_suggestion'] as String?,
      faceImage: aiAnalysis['face_image_url'] as String?,
      spectrumImages: aiAnalysis['spectrum_images'] != null
          ? (aiAnalysis['spectrum_images'] as List)
              .map((item) => SpectrumImage.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList()
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rapport_raw': rapportRaw,
      'rapport_source': rapportSource,
      'client_name': clientName,
      'client_age': clientAge,
      'skin_age': skinAge,
      'skin_type': skinType,
      'skin_scores': skinScores.toJson(),
      'ai_analysis': {
        'skin_type': skinType,
        'concerns': concerns,
        'summary': summary,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'routine_suggestion': routineSuggestion,
        'face_image_url': faceImage,
        'spectrum_images': spectrumImages.map((s) => s.toJson()).toList(),
      },
      'recommended_product_ids': recommendations
          .map((r) => r.productId)
          .toList(),
    };
  }

  /// Parses GPT JSON response into an AnalysisResult
  factory AnalysisResult.fromGptResponse(
    String rawRapport,
    Map<String, dynamic> gptJson,
  ) {
    return AnalysisResult(
      id: '',
      rapportRaw: rawRapport,
      rapportSource: 'M7',
      clientName: gptJson['client_name'] as String?,
      clientAge: gptJson['client_age'] as int?,
      skinAge: gptJson['skin_age'] as int?,
      skinType: gptJson['skin_type'] as String? ?? 'Desconhecido',
      skinScores: gptJson['skin_scores'] != null
          ? SkinScores.fromJson(gptJson['skin_scores'] as Map<String, dynamic>)
          : SkinScores(),
      concerns: gptJson['concerns'] != null
          ? List<String>.from(gptJson['concerns'] as List)
          : [],
      summary: gptJson['summary'] as String? ?? '',
      recommendations: gptJson['recommendations'] != null
          ? (gptJson['recommendations'] as List)
                .map(
                  (r) =>
                      ProductRecommendation.fromJson(r as Map<String, dynamic>),
                )
                .toList()
          : [],
      routineSuggestion: gptJson['routine_suggestion'] as String?,
      faceImage: gptJson['face_image_url'] as String?,
      spectrumImages: const [],
    );
  }
}
