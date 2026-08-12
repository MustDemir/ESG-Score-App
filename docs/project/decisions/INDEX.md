# ADR Index — ScanFair / ESG-Score-App

> Flache Übersicht aller Architecture Decision Records. Bei jedem neuen
> ADR diese Tabelle aktualisieren. Übernommen aus ai-context-vault-Pattern
> (entscheidungsregister), siehe [ADR 0009](0009-methodology-adoption.yaml).

Letztes Update: 2026-08-11

## Aktive ADRs

| ID | Titel | Status | Datum | Tags | Related |
|---|---|---|---|---|---|
| [0001](0001-flutter-frontend.yaml) | Flutter als Frontend-Framework | accepted | 2026-05-19 | frontend, architecture, mobile | — |
| [0002](0002-supabase-backend.yaml) | Supabase (EU-Frankfurt) als Backend | accepted | 2026-05-19 | backend, database, auth, dsgvo | 0003 |
| [0003](0003-open-food-facts.yaml) | Open Food Facts als primäre Produktdatenquelle | superseded | 2026-05-19 | data, api, dsgvo, licensing | 0002, 0030 |
| [0004](0004-no-ai-phase-1.yaml) | Kein KI-/LLM-Layer in Phase 1 (MVP) | accepted | 2026-05-19 | ai, scope, mvp | 0002, 0005 |
| [0005](0005-reject-argonos.yaml) | ArgonOS (ChapsVision) als KI-Plattform abgelehnt | rejected | 2026-05-19 | ai, evaluation, enterprise | 0004 |
| [0006](0006-monetization-via-membership.yaml) | Monetarisierung via Membership (Freemium + ScanFair+) | accepted | 2026-05-19 | monetization, business-model, ai, strategy | 0002, 0004 |
| [0007](0007-cicd-ct-strategy.yaml) | CI/CD/CT-Strategie — minimal aber von Anfang an | accepted | 2026-05-19 | ci-cd, testing, devops, quality | 0001, 0008 |
| [0008](0008-security-baseline.yaml) | Security-Baseline — 7 nicht-verhandelbare Praktiken | accepted | 2026-05-19 | security, dsgvo, secrets, supabase, owasp-masvs | 0002, 0007 |
| [0009](0009-methodology-adoption.yaml) | Methodik-Übernahme aus ai-context-vault + genaiops-compliance-gates | accepted | 2026-05-19 | methodology, adoption, compliance | 0007, 0008 |
| [0010](0010-eco-score-fallback.yaml) | Eco-Score-Fallback-Logik bei unvollständigen Daten | accepted | 2026-05-19 | scoring, esg, data-quality, ux | 0003, 0011 |
| [0011](0011-esg-score-formel.yaml) | ESG-Score-Formel — E/S/G aus OFF-Feldern | accepted | 2026-05-19 | scoring, esg, formel, mvp, methodology | 0003, 0010 |
| [0012](0012-apple-review-compliance.yaml) | Apple Review Compliance Strategy | superseded | 2026-05-19 | compliance, apple, app-store, gates, policy-as-code | 0006, 0007, 0008, 0009 |
| [0013](0013-multi-regulation-strategy.yaml) | Multi-Regulation-Strategy — Cross-Regulation-Mapping | accepted | 2026-05-19 | compliance, methodology, multi-regulation, dsgvo, apple, framework | 0007, 0008, 0009, 0012 |
| [0014](0014-local-mvp-quality-gates.yaml) | Lokale MVP-App-Architektur mit CI/CD-Quality-Gates | accepted | 2026-07-08 | architecture, flutter, ci-cd, quality-gates, local-first | 0001, 0003, 0007, 0008, 0009, 0010, 0011, 0012, 0013 |
| [0015](0015-phase-1-state-management.yaml) | Flutter-native State-Verwaltung fuer den Phase-1-MVP | accepted | 2026-07-18 | flutter, state-management, architecture, mvp | 0001, 0007, 0014 |
| [0016](0016-open-food-facts-api-v3.yaml) | Open Food Facts API v3 fuer Produktabfragen | accepted | 2026-07-18 | api, open-food-facts, data, architecture | 0003, 0008, 0010, 0011, 0014 |
| [0017](0017-mobile-scanner-ios-camera.yaml) | mobile_scanner fuer den nativen iOS-Barcode-Scan | accepted | 2026-07-19 | flutter, scanner, ios, camera, privacy | 0001, 0007, 0008, 0012, 0014, 0015 |
| [0020](0020-quality-gate-workflow-consolidation.yaml) | Einen verbindlichen Quality-Gate-Workflow verwenden | accepted | 2026-07-19 | ci-cd, quality-gates, github-actions, documentation | 0007, 0014 |
| [0021](0021-apple-compliance-enforcement-profiles.yaml) | Apple-Compliance mit gestuften Enforcement-Profilen steuern | accepted | 2026-07-19 | apple, compliance, policy-as-code, evidence, release-readiness | 0009, 0012, 0013, 0020 |
| [0022](0022-evidence-first-data-integration.yaml) | Evidence-first Datenintegration mit RLS-geschuetztem Supabase-Cache | accepted | 2026-07-27 | data, architecture, provenance, supabase, security, licensing | 0002, 0003, 0008, 0010, 0011, 0016, 0020, 0021 |
| [0023](0023-hierarchical-esg-parameter-catalog.yaml) | Hierarchischer und versionierter ESG-Parameterkatalog | accepted | 2026-07-27 | methodology, scoring, parameters, profiles, transparency, data | 0003, 0009, 0010, 0011, 0022 |
| [0024](0024-agribalyse-category-lca-source.yaml) | AGRIBALYSE 3.2 als Umwelt-LCA-Quelle auf Kategorieebene | accepted | 2026-07-27 | data, environment, lca, agribalyse, provenance, licensing | 0003, 0011, 0016, 0022, 0023 |
| [0025](0025-evidence-backed-traceability-links.yaml) | Evidenzbasierte Traceability-Links vor ESG-Risiko-Joins | accepted | 2026-07-27 | data, traceability, scoring, confidence, claims | 0022, 0023, 0024 |
| [0026](0026-reproducible-supply-chain-baseline.yaml) | Reproduzierbare Dependency- und Supply-Chain-Baseline | accepted | 2026-07-28 | security, dependencies, supply-chain, github-actions, ios, licensing | 0007, 0008, 0017, 0020, 0021 |
| [0027](0027-environmental-score-precedence.yaml) | Environmental-Evidenz als Voraussetzung fuer den Gesamt-ESG-Score | accepted | 2026-08-10 | scoring, esg, data-quality, transparency, methodology | 0010, 0011, 0022, 0023, 0025 |
| [0028](0028-product-scoped-commodity-origin.yaml) | Produktgebundene Rohstoff-Herkunftsbeziehungen | accepted | 2026-08-10 | data, traceability, scoring, context, coffee | 0022, 0023, 0025, 0027 |
| [0029](0029-lifecycle-gap-control.yaml) | Repo-native Lifecycle-Gap-Kontrolle mit Reifegrad und Evidence Closure | accepted | 2026-08-10 | methodology, governance, risk, quality-gates, release-readiness | 0007, 0009, 0020, 0021, 0022, 0026 |
| [0030](0030-data-license-composition.yaml) | Quellengetrennte Datenlizenz-Komposition vor Remote-Aktivierung | accepted | 2026-08-11 | data, licensing, odbl, architecture, quality-gates, supabase | 0002, 0020, 0022, 0024, 0025, 0029 |
| [0031](0031-claims-and-privacy-boundaries.yaml) | Fail-closed Claim- und Privacy-Grenzen vor externer Aktivierung | accepted | 2026-08-11 | compliance, claims, privacy, nutrition, app-store, quality-gates | 0013, 0017, 0021, 0023, 0027, 0029, 0030 |
| [0032](0032-backend-security-boundary.yaml) | Read-only Mobile-Client und vertrauenswuerdiger Server-Writer | accepted | 2026-08-11 | backend, security, threat-model, supabase, quality-gates | 0002, 0008, 0020, 0022, 0029, 0031 |

