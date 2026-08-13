import '../models/esg_score.dart';
import '../models/product.dart';

/// ESG-Formel v1.1 (ADR 0034): Säulen entstehen nur aus echter Evidenz —
/// keine Neutral-Baselines, exaktes Tag-Matching statt Substring, und ein
/// Gesamtwert ohne alle drei Säulen ist ein sichtbarer Teilscore.
class ESGScoreCalculator {
  const ESGScoreCalculator();

  // Konstanten der Formel v1.1 — Änderungen erfordern einen Versions-Bump
  // von ESGScore.formulaVersion (ADR 0034).
  static const _environmentWeight = 0.50;
  static const _socialWeight = 0.30;
  static const _governanceWeight = 0.20;

  static const _fairTradeLabels = {'fair-trade', 'fairtrade'};
  static const _organicLabels = {'organic', 'bio', 'eu-organic', 'demeter'};
  static const _veganLabels = {'vegan', 'vegetarian'};
  static const _cultivationStandardLabels = {'rainforest-alliance', 'utz'};
  static const _rspoLabels = {'rspo', 'rspo-certified'};
  static const _regionalOrigins = {
    'germany',
    'deutschland',
    'austria',
    'switzerland',
    'european-union',
  };
  static const _completeQualityTags = {'complete', 'ecoscore-complete'};

  // Trifft "palm", "palmöl", "palm oil", "palmfett", "palmkernöl" — aber
  // nicht "palmitate"/"palmitic"/"palmito" (Audit-Finding F-13).
  static final _palmPattern = RegExp(r'\bpalm(?!it)');

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
    if (total == null) {
      return ESGScore(
        state: ScoreState.dataIncomplete,
        dataCompleteness: completeness,
        environmental: environmental,
        social: social,
        governance: governance,
        sources: _scoreSources(product),
      );
    }

    return ESGScore(
      state: pillars.length == 3
          ? ScoreState.fullScore
          : ScoreState.partialScore,
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
    final labels = _normalizedTags(product.labelsTags);
    final origins = _normalizedTags(product.originTags);
    final ingredients = product.ingredientsText?.toLowerCase() ?? '';

    var delta = 0.0;
    final factors = <ScoreFactor>[];

    if (_matchesAny(labels, _fairTradeLabels)) {
      delta += 25;
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

    if (_matchesAny(labels, _organicLabels)) {
      delta += 20;
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

    if (_matchesAny(labels, _veganLabels)) {
      delta += 10;
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

    if (_matchesAny(origins, _regionalOrigins)) {
      delta += 15;
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

    if (_matchesAny(labels, _cultivationStandardLabels)) {
      delta += 20;
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

    final hasRspoSignal = _matchesAny(labels, _rspoLabels);
    if (hasRspoSignal) {
      delta += 10;
      factors.add(
        ScoreFactor(
          label: 'Zertifiziertes Palmöl (RSPO)',
          value: '+10',
          source: 'Open Food Facts · Kennzeichnungen',
          available: true,
          evidenceIds: _evidenceIds(product, 'labels'),
        ),
      );
    }

    if (_palmPattern.hasMatch(ingredients) && !hasRspoSignal) {
      delta -= 15;
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

    // Ohne echte Signale gibt es keine Social-Säule — kein Neutralwert
    // (ADR 0034).
    if (factors.isEmpty) return null;

    return PillarScore(
      pillar: ScorePillar.social,
      value: _clamp(50 + delta),
      label: 'Social',
      factors: factors,
    );
  }

  PillarScore? _calculateGovernance(ScanFairProduct product) {
    final qualityTags = _normalizedTags(product.dataQualityTags);

    var delta = 0.0;
    final factors = <ScoreFactor>[];

    if (_matchesAny(qualityTags, _completeQualityTags)) {
      delta += 20;
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

    if (_hasSegment(product.dataQualityWarnings, 'missing')) {
      delta -= 10;
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

    // Marke oder Zutatenliste allein sind keine Governance-Evidenz mehr —
    // kein Neutralwert (ADR 0034).
    if (factors.isEmpty) return null;

    return PillarScore(
      pillar: ScorePillar.governance,
      value: _clamp(50 + delta),
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

  /// Normalisiert OFF-Tags auf Kleinschreibung ohne Sprachpräfix ("en:",
  /// "de:", …). Verglichen wird immer der ganze Tag — nie ein Substring.
  Set<String> _normalizedTags(List<String> tags) {
    return tags
        .map(
          (tag) => tag.trim().toLowerCase().replaceFirst(
            RegExp(r'^[a-z]{2,3}:'),
            '',
          ),
        )
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  bool _matchesAny(Set<String> tags, Set<String> needles) {
    return tags.any(needles.contains);
  }

  /// Prüft, ob ein Tag das Segment (durch "-" getrennt) exakt enthält —
  /// "origins-missing" enthält "missing", "antibiotics" enthält kein "bio".
  bool _hasSegment(List<String> tags, String segment) {
    return _normalizedTags(tags).any((tag) => tag.split('-').contains(segment));
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
