# ScanFair Flutter App

Lokaler Flutter-MVP fuer ScanFair. Die App bildet den Kernflow ab:
Home/Scan-Simulation, echter Produktlookup ueber die Open Food Facts API v3,
ESG-Score-Berechnung, Ergebnisansicht, Detailansicht sowie Low-Data-,
Not-Found- und Netzwerkfehler-Zustaende. Demo-Daten bleiben fuer deterministische
Tests verfuegbar.

## Lokal starten

```bash
cd /Users/mustafademir/ESG-Score-App/esg_app
flutter pub get
flutter run
```

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
```

## Architektur

- `lib/models/` enthaelt Product- und ESG-Score-Datenmodelle.
- `lib/services/esg_score_calculator.dart` implementiert ADR 0011.
- `lib/services/open_food_facts_service.dart` kapselt OFF API v3 mit Timeout,
  Retry, User-Agent und Fehlerklassifikation.
- `lib/services/product_repository.dart` trennt Live- und Demo-Datenquellen.
- `lib/screens/` enthaelt Home, Result, Details, LowData und NotFound.
- `lib/widgets/score_widgets.dart` enthaelt wiederverwendbare Score-Komponenten.

Noch nicht Teil dieses lokalen Stands: echte Kamera via `mobile_scanner`,
Supabase, iOS-Deployment, TestFlight oder Release. Fuer einen lokalen
iOS-Simulator-Build muss die vollstaendige Xcode-App installiert und mit
`xcode-select` aktiviert sein; aktuell sind nur die Command Line Tools aktiv.
