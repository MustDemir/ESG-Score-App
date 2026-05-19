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
├── backlog.yaml           # Ideen, TODOs, geparkte Features
├── risks.yaml             # Risiko-Register
├── progress.yaml          # Fortschrittstracker
├── glossary.yaml          # Domänen-Begriffe (ESG, Eco-Score, etc.)
├── stack.yaml             # Tech-Stack-Inventar mit Versionen
├── costs.yaml             # Kosten-Tracker (Subscriptions, API-Usage)
├── monetization.yaml      # Geschäftsmodell, Tiers, Pricing
├── quality-strategy.md    # CI/CD/CT-Methodik, Test-Pyramide, Release-Gates
├── failure-modes.yaml     # Top-Solo-Founder-Fehler + unsere Gegenmaßnahmen
└── spikes/                # Spike-Reports (z.B. OFF-API-Coverage)
```

## Goldene Regeln

1. **Entscheidungen sind unveränderlich.** Änderung = neue ADR mit `supersedes:`.
2. **Backlog ist Wegwerf-Material.** Ideen dürfen gelöscht werden.
3. **Roadmap-Update max. 1× pro Phase.** Nicht wöchentlich anfassen.
4. **IDs nie wiederverwenden** — auch nicht nach Löschen.
5. **Bei jedem neuen Eintrag: Datum im ISO-Format** (`YYYY-MM-DD`).
6. **YAML ist Source of Truth.** GitHub Issues nur für aktuell aktive Arbeit.

## Schnellzugriff für Claude Code

Wenn du eine neue Claude-Code-Session startest: weise Claude auf diesen Ordner hin
(`Lies docs/project/README.md und docs/project/progress.yaml`), dann hat es sofort
den vollen Projektkontext.
