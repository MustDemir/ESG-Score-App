enum ScoreState { fullScore, partialScore, dataIncomplete, notFound }

enum TrafficLight { green, yellow, red, grey }

enum ScorePillar { environmental, social, governance }

class ESGScore {
  const ESGScore({
    required this.state,
    required this.dataCompleteness,
    this.environmental,
    this.social,
    this.governance,
    this.total,
    this.sources = const ['Open Food Facts', 'ScanFair Methodik v1.1'],
  });

  final ScoreState state;
  final PillarScore? environmental;
  final PillarScore? social;
  final PillarScore? governance;
  final double? total;
  final double dataCompleteness;
  final List<String> sources;

  static const formulaVersion = '1.1';

  bool get hasFullScore => state == ScoreState.fullScore && total != null;

  /// Voll- oder Teilscore mit vorhandenem Gesamtwert (ADR 0034).
  bool get hasAggregateScore =>
      total != null &&
      (state == ScoreState.fullScore || state == ScoreState.partialScore);

  bool get isPartial => state == ScoreState.partialScore;

  /// Sichtbarer Hinweis, dass der Gesamtwert nicht auf allen drei Säulen
  /// beruht — ein Teilscore darf nie als unqualifiziertes Grün erscheinen.
  String? get partialNote =>
      isPartial ? 'Teilscore: nicht alle Säulen sind belegt.' : null;

  TrafficLight get trafficLight {
    final value = total;
    if (!hasAggregateScore || value == null) {
      return TrafficLight.grey;
    }
    if (value >= 70) return TrafficLight.green;
    if (value >= 40) return TrafficLight.yellow;
    return TrafficLight.red;
  }

  String get verdictLabel {
    switch (trafficLight) {
      case TrafficLight.green:
        return 'Positive Signale';
      case TrafficLight.yellow:
        return 'Gemischte Signale';
      case TrafficLight.red:
        return 'Kritische Signale';
      case TrafficLight.grey:
        return 'Daten unvollständig';
    }
  }

  String get tagline {
    switch (trafficLight) {
      case TrafficLight.green:
        return 'Starke ESG-Signale mit nachvollziehbarer Datenbasis.';
      case TrafficLight.yellow:
        return 'Solide Signale, aber mit sichtbarem Verbesserungspotenzial.';
      case TrafficLight.red:
        return 'Mehrere Nachhaltigkeitssignale fallen kritisch aus.';
      case TrafficLight.grey:
        return 'Wir zeigen nur belegte Signale und verzichten auf Schätzung.';
    }
  }

  Iterable<PillarScore> get availablePillars sync* {
    if (environmental != null) yield environmental!;
    if (social != null) yield social!;
    if (governance != null) yield governance!;
  }
}

class PillarScore {
  const PillarScore({
    required this.pillar,
    required this.value,
    required this.label,
    required this.factors,
  });

  final ScorePillar pillar;
  final double value;
  final String label;
  final List<ScoreFactor> factors;
}

class ScoreFactor {
  const ScoreFactor({
    required this.label,
    required this.value,
    required this.source,
    required this.available,
    this.evidenceIds = const [],
  });

  final String label;
  final String value;
  final String source;
  final bool available;
  final List<String> evidenceIds;
}
