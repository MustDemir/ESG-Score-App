# Quality Strategy

> Lebendiges Methodik-Dokument zu CI/CD/CT, Testing und Code-Qualität.
> Grundsatz-Entscheidung: [ADR 0007](decisions/0007-cicd-ct-strategy.yaml).
> Sicherheits-Baseline: [ADR 0008](decisions/0008-security-baseline.yaml).

Letztes Update: 2026-08-18

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
| Methodikkatalog und Profile | Schema-, Referenz- und Claim-Regeln | `G-METHOD-CATALOG` |
| Subject Links und Score-Sicherheit | Link-, Missing-Data-, Red-Flag-, Reproduzierbarkeits- und Claim-Regeln | `G-LINK-INTEGRITY` bis `G-CLAIM-SAFETY` |
| Öffentliche Claims und Nährwertgrenze | Inventar-, Runtime-, Evidenz- und Aktivierungsprofile | `G-CLAIM-GOVERNANCE` |
| Privacy-Datenfluss und Aktivierung | Datenmatrix-, Code-, DPIA- und Review-Evidenz | `G-PRIVACY-BOUNDARY` |
| Backend- und Writer-Sicherheitsgrenze | STRIDE-/Abuse-Case-Modell, Umgebungsvertrag und Aktivierungsevidenz | `G-BACKEND-BOUNDARY` |
| Gate-Definitionen | Sieben Kernattribute, erlaubte Werte, Referenzen und positive/negative Selbsttests | `G-GATE-DEFINITION-QUALITY` |
| Provider Governance | DPA, Unterauftragsverarbeiter, Frankfurt-Region, Plan und Kostenfreigaben | `G-PROVIDER-DPA`, `G-PROVIDER-SUBPROCESSORS`, `G-COST-CONTROL` |
| Supabase-Schema und RLS | Migration-Replay + pgTAP | `supabase test db` |
| Native iOS-Integration | Compile-Gate + physischer Smoke-Test | Xcode + `flutter build ios` |
| Mobile Security | MASVS-2.1-Matrix + Repositorychecks + Device-Checkliste | `G-MASVS` |

### Coverage-Gates

| Sprint | Mindest-Coverage | Wo |
|---|---|---|
| Sprint 0 | n/a | noch kein Code |
| Sprint 1 | 50% | Models + Services |
| Sprint 2 | 60% | + Widgets |
| Sprint 3 (TestFlight) | 70% gesamt, 90% Services |
| Phase 2 (KI-Layer) | 70%+, KI-Service-Code 95% |

Coverage ist **Indikator, nicht Ziel**. Ein Test der nur Coverage erzeugt ist Schrott.

## 3. CI/CT-Pipeline

Die verbindliche Workflow-Datei ist
[`quality-gates.yml`](../../.github/workflows/quality-gates.yml). Sie laeuft
bei Pushes nach `main`, bei Pull Requests nach `main` sowie manuell via
`workflow_dispatch`. Feature-Branch-Pushes ohne Pull Request loesen bewusst
keinen doppelten Lauf aus. Aenderungen an der
Repository-README loesen sie ebenfalls aus, weil `G-DOC-TRACE` diese Datei
mitprueft. Montags laeuft zusaetzlich nur `G-SUPPLY-CHAIN`; die teuren
iOS-, Datenbank- und vollstaendigen App-Jobs werden im Zeitplanlauf
uebersprungen.

| Job | Inhalt | Ergebnis |
|---|---|---|
| `Local CI quality gates` | Flutter Dependencies, Format, Analyse, Tests, Coverage >= 60 %, MASVS, OPA, Conftest/Evidence-Log, Datenarchitektur, Methodikkatalog, Claim-/Privacy- und Backend-Grenzen, Projektsteuerung, Doku-Trace und YAML | Gate-Report + Compliance- und MASVS-Artefakte |
| `G-SUPPLY-CHAIN dependency and Action security` | OSV fuer alle gelockten Dart-Pakete, Lizenz- und iOS-Plugin-Inventar, unveraenderliche Action-SHAs sowie Dependency Review bei PRs | Supply-Chain-Inventar + OSV-Evidenz |
| `G-IOS-COMPILE native iOS build` | Unsigned Simulator-Build plus Audit aller gebuendelten Privacy Manifests auf macOS | `Runner.app` und `ios_privacy_audit.json` |
| `G-DATA-RLS migration and policy tests` | Supabase-Migration-Replay, 213 pgTAP-RLS-/Writer-/Retention-Tests und PostgreSQL-Lint | Pipeline-Abbruch bei Schema-/Policy-Fehlern |
| `G-PROVIDER-GOVERNANCE DPA, subprocessors and cost` | Gate-Schema, DPA-/Unterauftragsverarbeiter-/Kostenregister; geplante und manuelle Laeufe pruefen zusaetzlich offizielle Versionsmarker | Provider-, Gate- und Online-Pruefevidenz |
| `Secret scan gate` | Vollstaendiger Git-History-Scan mit Gitleaks | Pipeline-Abbruch bei Secrets |

