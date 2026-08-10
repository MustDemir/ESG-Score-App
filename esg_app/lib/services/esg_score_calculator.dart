import '../models/esg_score.dart';
import '../models/product.dart';

class ESGScoreCalculator {
  const ESGScoreCalculator();

  static const _environmentWeight = 0.50;
  static const _socialWeight = 0.30;
  static const _governanceWeight = 0.20;

  ESGScore calculate(ScanFairProduct product) {
    final environmental = _calculateEnvironmental(product);
    final social = _calculateSocial(product);
    final governance = _calculateGovernance(product);
    final pillars = [environmental, social, governance].nonNulls.toList();
    final completeness = pillars.length / 3;

    if (environmental == null) {
      return ESGScore(
        state: ScoreState.dataIncomplete,
        dataCompleteness: completeness,
        social: social,
        governance: governance,
        sources: _scoreSources(product),
      );
    }

    final total = _weightedAverage(
      environmental: environmental,
      social: social,
      governance: governance,
    );

    return ESGScore(
      state: total == null ? ScoreState.dataIncomplete : ScoreState.fullScore,
      environmental: environmental,
      social: social,
      governance: governance,
      total: total,
      dataCompleteness: completeness,
      sources: _scoreSources(product),
    );
  }

  PillarScore? _calculateEnvironmental(ScanFairProduct product) {
    final rawScore =
        product.ecoscoreScore ?? _mapEcoGrade(product.ecoscoreGrade);
    if (rawScore == null) {
      return null;
    }

    return PillarScore(
      pillar: ScorePillar.environmental,
      value: _clamp(rawScore),
      label: 'Environmental',
      factors: [
        ScoreFactor(
          label: 'Eco-Score',
          value: product.ecoscoreScore != null
              ? '${product.ecoscoreScore!.round()} von 100'
              : 'Grad ${product.ecoscoreGrade!.toUpperCase()}',
          source: 'Open Food Facts',
          available: true,
          evidenceIds: _evidenceIds(product, 'environmental_score'),
        ),
        ScoreFactor(
          label: 'Verpackung',
          value: product.packagingTags.isEmpty
              ? 'Keine Daten'
              : product.packagingTags.join(', '),
          source: 'Open Food Facts',
          available: product.packagingTags.isNotEmpty,
          evidenceIds: _evidenceIds(product, 'packaging'),
        ),
        ScoreFactor(
          label: 'Herkunft',
          value: product.originTags.isEmpty
              ? 'Keine Daten'
              : product.originTags.join(', '),
          source: 'Open Food Facts',
          available: product.originTags.isNotEmpty,
          evidenceIds: _evidenceIds(product, 'origin'),
        ),
      ],
    );
  }

  PillarScore? _calculateSocial(ScanFairProduct product) {
    if (!product.hasSocialSignal) return null;

    var score = 50.0;
    final tags = _normalizedTags(product);
    final ingredients = product.ingredientsText?.toLowerCase() ?? '';
    final factors = <ScoreFactor>[];

    if (_containsAny(tags, ['fair-trade', 'fairtrade', 'gepa'])) {
      score += 25;
      factors.add(
        ScoreFactor(
          label: 'Fair-Trade-Signal',
          value: '+25',
          source: 'Open Food Facts · Kennzeichnungen',
          available: true,
          evidenceIds: _evidenceIds(product, 'labels'),
        ),
      );
    }

    if (_containsAny(tags, ['organic', 'bio', 'eu-organic', 'demeter'])) {
      score += 20;
      factors.add(
        ScoreFactor(
          label: 'Bio-Siegel',
          value: '+20',
          source: 'Open Food Facts · Kennzeichnungen',
          available: true,
          evidenceIds: _evidenceIds(product, 'labels'),
        ),
      );
    }

    if (_containsAny(tags, ['vegan', 'vegetarian'])) {
      score += 10;
      factors.add(
        ScoreFactor(
          label: 'Vegan/Vegetarisch',
          value: '+10',
          source: 'Open Food Facts · Kennzeichnungen',
          available: true,
          evidenceIds: _evidenceIds(product, 'labels'),
        ),
      );
    }

    if (_containsAny(tags, [
      'germany',
      'deutschland',
      'austria',
      'switzerland',
      'european-union',
    ])) {
      score += 15;
      factors.add(
        ScoreFactor(
          label: 'Regionale/EU-Herkunft',
          value: '+15',
          source: 'Open Food Facts · Herkunft',
          available: true,
          evidenceIds: _evidenceIds(product, 'origin'),
        ),
      );
    }

    if (_containsAny(tags, ['rainforest-alliance', 'utz'])) {
      score += 20;
      factors.add(
        ScoreFactor(
          label: 'Sozial-/Anbaustandard',
          value: '+20',
          source: 'Open Food Facts · Kennzeichnungen',
          available: true,
          evidenceIds: _evidenceIds(product, 'labels'),
        ),
      );
    }

    if (ingredients.contains('palm') &&
        !_containsAny(tags, ['rspo-certified', 'rspo'])) {
      score -= 15;
      factors.add(
        ScoreFactor(
          label: 'Palmöl ohne RSPO-Signal',
          value: '-15',
          source: 'Open Food Facts · Zutaten',
          available: true,
          evidenceIds: _evidenceIds(product, 'ingredients'),
        ),
      );
    }

    if (factors.isEmpty) {
      factors.add(
        const ScoreFactor(
          label: 'Soziale Signale',
          value: 'Neutraler Startwert',
          source: 'ScanFair Methodik v1.0',
          available: true,
        ),
      );
    }

    return PillarScore(
      pillar: ScorePillar.social,
      value: _clamp(score),
      label: 'Social',
      factors: factors,
    );
  }