## Geplante ADRs (im Backlog)

| ID | Titel | Wann | Trigger |
|---|---|---|---|
| 0018 | RevenueCat als Subscription-Infrastruktur | Phase 2 | Membership-Implementation |
| 0019 | KI-Provider final (Mistral / Claude / Aleph Alpha) | Phase 2 | KI-Layer-Start |

## Status-Verteilung

| Status | Anzahl |
|---|---|
| accepted | 27 |
| rejected | 1 |
| proposed | 0 |
| superseded | 2 |
| deprecated | 0 |

## Tags-Index (häufigste)

- **architecture** → 0001, 0014, 0015, 0016, 0022
- **scanner / ios** → 0017
- **backend / database** → 0002, 0022, 0032
- **data / api** → 0003, 0016, 0022, 0024, 0025, 0028, 0030
- **ai / scope** → 0004, 0005, 0006
- **monetization** → 0006
- **ci-cd / testing** → 0007, 0020, 0021, 0026, 0029
- **security / dsgvo** → 0008, 0026, 0032
- **methodology** → 0009, 0011, 0023, 0025, 0028, 0029
- **scoring / esg** → 0010, 0011, 0023, 0025, 0027, 0028
- **compliance / governance** → 0009, 0029, 0030, 0031, 0032

## Wartung

- Bei neuem ADR: Eintrag in `## Aktive ADRs`, Status-Verteilung aktualisieren
- Bei Status-Wechsel (z.B. `accepted` → `superseded`): hier ändern + `supersedes`/`superseded_by` in beiden Dateien setzen
- Datum „Letztes Update" oben aktualisieren
