# Quality Strategy

> Lebendiges Methodik-Dokument zu CI/CD/CT, Testing und Code-Qualität.
> Grundsatz-Entscheidung: [ADR 0007](decisions/0007-cicd-ct-strategy.yaml).
> Sicherheits-Baseline: [ADR 0008](decisions/0008-security-baseline.yaml).

Letztes Update: 2026-05-19

---

## 1. Prinzipien

1. **Catch fast, fail loud** — jeder PR muss durch CI bevor er auf main kann
2. **Wachse mit Schmerz** — neue Checks erst wenn echter Schmerz auftaucht, nicht prophylaktisch
3. **Disziplin > Tooling** — bestes Test-Setup hilft nicht ohne Test-Schreiben-Gewohnheit
4. **Transparenz** — bei jedem Release weiß ich: was wurde getestet, was wurde nicht

## 2. Test-Pyramide für Flutter

```
                    ┌─────────────────┐
                    │  Manuell / QA   │   <5%  (Edge-Cases vor Release)
                    └─────────────────┘
                  ┌─────────────────────┐
                  │   Integration       │   ~15%  (Golden Paths, langsam)
                  └─────────────────────┘
              ┌──────────────────────────────┐
              │       Widget Tests           │   ~25%  (UI-Bausteine)
              └──────────────────────────────┘
        ┌────────────────────────────────────────────┐
        │             Unit Tests                     │   ~55%  (Logik, schnell)
        └────────────────────────────────────────────┘
```

### Was wird wie getestet?

| Code-Bereich | Test-Level | Tool |
|---|---|---|
| `lib/models/` (Freezed Models, Mappers) | Unit | `flutter test` |
| `lib/services/` (OFF-Service, ESG-Calculator) | Unit + Mocks | `mockito` |
| `lib/widgets/` (ProductCard, ScoreHero) | Widget | `flutter test` mit `WidgetTester` |
| `lib/screens/` (Scanner, Result) | Widget + Integration | `flutter test` + `integration_test` |
| API-Calls (echte OFF-API) | Manuell + selten in CI | `--tags=network` |

### Coverage-Gates

| Sprint | Mindest-Coverage | Wo |
|---|---|---|
| Sprint 0 | n/a | noch kein Code |
| Sprint 1 | 50% | Models + Services |
| Sprint 2 | 60% | + Widgets |
| Sprint 3 (TestFlight) | 70% gesamt, 90% Services |
| Phase 2 (KI-Layer) | 70%+, KI-Service-Code 95% |

Coverage ist **Indikator, nicht Ziel**. Ein Test der nur Coverage erzeugt ist Schrott.

## 3. CI-Pipeline (Sprint 0 Setup)

### `.github/workflows/ci.yml` (Skeleton)

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main, dev]

jobs:
  flutter-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.0'
          channel: stable
      - run: flutter pub get
      - run: flutter format --set-exit-if-changed lib test
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with:
          file: ./coverage/lcov.info

  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
```

### Branch-Protection auf `main` (GitHub Settings)

- Require pull request before merging
- Require status checks: `flutter-check`, `secret-scan`
- Require linear history
- Block force-pushes

## 4. Pre-Commit-Hooks (lokal)

Datei: `.git/hooks/pre-commit` (oder via `pre-commit` framework)

```bash
#!/bin/sh
set -e
# Secret-Scan
gitleaks protect --staged --redact || { echo "❌ Secrets erkannt"; exit 1; }
# Format
dart format --set-exit-if-changed lib test || { echo "❌ Format-Drift"; exit 1; }
# Schneller Lint (optional, falls Zeit knapp: nur in CI)
flutter analyze --no-pub --no-fatal-infos lib || true
```

## 5. Release-Gate-Checkliste (vor TestFlight)

In dieser Reihenfolge abarbeiten:

```
[ ] CI grün auf main
[ ] flutter test --coverage zeigt >=70%
[ ] flutter analyze sauber
[ ] /security-review Slash-Command durchgelaufen
[ ] compliance-auditor Skill durchgelaufen
[ ] Privacy Policy aktualisiert (falls Datenfluss-Änderung)
[ ] Changelog für diese Version geschrieben
[ ] Version-Bump in pubspec.yaml (SemVer)
[ ] Git-Tag gesetzt
[ ] TestFlight-Build via Fastlane gestartet
[ ] Smoke-Test auf physischem iPhone
```

## 6. Welche Claude-Code-Skills wann

| Situation | Skill / Command |
|---|---|
| Vor PR-Merge | `/review` (engineering:code-review) |
| Neuen Feature-Plan machen | `engineering:testing-strategy` |
| Bug debuggen | `engineering:debug` |
| Vor TestFlight | `engineering:deploy-checklist` + `/security-review` |
| Vor App-Store-Submission | `compliance-auditor` |
| Architektur-Frage | `backend-architect` oder `engineering:architecture` |
| Performance-Problem | `sre` |

## 7. Versionierung & Releases (SemVer)

`MAJOR.MINOR.PATCH+BUILDNUMBER`

- **MAJOR**: Breaking Change (API-Format ändert sich, Migrations-Pflicht)
- **MINOR**: Neues Feature, backward-compatible
- **PATCH**: Bugfix
- **BUILDNUMBER**: bei jedem Build inkrementiert (für TestFlight)

Beispiele:
- `0.1.0+1` — erste TestFlight-Version
- `0.1.1+2` — Bugfix-Release
- `0.2.0+3` — KI-Layer hinzugefügt
- `1.0.0+10` — Public App-Store-Launch

## 8. Was wir bewusst NICHT machen (Phase 1)

- ❌ E2E-Tests für jeden Screen (Maintenance-Hölle)
- ❌ Visual-Regression-Testing (overkill)
- ❌ Mutation-Testing
- ❌ Property-based Testing
- ❌ Performance-Benchmarks im CI (zu flaky)
- ❌ Lighthouse-Scoring in jeder Pipeline

Diese Punkte können in Phase 2/3 reaktiviert werden — aber nicht vor MVP.

## 9. Failure-Mode-Antwortplan

Was tun wenn CI rot wird?

1. **Format-Fehler**: `dart format lib test` lokal, neu pushen
2. **Lint-Fehler**: `flutter analyze` lokal lesen, beheben
3. **Test-Fehler**: lokal nachstellen, fixen oder Test fixen (nicht stumpf löschen!)
4. **Secret erkannt**: SOFORT rotieren, nicht nur Commit reverten
5. **Coverage gefallen**: war ein neuer Code-Pfad ohne Test? Test schreiben
6. **CI-Flake (intermittierend)**: rerun einmal, wenn weiterhin: Issue erstellen, analysieren

Niemals: `--skip`, `--no-verify`, „rebase squash to hide", oder Tests löschen statt fixen.

## 10. Wartung dieses Dokuments

- Updates wenn ein neuer Check eingeführt wird
- Updates wenn ein Anti-Pattern vermieden wurde (Lesson Learned)
- Mindestens 1× pro Phase reviewen ob Coverage-Gates noch passen
