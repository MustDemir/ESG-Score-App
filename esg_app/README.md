# ScanFair Flutter App

Lokaler Flutter-MVP fuer ScanFair. Die App bildet den Kernflow ab:
Home/Kamera-Scan, echter Produktlookup ueber die Open Food Facts API v3,
ESG-Score-Berechnung, Ergebnisansicht, Detailansicht sowie Low-Data-,
Not-Found-, Kamera-Permission- und Netzwerkfehler-Zustaende. Demo-Daten bleiben
fuer deterministische Tests verfuegbar. Live-Daten werden in feldgenaue
`ESGEvidence`-Eintraege mit Quelle, Lizenz, Zeitstempel und Qualitaetsklasse
ueberfuehrt. AGRIBALYSE-3.2-Klimadaten werden bei vorhandenem AGB-Code als
offizielle Kategorieevidenz erfasst; Open Food Facts bleibt als
Retrieval-Channel sichtbar. Dieses Rohmapping ist noch nicht score-aktiv. Die
aktive Formel v1.1 erzeugt keine neutralen Ersatzwerte und kennzeichnet
Gesamtwerte aus weniger als drei belegten Saeulen als partiell.

## Lokal starten

```bash
cd /Users/mustafademir/ESG-Score-App/esg_app
flutter pub get
flutter run
```

## Auf dem eigenen iPhone testen

1. iPhone per USB verbinden, entsperren und diesem Mac vertrauen.
2. Auf dem iPhone den Developer Mode unter Datenschutz & Sicherheit aktivieren.
3. `ios/Runner.xcworkspace` in Xcode oeffnen und fuer `Runner` unter
   `Signing & Capabilities` das eigene Apple-Team auswaehlen.
4. Das erkannte Geraet mit Flutter starten:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter devices
flutter run -d <IPHONE_DEVICE_ID>
```

Beim ersten Oeffnen des Scanners den Kamerazugriff erlauben. Der iOS-Simulator
eignet sich fuer UI- und Build-Tests, aber nicht fuer den realen Kamera-Scan.

## Tests und Checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage
```

Repo-weite Quality Gates:

```bash
cd /Users/mustafademir/ESG-Score-App
bash scripts/quality/run_quality_gates.sh
bash scripts/quality/run_ios_build_gate.sh
```

## Architektur

- `lib/models/` enthaelt Product- und ESG-Score-Datenmodelle.
- `lib/models/esg_evidence.dart` definiert die normalisierte Datenprovenienz.
- `lib/models/esg_relationship.dart` modelliert GTIN-, Rohstoff-, Herkunfts-,
  Marken- und Rechtstraegerbeziehungen mit Assertion-Klasse und Confidence.
- `lib/data_sources/` enthaelt quellenspezifische Mapper.
- `lib/services/esg_score_calculator.dart` implementiert Formel v1.1 aus ADR
  0011 in Verbindung mit ADR 0027 und ADR 0034.
- `lib/services/open_food_facts_service.dart` kapselt OFF API v3 mit Timeout,
  Retry, User-Agent und Fehlerklassifikation.
- `lib/services/product_repository.dart` trennt Live- und Demo-Datenquellen.
- `lib/screens/scanner_screen.dart` kapselt `mobile_scanner`, Kamera,
  EAN-/UPC-Erkennung, Lifecycle, Torch und Permission-Fallback.
- `lib/screens/` enthaelt ausserdem Home, Result, Details, LowData und NotFound.
- `lib/widgets/score_widgets.dart` enthaelt wiederverwendbare Score-Komponenten.

Die Detailansicht zeigt die aktuell aufgeloesten Beziehungen. Community-Daten
und abgeleitete Rohstoffhinweise bleiben sichtbar, sind aber nicht automatisch
score-aktiv. Eine Rohstoff-Laender-Risikobewertung benoetigt einen belastbaren
Produkt-Rohstoff-Link und einen separaten Rohstoff-Herkunfts-Link.

Das RLS-gesicherte Supabase-Schema liegt migrationsbasiert unter `../supabase/`.
Das dedizierte Development-Projekt `scanfair-dev` in Frankfurt ist provisioniert
und sein freigegebener Schemastand remote abgeglichen. Der App-Zugriff und die
Writer-Runtime bleiben deaktiviert. Die App enthaelt einen optionalen
read-only REST-/RPC-Cache-Adapter ohne `supabase_flutter`; ohne Build-Konfiguration
nutzt sie Open Food Facts direkt. Auth, Personendatenpfade, TestFlight,
App-Store-Release und Online-Deployment sind nicht aktiviert. Xcode 26.6, der
unsigned iOS-Simulator-Build und der reale Kamera-Flow auf einem lokal
signierten iPhone wurden validiert.