Die lokale Entsprechung ist `bash scripts/quality/run_quality_gates.sh`.
Sie deckt neunundzwanzig Engineering-, Schema-, Policy-, Evidence-, Security-, Scoring-Safety-, Provider-
und Doku-Gates ab.
Der native iOS-Compile-Job, der echte lokale PostgreSQL-/RLS-Test und der
vollstaendige Git-History-Scan erfolgen zusaetzlich in GitHub Actions. Der
Datenbanktest ist lokal ueber
`bash scripts/quality/run_data_database_gate.sh` reproduzierbar. Es gibt keine
automatische Auslieferung. Das
Profil `release_candidate` ist eine strenge lokale Freigabepruefung und fuehrt
weder TestFlight-Upload noch App-Store-Submission aus.

`G-SUPPLY-CHAIN` laedt OSV-Scanner 2.4.0 ausschliesslich ueber HTTPS und
verifiziert die plattformspezifische SHA-256-Pruefsumme vor der Ausfuehrung.
Das Gate inventarisiert `pubspec.lock`, installierte Lizenztexte, die
tatsaechlichen iOS-Flutter-Plugins sowie alle externen Action-Referenzen.
Bekannte Schwachstellen, unbekannte Lizenzen, bewegliche Action-Tags und neue
ungepruefte native Paketquellen blockieren. Eine Ausnahme ist nur mit Owner,
Begruendung, Freigabe- und Ablaufdatum fuer maximal 90 Tage moeglich.

Die Apple-Kontrollen verwenden drei Profile:

- `development`: objektive aktuelle MUST-Verstoesse blockieren, spaetere
  Release-Evidenz bleibt als Warnung sichtbar.
- `release_candidate`: jede anwendbare offene MUST-Evidenz blockiert.
- `submission`: wie Release Candidate plus finale manuelle Attestation.

`G-MASVS` verwendet dieselben Profile. Im Development-Profil blockieren
unvollstaendige Klassifikation, widerspruechliche Scope-Annahmen und
automatisierbare Security-Findings. Offene manuelle MUST-Nachweise bleiben
sichtbare Warnungen. `release_candidate` und `submission` blockieren dagegen
jede offene anwendbare MUST-Kontrolle sowie fehlende Device-Evidenz. Die
Baseline klassifiziert alle 24 MASVS-2.1-Kontrollen; nicht anwendbare
Kontrollen besitzen einen Reaktivierungs-Trigger, damit neue Auth-, Storage-,
WebView- oder Backend-Funktionen eine erneute Bewertung erzwingen.

`G-DATA-LICENSE` trennt ebenfalls Profile. `development` besteht nur bei
deaktiviertem Remote-Backend und technisch gepruefter OFF-Quellentrennung.
`remote_backend` und `release_candidate` blockieren, solange qualifiziertes
Rechtsreview, maschinenlesbarer Share-Alike-Export sowie Korrektur- und
Loeschprozesse fehlen. Ein lokales PASS ist daher keine Lizenzfreigabe fuer
eine oeffentliche Datenbank.

`G-CLAIM-GOVERNANCE` und `G-PRIVACY-BOUNDARY` trennen lokale Entwicklung von
externer Aktivierung. Das Development-Profil verlangt eine konservative
Runtime-Grenze und eine mit dem Code uebereinstimmende SSOT. External-Beta-,
Remote- und Release-Profile verlangen zusaetzlich qualifizierte Reviews sowie
typisierte, repository-interne und SHA-256-gebundene Evidenz. Beliebige
Statusfelder oder Platzhalterdateien koennen diese Gates nicht auf gruen setzen.

`G-BACKEND-BOUNDARY` laeuft lokal im Profil `development`: Writer-Vertrag,
Datenbank-RPCs und read-only Flutter-Cache werden geprueft; der Remote-Pfad
muss deaktiviert bleiben, waehrend Threat Model und Sicherheitsvertrag
vollstaendig und widerspruchsfrei sein muessen. `remote_backend` verlangt ein
aktives separates EU-Development-Projekt in `eu-central-1`, freigegebenen DPA-
und Regionnachweis sowie drei typisierte, repository-interne und per SHA-256
gebundene Reviews fuer Umgebung, Writer-Sicherheit und Betriebsbereitschaft.
Das Gate prueft ausserdem, dass kein privilegierter Supabase-Schluessel in
Flutter zugelassen ist und RLS-/Grant-Schutz in den Migrationen bestehen bleibt.
ADR 0037 ergaenzt denselben Gate-Pfad um feste technische Aufbewahrungsfristen,
einen taeglichen owner-ausgefuehrten pg_cron-Job, begrenzte Loeschbatches und
einen privaten Replay-Watermark. Das Development-Profil verlangt die lokale
Implementierung; Remote-Aktivierung bleibt bis Cron-, Monitoring- und Cleanup-
Drill-Evidenz gesperrt. Persoenliche Zugriffslogs sind davon nicht freigegeben.
`release_candidate` verlangt unabhaengig vom Aktivierungsstatus einen vierten,
release-spezifischen Security-Review, dessen Evidenz an den geprueften Commit,
Threat Model, Umgebungsvertrag und Review-Artefakt gebunden ist.

