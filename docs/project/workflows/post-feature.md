# Workflow: Post-Feature (A-F)

> Übernommen aus ai-context-vault `thesis-post-session` (A-F). Ergänzt
> unsere bestehende [`definition-of-done.yaml`](../definition-of-done.yaml)
> um klare Phasen-Struktur. ADR-Referenz: [0009](../decisions/0009-methodology-adoption.yaml).
> Trigger-Phrasen: „fertig für heute", „Session Ende", „Post-Check", „Repo aktualisieren".

## Zweck

Nach jedem fertigen Feature / Coding-Block sicherstellen dass alle
Artefakte im Repo konsistent sind. Verhindert: chapter_state veraltet,
Decisions vergessen, weekly_log fehlt, nächste Session startet im Blindflug.

## Workflow — 6 Prüfpunkte

### A — Code & Tests

- [ ] Code committed (kein unstaged-Drift)
- [ ] `flutter analyze` lokal grün
- [ ] `flutter format` keine Differenzen
- [ ] `flutter test` grün, Coverage erfüllt Sprint-Ziel
- [ ] PR erstellt oder direkt auf Branch (je nach Workflow)
- [ ] CI grün (oder bewusst aufgeschoben mit Begründung)

### B — Feature-State aktualisieren

(Sobald Feature-State-Pattern existiert, ab Sprint 0 / S09)

- [ ] `features/<feature>/state.yaml.status` korrekt (`in_progress` → `draft` → `review` → `done`)
- [ ] `progress` (%-Wert) aktualisiert
- [ ] `done`-Liste um neue Meilensteine ergänzt
- [ ] `next_steps` zeigt was als nächstes ansteht
- [ ] `decisions` falls neue Entscheidungen getroffen wurden
- [ ] `open_items` aktualisiert

### C — Entscheidungs-Register

Falls in der Session eine Architektur-Entscheidung getroffen wurde:

- [ ] Neue ADR (`NNNN-titel.yaml`) im `decisions/`-Ordner geschrieben
- [ ] [`decisions/INDEX.md`](../decisions/INDEX.md) Tabelle aktualisiert
- [ ] Status-Verteilung in INDEX.md hochgezählt
- [ ] `related`-Verlinkungen in bestehenden ADRs ergänzt

### D — progress.yaml + weekly_log

- [ ] Neuer `weekly_log`-Eintrag (oder bestehenden erweitert wenn gleiche Woche)
  - `summary`: 1-Zeiler
  - `done`: 3-5 Bullet-Points
  - `learnings`: ehrliche Reflexion
  - `blockers`: was hindert mich aktuell
  - `next_week`: konkrete Ziele
- [ ] `milestones` falls bedeutsamer Meilenstein erreicht
- [ ] `decisions_made` falls neue ADR
- [ ] `stats` aktualisiert (decisions_total, todos_open/done, etc.)

### E — Konsistenz-Diff

Vorher-Nachher-Vergleich:

- [ ] `git diff --stat` ansehen — alle Änderungen erwartet?
- [ ] Stimmt das Delta mit dem Pre-Coding-Plan überein?
- [ ] Sind neue Begriffe konsistent mit bestehenden ADRs?
- [ ] Keine Forward-References auf Code/Doku die nicht existiert?
- [ ] Bei Compliance-Touch: evidence-log.jsonl neuer Eintrag?

### F — Save & Commit

- [ ] Commit-Message folgt Konvention (siehe [`methodology/conventions.md`](../methodology/conventions.md))
  - `feat(<scope>):`, `fix(<scope>):`, `docs(<scope>):`, `chore(<scope>):`
  - Body erklärt WHY, nicht nur WHAT
  - Co-Author-Tag wenn mit Claude
- [ ] Push (falls remote relevant)
- [ ] Bei Risk-Mitigation: `risks.yaml` Status aktualisiert
- [ ] Bei TODO-Abschluss: `backlog.yaml` Status auf `done`

## Output: Post-Feature-Protokoll

```markdown
## Post-Feature-Protokoll — [Feature/Step]

### A: Code & Tests
- ✅ Coverage: 73% (Ziel 70%)
- ✅ CI grün

### B: Feature-State
- features/scanner/state.yaml: in_progress → draft (50% → 80%)

### C: Entscheidungen
- Neu: ADR 0012 (State Management = Riverpod)

### D: progress.yaml
- weekly_log[0] erweitert um 3 done-Items
- stats: decisions_total 11 → 12

### E: Diff
- 12 files changed, +340/-12
- Erwartet, deckt sich mit Pre-Coding-Plan

### F: Commit
- feat(scanner): mobile_scanner-Integration mit Riverpod
- Committed, gepusht

### Bereit für nächste Session?
[ja]
```

## Eskalations-Regel (übernommen aus DoD)

Wenn ein Prüfpunkt nicht erfüllt werden kann:
1. NICHT als „fertig" markieren
2. Im `progress.yaml` weekly_log Grund dokumentieren
3. Als TODO mit P1 in `backlog.yaml` anlegen
4. Bei Security/Compliance betroffen: Eskalation an User BEVOR weitergemacht

## Wann diesen Workflow ÜBERSPRINGEN?

- Bei trivialen Doku-Patches (1-Zeilen-Tippfehler)
- Bei Spike-Outputs (eigener Spike-DoD-Typ)

Sonst: pflicht am Ende jedes Coding-Blocks.

## lade_manifest

```yaml
pflicht:
  - docs/project/progress.yaml
  - docs/project/definition-of-done.yaml
  - features/<feature>/state.yaml (sobald existiert)
  - betroffene ADRs (für Konsistenz-Check)
kontext:
  - docs/project/methodology/conventions.md (für Commit-Format)
  - docs/project/decisions/INDEX.md
```
