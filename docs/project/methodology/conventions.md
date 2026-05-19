# YAML-Konventionen

## Datums-Format

Immer **ISO 8601**: `YYYY-MM-DD`. Niemals `19.05.26` oder `May 19`.

Für ISO-Wochen: `2026-W21`.

## IDs

| Typ | Format | Beispiel |
|---|---|---|
| ADR | `NNNN` (4-stellig) | `0001` |
| Idee | `IDEA-NNN` | `IDEA-001` |
| TODO | `TODO-NNN` | `TODO-001` |
| Risiko | `RISK-NNN` | `RISK-001` |
| Meilenstein | `MNN` | `M01` |

**Nie wiederverwenden**, auch nicht nach Löschung. ID-Lücken sind okay.

## Dateinamen

- ADRs: `NNNN-kurzer-titel-kebab-case.yaml`
- YAML allgemein: `kebab-case.yaml`
- Markdown: `kebab-case.md`

## YAML-Stil

- 2 Spaces Indentation, keine Tabs
- Mehrzeilige Texte mit `|` (preserve newlines) oder `>` (folded)
- Listen mit `-` immer auf neuer Zeile (lesbarer als Inline)
- Keine Quotes außer wenn nötig (Sonderzeichen, Zahlen-als-String)

**Gut:**
```yaml
title: Flutter als Frontend
tags:
  - frontend
  - architecture
context: |
  Mehrzeiliger
  Text hier.
```

**Schlecht:**
```yaml
title: "Flutter als Frontend"      # unnötige Quotes
tags: ["frontend","architecture"]   # Inline ist schlechter lesbar
context: "Einzeiliger Text mit \n drin"   # Newline-Escapes hässlich
```

## Status-Werte (Vokabular)

| Kontext | Erlaubte Werte |
|---|---|
| ADR | `proposed`, `accepted`, `superseded`, `deprecated`, `rejected` |
| Idee/TODO | `open`, `in_progress`, `done`, `parked`, `dropped` |
| Risiko | `open`, `mitigated`, `accepted`, `closed` |
| Phase | `planned`, `current`, `done`, `paused` |

## Bewertungs-Skalen

- **Likelihood/Impact (Risiken):** L / M / H
- **Effort:** XS / S / M / L / XL
- **Value:** L / M / H
- **Priority:** P0 (Blocker), P1 (jetzt), P2 (bald), P3 (später)

## Cross-Linking

YAML-Items können sich gegenseitig referenzieren via ID-Liste:

```yaml
decisions: [0001, 0002]
risks: [RISK-001]
todos: [TODO-005]
```

Das macht spätere Auswertung einfacher (z.B. „welche ADRs gehören zu Phase 1?").
