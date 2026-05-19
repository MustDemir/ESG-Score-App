# ADR Index — ScanFair / ESG-Score-App

> Flache Übersicht aller Architecture Decision Records. Bei jedem neuen
> ADR diese Tabelle aktualisieren. Übernommen aus ai-context-vault-Pattern
> (entscheidungsregister), siehe [ADR 0009](0009-methodology-adoption.yaml).

Letztes Update: 2026-05-19

## Aktive ADRs

| ID | Titel | Status | Datum | Tags | Related |
|---|---|---|---|---|---|
| [0001](0001-flutter-frontend.yaml) | Flutter als Frontend-Framework | accepted | 2026-05-19 | frontend, architecture, mobile | — |
| [0002](0002-supabase-backend.yaml) | Supabase (EU-Frankfurt) als Backend | accepted | 2026-05-19 | backend, database, auth, dsgvo | 0003 |
| [0003](0003-open-food-facts.yaml) | Open Food Facts als primäre Produktdatenquelle | accepted | 2026-05-19 | data, api, dsgvo, licensing | 0002 |
| [0004](0004-no-ai-phase-1.yaml) | Kein KI-/LLM-Layer in Phase 1 (MVP) | accepted | 2026-05-19 | ai, scope, mvp | 0002, 0005 |
| [0005](0005-reject-argonos.yaml) | ArgonOS (ChapsVision) als KI-Plattform abgelehnt | rejected | 2026-05-19 | ai, evaluation, enterprise | 0004 |
| [0006](0006-monetization-via-membership.yaml) | Monetarisierung via Membership (Freemium + ScanFair+) | accepted | 2026-05-19 | monetization, business-model, ai, strategy | 0002, 0004 |
| [0007](0007-cicd-ct-strategy.yaml) | CI/CD/CT-Strategie — minimal aber von Anfang an | accepted | 2026-05-19 | ci-cd, testing, devops, quality | 0001, 0008 |
| [0008](0008-security-baseline.yaml) | Security-Baseline — 7 nicht-verhandelbare Praktiken | accepted | 2026-05-19 | security, dsgvo, secrets, supabase, owasp-masvs | 0002, 0007 |
| [0009](0009-methodology-adoption.yaml) | Methodik-Übernahme aus ai-context-vault + genaiops-compliance-gates | accepted | 2026-05-19 | methodology, adoption, compliance | 0007, 0008 |
| [0010](0010-eco-score-fallback.yaml) | Eco-Score-Fallback-Logik bei unvollständigen Daten | accepted | 2026-05-19 | scoring, esg, data-quality, ux | 0003, 0011 |
| [0011](0011-esg-score-formel.yaml) | ESG-Score-Formel — E/S/G aus OFF-Feldern | accepted | 2026-05-19 | scoring, esg, formel, mvp, methodology | 0003, 0010 |
| [0012](0012-apple-review-compliance.yaml) | Apple Review Compliance Strategy | accepted | 2026-05-19 | compliance, apple, app-store, gates, policy-as-code | 0006, 0007, 0008, 0009 |
| [0013](0013-multi-regulation-strategy.yaml) | Multi-Regulation-Strategy — Cross-Regulation-Mapping | accepted | 2026-05-19 | compliance, methodology, multi-regulation, dsgvo, apple, framework | 0007, 0008, 0009, 0012 |

## Geplante ADRs (im Backlog)

| ID | Titel | Wann | Trigger |
|---|---|---|---|
| 0012 | State-Management-Wahl (Provider vs Riverpod) | Sprint 0/1 | Flutter-Setup, Architektur-Festlegung |
| 0013 | RevenueCat als Subscription-Infrastruktur | Phase 2 | Membership-Implementation |
| 0014 | KI-Provider final (Mistral / Claude / Aleph Alpha) | Phase 2 | KI-Layer-Start |

## Status-Verteilung

| Status | Anzahl |
|---|---|
| accepted | 12 |
| rejected | 1 |
| proposed | 0 |
| superseded | 0 |
| deprecated | 0 |

## Tags-Index (häufigste)

- **architecture** → 0001
- **backend / database** → 0002
- **data / api** → 0003
- **ai / scope** → 0004, 0005, 0006
- **monetization** → 0006
- **ci-cd / testing** → 0007
- **security / dsgvo** → 0008
- **methodology** → 0009, 0011
- **scoring / esg** → 0010, 0011
- **compliance** → 0009

## Wartung

- Bei neuem ADR: Eintrag in `## Aktive ADRs`, Status-Verteilung aktualisieren
- Bei Status-Wechsel (z.B. `accepted` → `superseded`): hier ändern + `supersedes`/`superseded_by` in beiden Dateien setzen
- Datum „Letztes Update" oben aktualisieren
