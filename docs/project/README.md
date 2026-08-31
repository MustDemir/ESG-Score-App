# ESG-Score-App — Projekt-Dokumentation

Dieser Ordner ist die **Source of Truth** für alle nicht-Code-Artefakte des Projekts: Entscheidungen, Roadmap, Backlog, Risiken, Fortschritt.

Designartefakte (Wireframes, Brand, Screens) liegen eine Ebene höher in `docs/`.

## Struktur

```
docs/project/
├── README.md              # diese Datei — Übersicht
├── STATUS.md              # menschenlesbarer aktueller Projekt- und Reifegradstand
├── methodology/           # WIE wir dokumentieren (Prozess-Dokus)
│   ├── README.md
│   ├── product-engineering-handbook.md
│   ├── gap-analysis-process.md
│   ├── vorgehenssystem.md
│   ├── adr-process.md
│   ├── backlog-process.md
│   ├── progress-tracking.md
│   └── conventions.md
├── decisions/             # ADRs (Architecture Decision Records) — append-only
│   └── NNNN-titel.yaml
├── roadmap.yaml           # Phasen-Plan, Meilensteine
├── improvement-register.yaml # Bewertete Verbesserungen, Reihenfolge und Evidenz
├── gap-register.yaml       # Reifegrad-Lücken, Trigger und Closure-Verträge
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
├── accessibility/         # VoiceOver language and terminology policy
├── data/                  # Quellenregister, Datenarchitektur, Lizenzvertrag und Pilot-Fixtures
├── security/              # Backend-Threat-Model, Umgebungsvertrag und Aktivierungsevidenz
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
├── compliance/            # Apple-, DSGVO-, Claim-, Privacy-, Supply-Chain- und MASVS-Mapping
│   ├── apple-review-relevance.md
│   ├── claim-inventory.yaml
│   ├── privacy-data-inventory.yaml
│   ├── privacy-data-flow.md
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

## Vorgehensmodell

Das [ScanFair Product Engineering Handbook](methodology/product-engineering-handbook.md)
ordnet Product Ownership, UX/Accessibility, Mobile Engineering, ESG-Methodik,
Data Governance, Testing, Compliance, DevSecOps und Release Governance in einen
gemeinsamen Lifecycle ein. Das
[Delivery Operating Model](delivery-operating-model.md) enthält die
verbindlichen Regeln; das Handbuch erklärt ihre praktische Anwendung und den
belegten Projektstand.

Die [ScanFair Lifecycle Gap Analysis](methodology/gap-analysis-process.md)
prüft dieses Modell wiederholt auf blinde Flecken. Der aktuelle Befund liegt im
[Gap-Register](gap-register.yaml) und im datierten
[Product Engineering Gap Audit](audits/2026-08-10-product-engineering-gap-analysis.md).
Die aktuelle OFF-/ODbL-Entscheidung und ihre Remote-Blocker sind im
[Data-License Composition Assessment](audits/2026-08-11-data-license-composition-assessment.md)
festgehalten.
Claim-, Nährwert- und Privacy-Aktivierungsgrenzen mit verbleibender Rechts-,
Fach- und DPIA-Evidenz stehen im
[Claims and Privacy Boundary Assessment](audits/2026-08-11-claims-privacy-boundaries-assessment.md).
Das [Backend Threat Model Assessment](audits/2026-08-11-backend-threat-model-assessment.md)
dokumentiert die Trust Boundaries, priorisierten Missbrauchsfaelle und die
fail-closed Freigabegrenze fuer den geplanten EU-Supabase-Serverpfad.

## Öffentliche und interne Dokumentation

Die Root-Dateien [`README.md`](../../README.md) und
[`README.de.md`](../../README.de.md) sind öffentliche technische Fallstudien
für Recruiting sowie Fach- und Engineering-Verantwortliche. Operative
Fortschritts- und Gate-Details bleiben in diesem Ordner. Dadurch muss die
öffentliche Darstellung nicht zugleich als internes Projekthandbuch dienen.

Der aktuelle menschenlesbare Stand liegt in [`STATUS.md`](STATUS.md), die
maschinenlesbare Wahrheit in [`progress.yaml`](progress.yaml) und
[`backlog.yaml`](backlog.yaml).

## Schnellzugriff für Claude Code

Wenn du eine neue Claude-Code-Session startest: weise Claude auf diesen Ordner hin
(`Lies docs/project/README.md und docs/project/progress.yaml`), dann hat es sofort
den vollen Projektkontext.
