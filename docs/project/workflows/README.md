# Workflows — Strukturierte Arbeits-Rituale

> Markdown-basierte Workflows übernommen aus ai-context-vault `thesis-*`-Skills.
> Bewusste Entscheidung: keine eigenen Claude-Code-Skills (zu viel Overhead),
> stattdessen Markdown-Workflows die Claude bei Trigger-Phrasen ausführt.
> Siehe [ADR 0009](../decisions/0009-methodology-adoption.yaml).

## Verfügbare Workflows

| Workflow | Trigger-Phrasen | Quelle (Vault-Skill) |
|---|---|---|
| [session-start.md](session-start.md) | „Status?", „Wo waren wir?", „Starten wir", „Guten Morgen" | thesis-session-manager (S1-S5) |
| [pre-coding-check.md](pre-coding-check.md) | „Pre-Coding-Check", „bevor wir X bauen", „GO vorbereiten", „prüf erstmal" | thesis-preflight (P0-P6) |
| [post-feature.md](post-feature.md) | „fertig für heute", „Session Ende", „Post-Check", „Repo aktualisieren" | thesis-post-session (A-F) |

## Wann welcher Workflow

```
Session-Anfang
   │
   ▼
 session-start.md   ◄── liefert Status-Dashboard + Vorschlag
   │
   ▼ (User: "GO" oder "los")
 pre-coding-check.md   ◄── prüft alle Voraussetzungen, schreibt Pre-Coding-Protokoll
   │
   ▼ (User: "ja, los")
 Coding-Arbeit (mit Claude-Code-Skills wie /review nach Bedarf)
   │
   ▼ (User: "fertig" oder Block-Ende)
 post-feature.md   ◄── 6 Prüfpunkte A-F + Post-Protokoll
   │
   ▼
 Session-Ende
```

## Was wir BEWUSST nicht übernommen haben

Aus den 7 Vault-Skills NICHT übernommen:

| Vault-Skill | Warum nicht |
|---|---|
| `thesis-writer` (Absatz-Loop mit BELEG/CLAIM/MATCH) | Code ≠ Schreibtext. Test-Coverage + Code-Review erfüllen den Zweck |
| `thesis-consistency` (K1-K7) | Wird durch failure-modes + quality-strategy + ggf. später Cross-Feature-Workflow abgedeckt |
| `thesis-reviewer` (R1-R6) | `engineering:code-review` Skill von Anthropic deckt das ab |
| `evidence-matrix-builder` | Akademisches Quellen-Mapping irrelevant für App-Code |

Die DEFERRED-Workflows (bei Bedarf später):

| Geplant für | Workflow-Name | Wann |
|---|---|---|
| Phase 1.5 / Phase 2 | `cross-feature-consistency.md` | Wenn ≥ 5 Features fertig sind |
| Phase 2 | `compliance-gate-check.md` | Mit Voll-Compliance-Framework |

## Workflows aufrufen (für Claude)

Workflows sind keine ausführbaren Skripte — sie sind **Anleitungen**.

Wenn User eine Trigger-Phrase nennt:
1. Workflow-Datei lesen (Volltext)
2. Workflow ausführen (= Schritte abarbeiten)
3. Output gemäß Workflow rendern

Wenn User KEINE Trigger-Phrase nennt, aber den entsprechenden Kontext schafft
(z.B. fragt nach Status ohne „Status?" zu sagen): Workflow trotzdem
proaktiv anbieten („Soll ich Session-Start-Workflow ausführen?").

## Wartung

- Bei neuem Vault-Pattern: hier dokumentieren ob übernommen oder nicht
- Bei Workflow-Anpassung: ADR 0009 erweitern wenn Trade-off-Änderung
- Bei neuem Skill von Anthropic der einen unserer Workflows überflüssig macht: hier abschalten und auf Skill verweisen
