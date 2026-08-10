# ESG-Score-App — Projekt-Dokumentation

Dieser Ordner ist die **Source of Truth** für alle nicht-Code-Artefakte des Projekts: Entscheidungen, Roadmap, Backlog, Risiken, Fortschritt.

Designartefakte (Wireframes, Brand, Screens) liegen eine Ebene höher in `docs/`.

## Struktur

```
docs/project/
├── README.md              # diese Datei — Übersicht
├── methodology/           # WIE wir dokumentieren (Prozess-Dokus)
│   ├── README.md
│   ├── adr-process.md
│   ├── backlog-process.md
│   ├── progress-tracking.md
│   └── conventions.md
├── decisions/             # ADRs (Architecture Decision Records) — append-only
│   └── NNNN-titel.yaml
├── roadmap.yaml           # Phasen-Plan, Meilensteine
├── improvement-register.yaml # Bewertete Verbesserungen, Reihenfolge und Evidenz
├── backlog.yaml           # Ideen, TODOs, geparkte Features
├── risks.yaml             # Risiko-Register
├── progress.yaml          # Fortschrittstracker
├── glossary.yaml          # Domänen-Begriffe (ESG, Eco-Score, etc.)
├── stack.yaml             # Tech-Stack-Inventar mit Versionen
├── costs.yaml             # Kosten-Tracker (Subscriptions, API-Usage)
├── monetization.yaml      # Geschäftsmodell, Tiers, Pricing
├── quality-strategy.md    # CI/CD/CT-Methodik, Test-Pyramide, Release-Gates
├── failure-modes.yaml     # Top-Solo-Founder-Fehler + unsere Gegenmaßnahmen
├── definition-of-done.yaml # Verbindliche Checks pro Task-Typ
├── session-start-protocol.md # Wiedereinstieg in neue Claude-Sessions
├── audits/                # Dated audit reports with scope and evidence
├── implementation-plan.yaml # 22-Schritte-Plan in 5 Blöcken (Sprint 0 → Phase 2)
├── workflows/             # Strukturierte Arbeits-Rituale (Trigger-Phrasen-basiert)
│   ├── README.md
│   ├── session-start.md
│   ├── pre-coding-check.md
│   └── post-feature.md
├── features/              # Per-Feature-State (analog chapter_state.yaml)
│   ├── README.md
│   ├── scanner/state.yaml
│   ├── scoring/state.yaml
│   └── results/state.yaml
├── compliance/            # Apple-, DSGVO-, Supply-Chain- und MASVS-Mapping
│   ├── apple-review-relevance.md
│   └── owasp-masvs-ios-baseline.yaml
├── requirements/          # Compliance-Anforderungen (R-AS-NN, R-DSGVO-NN, ...)
├── gate-definitions/      # Pruefbare Apple- und lokale Gate-Spezifikationen
│   ├── apple/
│   └── local/
├── policies/              # Rego-Policies (Conftest)
│   └── apple/
└── spikes/                # Spike-Reports (z.B. OFF-API-Coverage)
```

## Goldene Regeln

1. **Entscheidungen sind unveränderlich.** Änderung = neue ADR mit `supersedes:`.
2. **Backlog ist Wegwerf-Material.** Ideen dürfen gelöscht werden.
3. **Roadmap-Update max. 1× pro Phase.** Nicht wöchentlich anfassen.
4. **IDs nie wiederverwenden** — auch nicht nach Löschen.
5. **Bei jedem neuen Eintrag: Datum im ISO-Format** (`YYYY-MM-DD`).
6. **YAML ist Source of Truth.** GitHub Issues nur für aktuell aktive Arbeit.
7. **Verbesserungen bleiben traceable.** Gesamtbewertungen werden im
   `improvement-register.yaml` mit Owner, Status, Akzeptanzkriterien, Evidenz
   und naechster Aktion gefuehrt.

## Schnellzugriff für Claude Code

Wenn du eine neue Claude-Code-Session startest: weise Claude auf diesen Ordner hin
(`Lies docs/project/README.md und docs/project/progress.yaml`), dann hat es sofort
den vollen Projektkontext.
