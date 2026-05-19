# Workflow: Session-Start

> Übernommen aus ai-context-vault `thesis-session-manager` (S1-S5).
> ADR-Referenz: [0009](../decisions/0009-methodology-adoption.yaml) — Skill-Pattern-Übernahme.
> Trigger-Phrasen: „Status?", „Wo waren wir?", „Starten wir", „Guten Morgen", „Wo stehen wir?".

## Zweck

Jede neue Claude-Code-Session in diesem Repo beginnt mit einem
strukturierten Wiedereinstieg. Kein zeitraubendes „wo waren wir nochmal?".

## Workflow

### S1 — Kontext laden (pflicht)

Lies in dieser Reihenfolge:

| # | Datei | Was extrahieren |
|---|---|---|
| 1 | [`progress.yaml`](../progress.yaml) | `current_phase`, letzter `weekly_log` Eintrag, `next_week`-Items, `stats` |
| 2 | [`roadmap.yaml`](../roadmap.yaml) | Aktuelle Phase, `out_of_scope`-Liste |
| 3 | [`backlog.yaml`](../backlog.yaml) | TODOs mit Status `in_progress` und `priority: P0/P1` |
| 4 | [`risks.yaml`](../risks.yaml) | Risiken mit Status `open` |
| 5 | [`implementation-plan.yaml`](../implementation-plan.yaml) | Aktuelles Block + nächste 2-3 Steps |

### S2 — Dashboard rendern (pflicht)

Erstelle in der Antwort ein kompaktes Dashboard nach diesem Template:

```markdown
## ScanFair-Dashboard — [ISO-Datum]

### Aktuelle Phase
Phase X (Sprint Y), Woche [ISO-Woche]

### Letzte Session
- Datum: [aus weekly_log[0].week]
- Erledigt: [3 Bullet-Points aus weekly_log[0].done, max]
- Blocker: [aus weekly_log[0].blockers]

### Was als nächstes ansteht
| Priorität | Item | Step-ID |
|---|---|---|
| P0 | … | S0X |
| P0 | … | S0X |
| P1 | … | S0X |

### Offene Risiken (P0/H)
- RISK-XXX — Titel [Status]

### Vorschlag für diese Session
→ [Konkrete Empfehlung welcher Step jetzt drankommt + warum]
```

### S3 — Nächsten Schritt vorschlagen (pflicht)

Aus `implementation-plan.yaml`:
1. Finde nächsten Step mit `status: planned` ohne offene `blocked_by`
2. Lies aus dem Step: `effort`, `target`, `description`, `adr_ref`
3. Zeige im Dashboard unter „Vorschlag für diese Session"

### S4 — Definition of Ready prüfen

Bevor User „GO" sagt: sicherstellen dass der Step ready ist:

- [ ] Akzeptanzkriterien klar (Step hat `description` + `target`)
- [ ] Architektur-relevant: existiert ADR oder muss eine geschrieben werden?
- [ ] `depends_on`-Items erfüllt
- [ ] Step gehört zur aktuellen Phase (kein Out-of-Scope-Drift)

Bei Lücke: User explizit fragen ob Step bereit ist oder erst die Lücke füllen.

### S5 — Pre-Coding-Check anbieten (optional)

Wenn der vorgeschlagene Step ein Coding-Task ist (`feature_code` /
`api_integration` aus DoD), Pre-Coding-Check (`pre-coding-check.md`)
anbieten BEVOR Code geschrieben wird.

## User-Aktion

User antwortet typischerweise mit:

| User sagt | Claude tut |
|---|---|
| „GO" oder „los" | Pre-Coding-Check starten (`pre-coding-check.md`) |
| „Status reicht" | Ende des Workflows, User entscheidet später |
| „Lass uns Z stattdessen machen" | Z prüfen ggü. Out-of-Scope, dann anpassen |
| „Erst mal nur lesen" | Auf User warten |

## lade_manifest

```yaml
pflicht:
  - docs/project/progress.yaml
  - docs/project/roadmap.yaml
  - docs/project/backlog.yaml
  - docs/project/risks.yaml
  - docs/project/implementation-plan.yaml
kontext:
  - docs/project/decisions/INDEX.md
  - docs/project/failure-modes.yaml
```
