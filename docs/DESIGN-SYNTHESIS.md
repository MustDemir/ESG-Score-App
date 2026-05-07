# Design-Synthese: ScanFair Prototypen

Stand: 2026-05-07

Dieses Dokument fasst die neu integrierten Design- und Discovery-Artefakte zusammen und arbeitet die wichtigsten Abweichungen zum bisherigen Stand der ESG-Score App heraus.

## 1. Einordnung

Die bisherigen Dokumente beschreiben das Projekt als **ESG-Score App**: eine mobile App, die Lebensmittel per Barcode scannt und einen ESG-Score von 0 bis 10 mit Ampelsystem anzeigt.

Die neuen Prototypen konkretisieren daraus eine App-Marke:

- **Projekt/Repository:** ESG-Score App
- **Produkt-/App-Name:** ScanFair
- **Kernversprechen:** Schnelle, verständliche und quellentransparente Nachhaltigkeitsbewertung direkt am Point of Sale.

Damit wird der bisher technische Projektname um eine nutzerfreundlichere Produktmarke ergänzt.

## 2. Neue Artefakte

| Artefakt | Inhalt | Bedeutung |
| --- | --- | --- |
| [00-discovery-scroll.html](00-discovery-scroll.html) | Personas, Customer Journey, Value Proposition, Epics, Roadmap, Risiken | Schärft Zielgruppen, Pain Points und Produktlogik |
| [01-wireframes.html](01-wireframes.html) | frühe Wireframes der Scanner- und Score-Flows | Übersetzt Requirements in konkrete Screen-Strukturen |
| [02-brand-identity.html](02-brand-identity.html) | Brand Essence, Farben, Typografie, UI-Komponenten | Definiert ScanFair als eigenständige Marke |
| [02-score-variants.html](02-score-variants.html) | drei Varianten der Score-Visualisierung | Vergleicht Verständlichkeit, Differenzierung und Detailtiefe |
| [04-screens.html](04-screens.html) | Hi-Fi Screens für mehrere Produktkategorien | Zeigt den erweiterten App-Flow für Lebensmittel, Kleidung und Kosmetik |

Die Einstiegspunkte liegen direkt unter `docs/`. Die zugehörigen React-/CSS-/Demo-Daten liegen unter `docs/Design/prototypes/`.

## 3. Inhaltliche Unterschiede Zum Bisherigen Stand

### Naming und Positionierung

Bisher war **ESG-Score App** zugleich Arbeitsname und Produktname. Die neuen Entwürfe nutzen **ScanFair** als Marke. Das ist für Nutzer leichter merkbar und emotionaler, ohne die fachliche ESG-Logik zu verlieren.

Empfehlung: README und Dokumentation sollten künftig klar trennen:

- ESG-Score App = Projekt und Repository
- ScanFair = App-Marke und Nutzeroberfläche

### MVP-Scope

Bisheriger MVP-Scope:

- Fokus auf Lebensmittel
- Barcode-Scan
- Open Food Facts als wichtigste Datenquelle
- E-Score vollständig, S-Score vereinfacht, G-Score als Platzhalter

Neuer Prototyp-Scope:

- Lebensmittel, Kleidung und Kosmetik als sichtbare Kategorien
- zusätzlicher Erkennungsschritt nach dem Scan
- kategoriespezifische Begleitinformationen:
  - Lebensmittel: Gesundheit/Nutri-Score/NOVA/Zucker
  - Kleidung: Material, Pflege, Mikroplastik, Reparierbarkeit
  - Kosmetik: Inhaltsstoffe, Mikroplastik, Silikone, Tierversuche

Das ist fachlich stark, erhöht aber den MVP-Umfang deutlich. Für die Umsetzung sollte entschieden werden, ob Multi-Kategorie direkt MVP-Bestandteil wird oder als Phase-2-Ausbau dokumentiert bleibt.

### Score-Modell und UX

Bisher:

- ein ESG-Gesamtscore
- E/S/G Einzelscores
- Ampel-System rot/gelb/grün

Neu:

- **Two-Score-Modell:** ESG bleibt der Hauptscore; Health/Material/Inhaltsstoffe sind Begleithinweise und werden nicht in den ESG-Score eingerechnet.
- Score-Darstellung wird als V1/V3-Hybrid empfohlen:
  - V1 Ampel-Karte für schnelle Verständlichkeit
  - V3 Editorial-/Detailansatz für Begründung und Transparenz
- Datenqualität und Quellen werden als sichtbare Vertrauenselemente wichtiger.

Diese Richtung passt gut zur bestehenden Methodik, sollte aber in `MVP-REQUIREMENTS.md` noch explizit nachgezogen werden.

### User Research und Zielgruppen

Die neuen Discovery-Artefakte ergänzen den bisherigen Ansatz um konkrete Personas:

- Klaus: einfache Orientierung, geringe Komplexität, schnelle Kaufentscheidung
- Thomas: Power-User, Planung, Filter, Fitness-/Regionalitätsziele
- Anna: Familienbudget, Zeitdruck, Nachhaltigkeit ohne Rechercheaufwand

Das bestätigt, dass der erste Screen nach dem Scan extrem verständlich sein muss. Tiefe Erklärungen sollten verfügbar sein, aber nicht die schnelle Entscheidung blockieren.

### Design-System

Die Brand Identity ergänzt:

- ScanFair-Farbwelt mit Forest Green, warmen Neutrals und ESG-spezifischen Farben
- Ampel-Logik plus 0-10-Zahl
- Komponenten wie Score-Ring, Score-Bars, Product Card, Pills, Navigation und CTA-Struktur
- iPhone-orientierte Screen-Mockups

Das ist ein guter Vorlauf für Flutter-Komponenten. Die Prototype-Dateien sind aber aktuell HTML/React-Artefakte und noch kein Flutter-Code.

## 4. Entscheidungen Für Die Nächste Umsetzung

| Entscheidung | Empfehlung |
| --- | --- |
| Produktname | ScanFair als App-Marke übernehmen |
| Repository-/Projektname | ESG-Score App beibehalten |
| MVP-Kategorien | Lebensmittel als MVP-Kern, Kleidung/Kosmetik als validierter Ausbau |
| Score-Visualisierung | V1 Ampel-Karte als Default, V3-Elemente in Details |
| Health/Nutrition | Nicht in ESG einrechnen, nur als separater Begleithinweis anzeigen |
| Dokumentation | README aktualisieren, danach MVP Requirements gezielt nachziehen |

## 5. Nächste Dokumentationsaufgaben

1. `MVP-REQUIREMENTS.md` mit ScanFair-Naming und Two-Score-Modell ergänzen.
2. Multi-Kategorie-Scope als Phase-2-Option oder MVP-Stretch Goal festlegen.
3. Design-Tokens aus `tokens.css` in Flutter Theme-Definition übersetzen.
4. Screen-Flows aus `04-screens.html` in Flutter-Screens und Widgets überführen.
