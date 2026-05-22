# Workflow: Pre-Coding-Check (P1-P6)

> Übernommen aus ai-context-vault `thesis-preflight` (P0-P6), übersetzt
> auf App-Entwicklung. ADR-Referenz: [0009](../decisions/0009-methodology-adoption.yaml).
> Trigger-Phrasen: „Pre-Coding-Check für X", „bevor wir Y bauen", „GO vorbereiten",
> „prüf erstmal".

## Zweck

VOR dem Schreiben von Code für ein Feature systematisch die Wissensbasis
durchgehen. Verhindert: vergessene Entscheidungen, ignorierte Anforderungen,
Edge-Cases-Übersehen, Architektur-Drift.

## Voraussetzung

User hat einen konkreten **Zielfeature/Step** benannt (z.B. „S07 GitHub
Actions CI/CD" oder „Feature `scanner`"). Wenn nicht: erst Session-Start
ausführen, dann diesen Workflow.

## Workflow — 6 Prüfinstanzen + lade_manifest

### P0 — Kontext-Fokussierung via lade_manifest

Lies das `lade_manifest` aus dem **Ziel-Feature-State** oder aus dem
**DoD-Task-Typ**:

- `pflicht`-Dateien → als Volltext lesen
- `kontext`-Dateien → nur Metadata (chapter/feature_state + Front-Matter)

Ohne lade_manifest (z.B. Setup-Tasks vor Sprint 0): folgendes Default-Set:
- `progress.yaml`, `roadmap.yaml`, betroffene ADR(s), `failure-modes.yaml`

### P1 — Roadmap & Out-of-Scope-Check

Lies: [`roadmap.yaml`](../roadmap.yaml)

Beantworte:
- Gehört dieser Step zur aktuellen Phase?
- Verletzt er die `out_of_scope`-Liste der Phase?
- Stimmt Vision/Mission noch überein?

**Bei Konflikt:** STOP. User fragen ob Scope-Erweiterung oder Step verwerfen.

### P2 — Bestehende ADRs respektieren

Lies: [`decisions/INDEX.md`](../decisions/INDEX.md)

Identifiziere relevante ADRs (per Tag-Filter) und prüfe:
- Welche ADRs gelten für diesen Code-Bereich?
- Stehen sie im Konflikt mit dem geplanten Vorgehen?
- Müssen wir eine neue ADR schreiben (Architektur-Entscheidung) bevor Code?

**Beispiel-Filter:**

| Step betrifft | Relevante ADRs |
|---|---|
| Auth-Code | 0002, 0008 |
| OFF-Integration | 0003, 0008, 0010, 0011 |
| Scoring-Code | 0010, 0011 |
| CI-Config | 0007, 0008, 0009 |
| Membership | 0006 |
| KI-Layer | 0004 (negativ!), 0009 |

### P3 — Anforderungen & Failure-Modes

Lies:
- [`failure-modes.yaml`](../failure-modes.yaml) — relevante FMs
- [`requirements/R*.yaml`](../requirements/) — falls Compliance-Requirements existieren (Sprint 0+)

Beantworte:
- Welche `failure-modes` sind hier wahrscheinlich? (Liste explizit)
- Welche `requirements` muss der Code erfüllen?
- Welche Defenses aus FMs wenden wir an?

### P4 — Risk-Check

Lies: [`risks.yaml`](../risks.yaml)

Identifiziere offene Risiken die diesen Step betreffen.
Wenn Risiko-Mitigation Teil des Steps ist: Mitigation-Schritt mit
einplanen.

### P5 — Test-Plan vorab

Bevor Code geschrieben wird: definiere Test-Coverage-Plan:
- Welche Unit-Tests sind nötig?
- Widget-Tests?
- Integration-Test (Edge-Cases)?
- Coverage-Erwartung für diesen PR?

Referenz: [`quality-strategy.md`](../quality-strategy.md) §2 Test-Pyramide.

### P6 — Edge-Cases & Negativ-Checklist

Was darf NICHT passieren? Negativ-Checklist:
- Welche bekannten Failure-Modes (FM-XX) MÜSSEN abgedeckt sein?
- Welche Edge-States braucht die UI? (`no_internet`, `no_data`, `permission_denied`, etc.)
- Welche Security-Checks aus ADR 0008 sind relevant?

Bei Scoring-Code (ADR 0010 + 0011): drei UI-States müssen abgedeckt sein.

## Output: Pre-Coding-Protokoll

Schreibe in der Antwort (NICHT als Datei — bleibt im Conversation-Kontext):

```markdown
## Pre-Coding-Protokoll — [Step-ID / Feature]

### Geprüft
- ✅ Roadmap-Scope: in-scope für Phase X
- ✅ Relevante ADRs: 0003, 0010, 0011
- ✅ Failure-Modes adressiert: FM-01, FM-09, FM-14
- ✅ Risks: RISK-XXX wird durch Step mitigated

### Plan
1. [Konkrete Implementation-Steps]
2. …

### Test-Plan
- Unit: …
- Widget: …
- Edge-Cases: …

### Negativ-Checklist
- Darf NICHT: …
- Edge-State UI muss da sein für: …

### Bereit für GO?
[ja / nein — wenn nein: was fehlt?]
```

Bei „bereit" + User-„GO" → Code-Schreiben starten.

## Wann diesen Workflow ÜBERSPRINGEN?

- Bei reinen Doku-Änderungen (Markdown-Updates)
- Bei Bug-Fixes < 10 Zeilen (kurze Begründung im PR reicht)
- Bei Setup-Tasks ohne fachliche Logik (z.B. `flutter create`)

Aber: bei jedem Feature-Coding-Task in Block 3 (S13-S18) ist dieser Check
**pflicht**.

## lade_manifest dieses Workflows

```yaml
pflicht:
  - docs/project/roadmap.yaml
  - docs/project/decisions/INDEX.md
  - docs/project/failure-modes.yaml
  - docs/project/risks.yaml
  - betroffene ADRs (per Tag-Filter aus INDEX.md)
kontext:
  - docs/project/quality-strategy.md
  - docs/project/feature-states/<feature>/state.yaml (sobald existiert)
```
