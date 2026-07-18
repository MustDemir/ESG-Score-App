enum ProductType { food, clothing, cosmetics }

class ScanFairProduct {
  const ScanFairProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageEmoji,
    required this.productType,
    this.ecoscoreGrade,
    this.ecoscoreScore,
    this.co2Total,
    this.ingredientsText,
    this.secondaryTitle = 'Gesundheit',
    this.secondaryLabel = 'zur Information',
    this.secondaryFacts = 'Zusatzhinweis, kein Teil des ESG-Scores.',
    this.secondaryPosition = 5,
    this.packagingTags = const [],
    this.originTags = const [],
    this.labelsTags = const [],
    this.dataQualityTags = const [],
    this.dataQualityWarnings = const [],
  });

  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String imageEmoji;
  final ProductType productType;
  final String? ecoscoreGrade;
  final double? ecoscoreScore;
  final double? co2Total;
  final String? ingredientsText;
  final String secondaryTitle;
  final String secondaryLabel;
  final String secondaryFacts;
  final double secondaryPosition;
  final List<String> packagingTags;
  final List<String> originTags;
  final List<String> labelsTags;
  final List<String> dataQualityTags;
  final List<String> dataQualityWarnings;

  bool get hasEnvironmentalSignal =>
      ecoscoreScore != null ||
      (ecoscoreGrade != null && ecoscoreGrade!.trim().isNotEmpty);

  bool get hasSocialSignal =>
      labelsTags.isNotEmpty ||
      originTags.isNotEmpty ||
      (ingredientsText != null && ingredientsText!.trim().isNotEmpty);

  bool get hasGovernanceSignal =>
      brand.trim().isNotEmpty ||
      dataQualityTags.isNotEmpty ||
      dataQualityWarnings.isNotEmpty ||
      (ingredientsText != null && ingredientsText!.trim().isNotEmpty);

  factory ScanFairProduct.fromOpenFoodFactsJson(
    Map<String, Object?> json, {
    required String barcode,
  }) {
    final product = json['product'];
    final productMap = product is Map<String, Object?> ? product : json;

    return ScanFairProduct(
      barcode: barcode,
      name: _string(
        productMap['product_name'],
        fallback: 'Unbenanntes Produkt',
      ),
      brand: _string(productMap['brands'], fallback: 'Unbekannte Marke'),
      category: _firstTag(productMap['categories_tags']) ?? 'Lebensmittel',
      imageEmoji: '□',
      productType: ProductType.food,
      ecoscoreGrade: _nullableString(
        productMap['environmental_score_grade'] ?? productMap['ecoscore_grade'],
      ),
      ecoscoreScore: _double(
        productMap['environmental_score_score'] ?? productMap['ecoscore_score'],
      ),
      co2Total:
          _doubleFromPath(productMap, [
            'environmental_score_data',
            'agribalyse',
            'co2_total',
          ]) ??
          _doubleFromPath(productMap, [
            'ecoscore_data',
            'agribalyse',
            'co2_total',
          ]),
      ingredientsText: _nullableString(productMap['ingredients_text']),
      packagingTags: _stringList(productMap['packaging_tags']),
      originTags: _stringList(productMap['origins_tags']),
      labelsTags: _stringList(productMap['labels_tags']),
      dataQualityTags: _stringList(productMap['data_quality_tags']),
      dataQualityWarnings: _stringList(
        productMap['data_quality_warnings_tags'],
      ),
    );
  }

  static String _string(Object? value, {required String fallback}) {
    final parsed = _nullableString(value);
    return parsed == null || parsed.isEmpty ? fallback : parsed;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((entry) => entry.toString().toLowerCase()).toList();
    }
    final text = _nullableString(value);
    if (text == null) return const [];
    return text
        .split(',')
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static String? _firstTag(Object? value) {
    final tags = _stringList(value);
    if (tags.isEmpty) return null;
    return tags.first.replaceAll('en:', '').replaceAll('-', ' ');
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double? _doubleFromPath(
    Map<String, Object?> map,
    List<String> segments,
  ) {
    Object? current = map;
    for (final segment in segments) {
      if (current is! Map<String, Object?>) return null;
      current = current[segment];
    }
    return _double(current);
  }
}
