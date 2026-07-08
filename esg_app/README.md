# ScanFair Flutter App

Lokaler Flutter-MVP fuer ScanFair. Die App bildet den Kernflow ab:
Home/Scan-Simulation, Produktlookup ueber lokale Demo-/OFF-aehnliche Daten,
ESG-Score-Berechnung, Ergebnisansicht, Detailansicht, Low-Data-Zustand und
Not-Found-Zustand.

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
- `lib/services/product_repository.dart` kapselt den lokalen Demo-Lookup.
- `lib/screens/` enthaelt Home, Result, Details, LowData und NotFound.
- `lib/widgets/score_widgets.dart` enthaelt wiederverwendbare Score-Komponenten.

Noch nicht Teil dieses lokalen Stands: echte Kamera via `mobile_scanner`,
echter OFF-Netzwerkadapter, Supabase, iOS-Deployment, TestFlight oder Release.
