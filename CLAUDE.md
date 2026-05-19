# ESG-Score App – Projekt-Kontext für Claude Code

---

## ⚠️ SESSION-START-PROTOKOLL (PFLICHT)

**Bevor du irgendetwas anderes tust, lies in dieser Reihenfolge:**

1. [docs/project/README.md](docs/project/README.md) — Übersicht der Projekt-Doku
2. [docs/project/progress.yaml](docs/project/progress.yaml) — wo stehen wir, was war zuletzt erledigt, was kommt als nächstes
3. [docs/project/roadmap.yaml](docs/project/roadmap.yaml) — aktuelle Phase + Out-of-Scope
4. [docs/project/backlog.yaml](docs/project/backlog.yaml) — offene TODOs in der aktuellen Phase
5. [docs/project/session-start-protocol.md](docs/project/session-start-protocol.md) — vollständige Checkliste

**Bei jedem Coding-Task ZUSÄTZLICH:**

- [docs/project/quality-strategy.md](docs/project/quality-strategy.md) — Test-Pyramide, Coverage-Gates, CI-Anforderungen
- [docs/project/definition-of-done.yaml](docs/project/definition-of-done.yaml) — was muss erfüllt sein bevor ein Task „fertig" ist
- [docs/project/failure-modes.yaml](docs/project/failure-modes.yaml) — typische Fehler vermeiden
- [docs/project/decisions/](docs/project/decisions/) — bestehende ADRs respektieren, nicht widersprechen

**Bei Architektur-Entscheidungen:** schreibe eine ADR nach dem Schema in
[docs/project/methodology/adr-process.md](docs/project/methodology/adr-process.md) — bevor du Code schreibst.

---

## Was ist dieses Projekt?

Eine mobile App (iOS + Android) die Supermarkt-Produkte per Barcode scannt
und einen ESG-Score (Environmental, Social, Governance) anzeigt.
Branding: **ScanFair**. Die App hilft Konsumenten, nachhaltigere
Kaufentscheidungen zu treffen.

## Tech-Stack (verbindlich)

| Schicht | Wahl | ADR |
|---|---|---|
| Frontend | Flutter (Dart) | [0001](docs/project/decisions/0001-flutter-frontend.yaml) |
| Backend | Supabase (EU Frankfurt) | [0002](docs/project/decisions/0002-supabase-backend.yaml) |
| Produktdaten | Open Food Facts | [0003](docs/project/decisions/0003-open-food-facts.yaml) |
| KI-Layer in MVP | **NEIN** (erst Phase 2) | [0004](docs/project/decisions/0004-no-ai-phase-1.yaml) |
| Monetarisierung | Freemium + Membership | [0006](docs/project/decisions/0006-monetization-via-membership.yaml) |
| CI/CD/CT | Minimal von Tag 1 | [0007](docs/project/decisions/0007-cicd-ct-strategy.yaml) |
| Security-Baseline | 7 nicht-verhandelbare Praktiken | [0008](docs/project/decisions/0008-security-baseline.yaml) |

Detaillierte Versionen: [docs/project/stack.yaml](docs/project/stack.yaml).

## Projektstruktur

```
/Users/mustafademir/ESG-Score-App/
├── CLAUDE.md                  # diese Datei — Eingangspunkt
├── docs/
│   ├── project/               # Projekt-SSOT (ADRs, Roadmap, Backlog, …)
│   │   ├── README.md          # Index
│   │   ├── progress.yaml      # IMMER LESEN am Session-Start
│   │   ├── roadmap.yaml
│   │   ├── backlog.yaml
│   │   ├── decisions/         # ADRs
│   │   ├── methodology/       # Wie wir dokumentieren
│   │   ├── quality-strategy.md
│   │   ├── failure-modes.yaml
│   │   ├── definition-of-done.yaml
│   │   └── …
│   └── …                      # Design-Artefakte
├── design_handoff_scanfair/   # Tokens, Screens, Brand
├── scripts/                   # Helfer-Skripte (Spikes, etc.)
└── esg_app/                   # Flutter-Projekt (kommt in Sprint 0)
```

## MVP-Scope (Phase 1)

Quelle: [roadmap.yaml](docs/project/roadmap.yaml).

1. Barcode scannen → Produkt aus OFF laden
2. ESG-Score anzeigen (Ampel grün/gelb/rot)
3. Detailansicht E/S/G aufklappen
4. Nachhaltigere Alternative vorschlagen (regelbasiert, OHNE KI)
5. Einfaches Nutzerprofil (Login, Präferenzen)

## Was NICHT in Phase 1 gehört

Quelle: `roadmap.yaml > phases > phase-1-mvp > out_of_scope`.

- KI-/LLM-Layer (Phase 2)
- AR-Overlay
- Kassenbonscan
- Impact-Tracker / Gamification
- Community-Features
- On-Device ML

## Code-Regeln

- Sauberer Dart-Code, kleine Widgets statt Monolithen
- Kommentare auf Deutsch ODER Englisch (konsistent)
- Aussagekräftige Namen, keine Abkürzungs-Magie
- Fehlerbehandlung bei ALLEN API-Aufrufen (Timeout + Retry + UX-Fallback)
- **Niemals** API-Keys im Code — `.env` + `flutter_dotenv` oder `--dart-define`
- Test-Driven für Services und Models (siehe quality-strategy.md)
- Vor PR-Merge: `flutter analyze` + `flutter format` + `flutter test` müssen grün

## Security (non-negotiable)

Siehe [ADR 0008](docs/project/decisions/0008-security-baseline.yaml). Kurz:

1. Keine Secrets im Repo (gitleaks)
2. Env-Stages strikt getrennt
3. Supabase RLS für ALLE Tabellen
4. HTTPS-only, kein Cleartext
5. Wöchentlicher Dependency-Audit
6. Datenminimierung / DSGVO
7. Disaster-Recovery-Plan

## Wichtige Hinweise zum Entwickler

- Mustafa ist Programmier-Anfänger mit Python-Grundkenntnissen
- Erkläre Code-Änderungen kurz und verständlich (DE)
- Bevorzuge einfache, lesbare Lösungen
- Bei Fehlern: erkläre WAS schief lief und WARUM die Lösung wirkt
- Mustafa möchte ohne Klärungsfragen-Bremse arbeiten — triff sinnvolle
  Entscheidungen und mache weiter, statt zu pausieren

## Bei jedem Task-Abschluss

Bevor du einen Task als „fertig" markierst:
- Checkliste in [definition-of-done.yaml](docs/project/definition-of-done.yaml) passend zum Task-Typ durchgehen
- `progress.yaml` updaten (Milestones, Decisions, weekly_log, stats)
- Bei größeren Änderungen: ADR schreiben
- Bei neuen Risiken / Failure-Modes: `risks.yaml` oder `failure-modes.yaml` ergänzen
