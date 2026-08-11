# Methodik — Wie wir dokumentieren

Dieser Ordner beschreibt **das Vorgehen**: wie ADRs entstehen, wie der Backlog
gepflegt wird, wie der Fortschritt getrackt wird, welche YAML-Konventionen gelten.

## Dateien

- [product-engineering-handbook.md](product-engineering-handbook.md) — praktisches
  Gesamthandbuch: Disziplinen, Methoden, Branches, Lifecycle, Ist-Stand und
  Reifepfad
- [gap-analysis-process.md](gap-analysis-process.md) — wiederholbare
  Lifecycle-Gap-Analyse mit zwölf Prüffeldern, Reifegrad und Closure-Regeln
- [vorgehenssystem.md](vorgehenssystem.md) — Herkunft und Synthese des
  repo-nativen Vorgehenssystems
- [adr-process.md](adr-process.md) — Architecture Decision Records erstellen
- [backlog-process.md](backlog-process.md) — Ideen und TODOs verwalten
- [progress-tracking.md](progress-tracking.md) — Fortschritt tracken
- [conventions.md](conventions.md) — YAML-Format, IDs, Namensgebung

## Warum diese Methodik?

**Problem:** Solo-Founder vergessen nach 4 Wochen warum sie X entschieden haben.
LLM-Sessions starten ohne Kontext. Ideen versanden in Notion/Notes/Köpfen.

**Lösung:** Alles im Repo als YAML. Versioniert. Diff-bar. Claude Code lesbar.

**Trade-off:** Keine UI, kein Drag-and-Drop. Dafür: kein Vendor-Lock-in,
funktioniert offline, gehört dir komplett.

## Wann was nutzen?

| Situation | Tool |
|---|---|
| „Wir haben X statt Y gewählt, weil…" | ADR (`decisions/`) |
| „Cool wäre noch…" | `backlog.yaml` (ideas) |
| „Muss diese Woche erledigen" | `backlog.yaml` (todos) ODER GitHub Issue |
| „Was kann schief gehen?" | `risks.yaml` |
| „Wo stehen wir gerade?" | `progress.yaml` |
| „Was ist die nächste Phase?" | `roadmap.yaml` |
| „Was bedeutet eigentlich XYZ?" | `glossary.yaml` |
| „Was haben wir noch nicht bedacht?" | `gap-analysis-process.md` + `gap-register.yaml` |
