# ADR-Prozess (Architecture Decision Records)

## Was ist eine ADR?

Eine ADR dokumentiert eine **bewusst getroffene Entscheidung** mit Begründung,
Alternativen und Konsequenzen. Sie ist **append-only** — wird nie geändert,
nur durch eine neue ADR ersetzt (`supersedes`).

## Wann eine ADR schreiben?

✅ **JA, schreiben:**
- Tech-Stack-Wahl (Framework, Datenbank, Provider)
- Architektur-Pattern (Clean Arch, State Management)
- Externe Abhängigkeiten (APIs, SDKs)
- Bewusste Nicht-Entscheidungen (z.B. „Kein KI-Layer in Phase 1")
- Abgelehnte Optionen mit Begründung (z.B. „ArgonOS verworfen, weil…")

❌ **NEIN, nicht schreiben:**
- Trivialitäten (Variable umbenannt)
- Bugfixes
- Ideen die nur „cool wären" → Backlog
- Tagesgeschäft → Issues/Commits

## Workflow

1. Nächste freie ID im `decisions/`-Ordner schauen (vierstellig, fortlaufend)
2. Datei anlegen: `NNNN-kurzer-titel.yaml` (kebab-case)
3. Schema unten ausfüllen
4. Status `proposed` → nach Bestätigung `accepted`
5. Bei späterer Ablösung: neue ADR mit `supersedes: NNNN`, alte ADR auf
   `superseded_by: MMMM` setzen (einzige erlaubte Änderung an alter ADR)

## Schema

```yaml
id: 0001
title: Kurzer prägnanter Titel
date: 2026-05-19         # ISO-Datum
status: accepted         # proposed | accepted | superseded | deprecated | rejected
deciders: [Mustafa]
tags: [frontend, architecture]   # frei wählbar, hilft beim Filtern

context: |
  Was ist die Ausgangslage? Welches Problem lösen wir?
  Welche Constraints gelten (Zeit, Geld, Skills)?

options_considered:
  - name: Option A
    pros: [...]
    cons: [...]
  - name: Option B
    pros: [...]
    cons: [...]

decision: Option A
rationale: |
  Warum genau diese Option? Was war der Tie-Breaker?

consequences:
  - Was müssen wir jetzt lernen/tun?
  - Welche Türen schließen sich?
  - Welche öffnen sich?

supersedes: null         # ID einer abgelösten ADR oder null
superseded_by: null      # gefüllt wenn eine spätere ADR diese ersetzt
related: [0002, 0003]    # andere ADRs die thematisch verbunden sind
```

## Beispiele anschauen

Siehe `decisions/0001-flutter-frontend.yaml` für ein Vorlage-Beispiel.
