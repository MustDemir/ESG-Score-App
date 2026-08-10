import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

enum SemanticTermId {
  environmental,
  social,
  governance,
  openFoodFacts,
  openFoodFactsContributors,
  scanFair,
  esg,
  rspo,
}

class SemanticTermDefinition {
  const SemanticTermDefinition({
    required this.id,
    required this.displayText,
    required this.spokenText,
    required this.locale,
  });

  final SemanticTermId id;
  final String displayText;
  final String spokenText;
  final Locale locale;
}

abstract final class ScanFairSemanticTerminology {
  static const defaultLocale = Locale('de');

  static const definitions = <SemanticTermDefinition>[
    SemanticTermDefinition(
      id: SemanticTermId.environmental,
      displayText: 'Environmental',
      spokenText: 'Environmental',
      locale: Locale('en'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.social,
      displayText: 'Social',
      spokenText: 'Social',
      locale: Locale('en'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.governance,
      displayText: 'Governance',
      spokenText: 'Governance',
      locale: Locale('en'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.openFoodFactsContributors,
      displayText: 'Open Food Facts contributors',
      spokenText: 'Open Food Facts contributors',
      locale: Locale('en'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.openFoodFacts,
      displayText: 'Open Food Facts',
      spokenText: 'Open Food Facts',
      locale: Locale('en'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.scanFair,
      displayText: 'ScanFair',
      spokenText: 'Scan Fair',
      locale: Locale('en'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.esg,
      displayText: 'ESG',
      spokenText: 'E S G',
      locale: Locale('de'),
    ),
    SemanticTermDefinition(
      id: SemanticTermId.rspo,
      displayText: 'RSPO',
      spokenText: 'R S P O',
      locale: Locale('de'),
    ),
  ];

  static final Map<SemanticTermId, SemanticTermDefinition> _byId = {
    for (final definition in definitions) definition.id: definition,
  };

  static final Map<String, SemanticTermDefinition> _byDisplayText = {
    for (final definition in definitions) definition.displayText: definition,
  };

  static final RegExp _knownTermPattern = RegExp(
    (definitions.map((definition) => definition.displayText).toList()
          ..sort((left, right) => right.length.compareTo(left.length)))
        .map(RegExp.escape)
        .join('|'),
  );

  static SemanticTermDefinition definition(SemanticTermId id) => _byId[id]!;

  static AttributedString annotate(
    String text, {
    Locale baseLocale = defaultLocale,
  }) {
    if (text.isEmpty) return AttributedString(text);

    final spokenText = StringBuffer();
    final attributes = <StringAttribute>[];
    var cursor = 0;

    void append(String value, Locale locale) {
      if (value.isEmpty) return;
      final start = spokenText.length;
      spokenText.write(value);
      attributes.add(
        LocaleStringAttribute(
          range: TextRange(start: start, end: spokenText.length),
          locale: locale,
        ),
      );
    }

    for (final match in _knownTermPattern.allMatches(text)) {
      append(text.substring(cursor, match.start), baseLocale);
      final definition = _byDisplayText[match.group(0)!]!;
      append(definition.spokenText, definition.locale);
      cursor = match.end;
    }

    append(text.substring(cursor), baseLocale);
    return AttributedString(spokenText.toString(), attributes: attributes);
  }
}

class TerminologySemantics extends StatelessWidget {
  const TerminologySemantics({
    required this.label,
    required this.child,
    this.value,
    this.container = false,
    super.key,
  });

  final String label;
  final String? value;
  final bool container;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: container,
      attributedLabel: ScanFairSemanticTerminology.annotate(label),
      attributedValue: value == null
          ? null
          : ScanFairSemanticTerminology.annotate(value!),
      child: ExcludeSemantics(child: child),
    );
  }
}

class TerminologyText extends StatelessWidget {
  const TerminologyText(
    this.data, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return TerminologySemantics(
      label: data,
      child: Text(
        data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