  PillarScore? _calculateGovernance(ScanFairProduct product) {
    if (!product.hasGovernanceSignal) return null;

    var score = 50.0;
    final factors = <ScoreFactor>[];

    if (_containsAny(product.dataQualityTags, [
      'complete',
      'ecoscore-complete',
    ])) {
      score += 20;
      factors.add(
        ScoreFactor(
          label: 'Datenqualität',
          value: '+20',
          source: 'Open Food Facts · Datenqualität',
          available: true,
          evidenceIds: _evidenceIds(product, 'data_quality'),
        ),
      );
    }

    if (product.hasKnownBrand && !product.brand.contains(',')) {
      score += 10;
      factors.add(
        ScoreFactor(
          label: 'Marke eindeutig',
          value: '+10',
          source: 'Open Food Facts · Marke',
          available: true,
          evidenceIds: _evidenceIds(product, 'brand'),
        ),
      );
    }

    if (product.ingredientsText != null &&
        product.ingredientsText!.trim().isNotEmpty) {
      score += 10;
      factors.add(
        ScoreFactor(
          label: 'Zutatenliste vorhanden',
          value: '+10',
          source: 'Open Food Facts · Zutaten',
          available: true,
          evidenceIds: _evidenceIds(product, 'ingredients'),
        ),
      );
    }

    if (_containsAny(product.dataQualityWarnings, ['missing'])) {
      score -= 10;
      factors.add(
        ScoreFactor(
          label: 'Datenwarnung',
          value: '-10',
          source: 'Open Food Facts · Datenwarnungen',
          available: true,
          evidenceIds: _evidenceIds(product, 'data_quality_warnings'),
        ),
      );
    }

    if (factors.isEmpty) {
      factors.add(
        const ScoreFactor(
          label: 'Governance-Signal',
          value: 'Neutraler Startwert',
          source: 'ScanFair Methodik v1.0',
          available: true,
        ),
      );
    }

    return PillarScore(
      pillar: ScorePillar.governance,
      value: _clamp(score),
      label: 'Governance',
      factors: factors,
    );
  }

  double? _weightedAverage({
    PillarScore? environmental,
    PillarScore? social,
    PillarScore? governance,
  }) {
    final weightedValues = <double>[];
    var weightSum = 0.0;

    if (environmental != null) {
      weightedValues.add(environmental.value * _environmentWeight);
      weightSum += _environmentWeight;
    }
    if (social != null) {
      weightedValues.add(social.value * _socialWeight);
      weightSum += _socialWeight;
    }
    if (governance != null) {
      weightedValues.add(governance.value * _governanceWeight);
      weightSum += _governanceWeight;
    }

    if (weightSum == 0) return null;
    return weightedValues.reduce((a, b) => a + b) / weightSum;
  }

  double? _mapEcoGrade(String? grade) {
    switch (grade?.toLowerCase().trim()) {
      case 'a-plus':
      case 'a+':
        return 95;
      case 'a':
        return 85;
      case 'b':
        return 70;
      case 'c':
        return 55;
      case 'd':
        return 40;
      case 'e':
        return 25;
      case 'f':
        return 10;
      default:
        return null;
    }
  }

  double _clamp(double value) => value.clamp(0, 100).toDouble();

  List<String> _normalizedTags(ScanFairProduct product) {
    return [
      ...product.labelsTags,
      ...product.originTags,
    ].map((tag) => tag.toLowerCase().replaceAll('en:', '')).toList();
  }

  bool _containsAny(List<String> tags, List<String> needles) {
    return tags.any((tag) => needles.any(tag.contains));
  }

  List<String> _evidenceIds(ScanFairProduct product, String metric) {
    return product
        .evidenceFor(metric)
        .map((entry) => entry.id)
        .toList(growable: false);
  }

  List<String> _scoreSources(ScanFairProduct product) {
    final sources = product.dataSources
        .map((source) => source.name)
        .toList(growable: true);
    if (sources.isEmpty) {
      sources.add('Lokale Demo-Daten');
    }
    sources.add('ScanFair Methodik v${ESGScore.formulaVersion}');
    return sources;
  }
}
