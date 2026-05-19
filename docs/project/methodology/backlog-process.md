# Backlog-Prozess

## Was gehört in den Backlog?

`backlog.yaml` hat zwei Sektionen: **`ideas`** (langfristig) und **`todos`** (kurzfristig).

### `ideas` — geparkte Features / Konzepte
Alles was „cool wäre" aber **nicht** in der aktuellen Phase geplant ist.
Beispiele: AR-Overlay, Community-Feed, Gamification.

### `todos` — aktive nächste Schritte
Konkrete kleine Aufgaben für die laufende Phase. Wenn ein TODO größer als
~1 Arbeitstag ist → in mehrere zerlegen.

## ID-Schema

- Ideas: `IDEA-NNN` (fortlaufend)
- TODOs: `TODO-NNN` (fortlaufend)
- Nie wiederverwenden, auch nicht nach Löschung

## Bewertungsfelder

| Feld | Werte | Bedeutung |
|---|---|---|
| `effort` | XS / S / M / L / XL | XS = <1h, S = halber Tag, M = 1-3 Tage, L = 1 Woche, XL = mehr |
| `value` | L / M / H | Nutzen für User/Projekt |
| `risk` | L / M / H | Wie viel kann schief gehen |
| `priority` | P0 / P1 / P2 / P3 | P0 = Blocker, P1 = jetzt, P2 = bald, P3 = später |
| `status` | open / in_progress / done / parked / dropped | self-explanatory |

## Pflege-Rhythmus

- **Wöchentlich:** Erledigte TODOs auf `done`, neue rein, geparkte prüfen
- **Phasenwechsel:** Komplette Bereinigung — was ist obsolet?
- **Spontan:** Jede neue Idee sofort als `IDEA-NNN` rein, nicht im Kopf behalten

## Ideen → TODOs → ADRs Flow

```
Spontane Idee
    ↓ (Bewertung)
backlog.yaml ideas        ← die meisten bleiben hier
    ↓ (wird konkret)
backlog.yaml todos        ← in nächster Phase einplanen
    ↓ (architektur-relevant?)
decisions/ ADR            ← wenn ja, vor Umsetzung dokumentieren
    ↓
Code + Commit
```

## Schema-Beispiel siehe `backlog.yaml` selbst.
