# VoiceOver language and terminology policy

## Status and scope

- Status: active development baseline
- App default language: German (`de`)
- Applies to: user-facing Flutter semantics on iOS
- Related requirement: `R-AS-29`
- Related gate: `G-AS-REVIEW-READINESS`

This policy prevents VoiceOver pronunciation from depending on the optional
automatic language detection configured on an individual iPhone. It also
keeps language decisions in one catalog instead of distributing one-off
locale declarations across widgets.

## Rules

1. German is the semantic default for the complete app subtree.
2. A deliberate English phrase is marked with locale `en`.
3. Abbreviations use an explicit spoken form where pronunciation would
   otherwise be ambiguous.
4. Proper names and product brands inherit German by default. Add a catalog
   entry only when an intentional pronunciation is required and device-tested.
5. Technical source fields such as `labels_tags` are not exposed as UI copy;
   the UI uses a German description while retaining the raw field in evidence.
6. Dynamic product data inherits German until its source provides trustworthy
   language metadata. ScanFair does not guess language word by word.
7. Every catalog change requires automated semantics tests and a focused
   physical VoiceOver check before release-candidate evidence is closed.

## Single source of truth

The executable catalog and reusable semantics wrappers are located in:

- `esg_app/lib/accessibility/semantic_terminology.dart`

Current decisions:

| Display text | Spoken form | Locale | Classification |
|---|---|---|---|
| Environmental | Environmental | `en` | English ESG pillar |
| Social | Social | `en` | English ESG pillar |
| Governance | Governance | `en` | English ESG pillar |
| Open Food Facts | Open Food Facts | `en` | English source name |
| Open Food Facts contributors | Open Food Facts contributors | `en` | English attribution |
| ScanFair | Scan Fair | `en` | Product name with intentional pronunciation |
| ESG | E S G | `de` | German letter-by-letter abbreviation |
| RSPO | R S P O | `de` | German letter-by-letter abbreviation |

`Eco-Score`, `Nutri-Score`, `NOVA`, `Barcode`, `Scanner` and ordinary German
UI copy inherit `de`. Other brands and product names remain proper names unless
a documented pronunciation problem is observed.

## Development workflow

For a new foreign term:

1. Decide whether it is ordinary German usage, a deliberate foreign phrase,
   an abbreviation or a proper name.
2. Add one catalog definition only when explicit pronunciation is needed.
3. Render terminology-bearing copy through `TerminologyText` or
   `TerminologySemantics`; the widget receives annotations from the catalog.
4. Add or update semantics tests.
5. Verify the affected flow with VoiceOver while automatic language detection
   is disabled.

For dynamic API content, extend the data model with reviewed language metadata
before applying source-provided locales. Untrusted language tags must not
override the app semantics tree.

## Verification

Automated checks:

```bash
cd esg_app
flutter test test/accessibility/semantic_terminology_test.dart \
  test/widgets/score_accessibility_test.dart
```

The full Flutter test gate includes these tests. Automated semantics evidence
does not replace physical VoiceOver verification because pronunciation depends
on the installed iOS voice and speech synthesizer.

## References

- Apple iPhone User Guide, VoiceOver language settings:
  <https://support.apple.com/de-de/guide/iphone/iphfa3d32c50/ios>
- WCAG 2.2 Understanding SC 3.1.2, Language of Parts:
  <https://www.w3.org/WAI/WCAG22/Understanding/language-of-parts.html>
