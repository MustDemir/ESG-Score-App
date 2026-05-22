# Fortschritts-Tracking

## Zweck

`progress.yaml` ist dein **wöchentlicher Snapshot**: Wo stehst du, was hast du
diese Woche erreicht, was lernst du, was ist als nächstes dran.

Das ist KEIN Tages-Logbuch (das wäre Overhead). Eher: wöchentliche Reflexion,
die du in 10 Minuten machst.

## Wann aktualisieren?

- **Mindestens 1× pro Woche** (z.B. Freitag-Abend oder Montag-Morgen)
- **Beim Phasenwechsel** (kompletter neuer Eintrag)
- **Nach Meilensteinen** (z.B. erstes Mal Scanner funktioniert)

## Struktur

```yaml
current_phase: phase-1-mvp
current_week: 2026-W21       # ISO-Woche
last_updated: 2026-05-19

milestones:                  # große Meilensteine, append-only
  - id: M01
    title: Flutter SDK installiert
    date: 2026-05-19
    phase: phase-1-mvp

decisions_made:              # Verweise auf ADRs, append-only
  - adr: 0001
    title: Flutter als Frontend
    date: 2026-05-19

weekly_log:                  # eine Entry pro Woche, neueste oben
  - week: 2026-W21
    summary: Setup-Phase
    done:
      - Flutter SDK via Homebrew installiert
      - Android Studio + CocoaPods installiert
      - ArgonOS evaluiert und verworfen (siehe ADR 0005)
    learnings:
      - OFF-API-Datenqualität ist kritisches Risiko
      - ArgonOS ist Enterprise-Tool, nicht für Solo-Founder
    blockers:
      - Xcode-Install noch ausstehend
      - Apple Dev Account noch nicht angelegt
    next_week:
      - OFF-API-Spike mit 20 DE-Barcodes
      - ESG-Score-Mapping definieren
      - Flutter-Projekt erstellen

stats:                       # optional, Zahlen statt Worte
  decisions_total: 5
  todos_done: 0
  todos_open: 8
  risks_open: 3
```

## Beispiel-Workflow Freitag-Abend (10 Min)

1. `progress.yaml` öffnen
2. Neuen Eintrag in `weekly_log` ganz oben hinzufügen
3. `done`: was wurde diese Woche fertig? (Schaue auf Commits + erledigte TODOs)
4. `learnings`: was hast du gelernt? (1-3 Bullet-Points, ehrlich)
5. `blockers`: was hindert dich aktuell?
6. `next_week`: 2-3 konkrete Ziele
7. `stats` aktualisieren
8. Commit: `docs: progress update 2026-W21`

## Goldene Regel

**Schreib für dein zukünftiges Ich in 3 Monaten.** Wenn du in 3 Monaten in
dieses File schaust, soll dir klar sein wo du standest und warum du was getan
hast.