`G-GATE-DEFINITION-QUALITY` validiert fuer alle Gate-Dateien die normalisierten
sieben Kernattribute `trigger`, `criteria`, `artifacts`, `decision`, `owner`,
`audit` und `waiver`. Bestehende Definitionen bleiben nur ueber deklarierte
Legacy-Aliase kompatibel; neue Definitionen muessen `scanfair-gate-v1`
verwenden. Positive und negative Selbsttests verhindern, dass ein formal
vorhandenes, aber semantisch unvollstaendiges Gate akzeptiert wird.

Die Provider-Gates trennen drei Ebenen. Im Profil `development` darf ein Gate
nur bestehen, wenn das Frankfurt-Projekt ohne Personendaten, Remote-Schema und
App-Zugriff fail-closed bleibt. `remote_backend` verlangt DPA- und
Unterauftragsverarbeiter-Freigabe, bestaetigte Aenderungsbenachrichtigung,
gepruefte Plan-Evidenz und ein tatsaechlich aktiviertes EU-Development-Backend.
`release_candidate` erbt diese Grenzen und verlangt aktuelle qualifizierte
Reviews. Ein gemeinsames typisiertes Freigabeartefakt muss Reviewer-Identitaet
und -Qualifikation, freigegebene Profile und Gates, den geprueften Commit sowie
die aktuellen Quellversionen enthalten. SHA-256 bindet es an Provider-Register
und Review-Artefakt; reine Statusaenderungen koennen das Gate nicht schliessen.
Woechentliche Online-Pruefungen vergleichen nur offizielle
Versionsmarker. Eine Quellenaenderung erzeugt `review_required`, niemals eine
automatische Rechts- oder Kostenfreigabe.

### Branch-Protection auf `main` (GitHub Settings)

- Require pull request before merging
- Require status checks: `Local CI quality gates`,
  `G-IOS-COMPILE native iOS build`,
  `G-DATA-RLS migration and policy tests`, `Secret scan gate`
- Block force-pushes und Branch-Loeschung
- Kein Owner-Bypass; Merge, Squash und Rebase bleiben als PR-Methode erlaubt

Der neue eigenstaendige Check `G-SUPPLY-CHAIN dependency and Action security`
bleibt zusaetzlich im bereits erforderlichen lokalen Gate-Job eingebettet.
Nach seinem ersten gruenen PR- und Post-Merge-Lauf wird er als fuenfter
expliziter Required Check in das Ruleset aufgenommen.

Der neue Check `G-PROVIDER-GOVERNANCE DPA, subprocessors and cost` wird nach
seinem ersten gruenen PR- und Post-Merge-Lauf als weiterer Required Check
aufgenommen. Bis dahin bleibt er sowohl im lokalen Hauptjob als auch als
separater sichtbarer GitHub-Job enthalten.

Die produktive Quality-Gate-Action ergaenzt den Linux-Job um
`G-IOS-COMPILE` auf einem macOS-Runner. Das Gate baut eine unsigned
iOS-Simulator-App, erkennt native Plugin-, CocoaPods- und Swift-Fehler und
prueft anschliessend alle im `Runner.app` gebuendelten
`PrivacyInfo.xcprivacy`-Dateien. Fehlende Standard-Keys, unbegruendete
Required-Reason-API-Kategorien oder eine Tracking-Deklaration entgegen dem
Compliance-Manifest blockieren den Job. Kameraerkennung selbst bleibt ein
Smoke-Test auf einem physischen iPhone.

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
[ ] COMPLIANCE_PROFILE=release_candidate ohne Findings
[ ] MASVS-Release-Device-Checkliste vollständig mit Evidenz
[ ] Evidence-Hash-Chain verifiziert
[ ] flutter test --coverage zeigt >=70%
[ ] flutter analyze sauber
[ ] /security-review Slash-Command durchgelaufen
[ ] compliance-auditor Skill durchgelaufen
[ ] Privacy Policy aktualisiert (falls Datenfluss-Änderung)
[ ] DPA, Unterauftragsverarbeiter, Aenderungsbenachrichtigung und Provider-Plan freigegeben
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
