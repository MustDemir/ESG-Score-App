# 🌱 ESG-Score App

> **Scan. Bewerte. Entscheide nachhaltig.**

Eine mobile App, die Konsumenten ermöglicht, den Barcode eines Produkts zu scannen und sofort eine verständliche Nachhaltigkeitsbewertung (Environmental, Social, Governance) zu erhalten.

**ScanFair** ist der geplante Produkt- und App-Name innerhalb dieses Projekts. Das Repository dokumentiert weiterhin die fachliche ESG-Score-App, während ScanFair die nutzerseitige Marke, UI-Sprache und Prototypen bündelt.

---

## 🎯 Projektziel

Konsumenten treffen täglich Kaufentscheidungen – aber Nachhaltigkeitsinformationen sind fragmentiert, unverständlich oder schlicht nicht vorhanden. Die ESG-Score App löst dieses Problem: **Ein Scan, ein Score, eine Entscheidung.**

### Das Problem
- 85% der Konsumenten wollen nachhaltiger einkaufen ([McKinsey, 2023](https://www.mckinsey.com/capabilities/sustainability/our-insights/consumers-care-about-sustainability-and-back-it-up-with-their-wallets))
- Aber: Siegel-Dschungel, Greenwashing, keine Vergleichbarkeit
- Bestehende Apps zeigen Einzelaspekte (nur CO2, nur Bio) – nie das Gesamtbild

### Die Lösung
| Feature | Beschreibung |
|---------|-------------|
| 📱 Barcode scannen | EAN-13 Barcode mit der Handy-Kamera scannen |
| 🔢 ESG-Score sehen | Gesamtscore 0-10 mit Ampelsystem (🟢🟡🔴) |
| 📊 Details verstehen | Aufschlüsselung nach E, S, G mit Datenquellen |
| 🔍 Transparent bleiben | Jeder Score zeigt seine Quellen. Fehlende Daten werden ehrlich angezeigt |

---

## 📐 Architektur & Tech Stack

| Komponente | Technologie | Warum |
|-----------|------------|-------|
| Frontend | Flutter (Dart) | Cross-platform, MVP nur iOS |
| Backend | Supabase (EU) | DSGVO-konform, kostenloser Tier |
| Produkt-API | Open Food Facts | Kostenlos, ~600.000 DE-Produkte |
| Barcode Scanner | mobile_scanner | Bewährtes Flutter-Package |
| State Management | Riverpod | Moderner Flutter-Standard |
| Lokaler Cache | Hive | Offline-Fähigkeit |

### System-Überblick
```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   iPhone     │────▶│  Flutter App      │────▶│ Open Food Facts │
│   Kamera     │     │  (Dart)           │     │ API (REST)      │
│   Barcode    │     │                   │     └─────────────────┘
└─────────────┘     │  ESG-Scoring      │
                     │  Engine            │     ┌─────────────────┐
                     │  (regelbasiert)    │────▶│ Supabase (EU)   │
                     │                   │     │ Cache & Auth     │
                     └──────────────────┘     └─────────────────┘
```

---

## 🎨 Design & Prototyping

Die aktuellen Design-Artefakte konkretisieren die App als **ScanFair** und ergänzen den bisherigen Konzeptstand um Discovery, Wireframes, Brand Identity, Score-Visualisierung und Hi-Fi Screens.

| Prototyp | Inhalt |
|----------|--------|
| [Discovery Scroll](docs/00-discovery-scroll.html) | Personas, Customer Journey, Value Proposition, Epics, Roadmap und Risiken |
| [Wireframes](docs/01-wireframes.html) | frühe Screen-Strukturen für Scanner- und Score-Flows |
| [Brand Identity](docs/02-brand-identity.html) | Farben, Typografie, Score-System und UI-Komponenten |
| [Score-Varianten](docs/02-score-variants.html) | Vergleich von Ampel-Karte, Radial-Donut und Editorial-Score |
| [Hi-Fi Screens](docs/04-screens.html) | Multi-Kategorie-Flow für Lebensmittel, Kleidung und Kosmetik |

Die inhaltliche Auswertung der neuen Artefakte steht in [Design-Synthese](docs/DESIGN-SYNTHESIS.md). Wichtigste Entscheidung: **Lebensmittel bleiben der MVP-Kern; Kleidung und Kosmetik sind als validierter Ausbau sichtbar, aber noch als Scope-Entscheidung zu behandeln.**

---

## 📂 Projektstruktur

```
esg-score-app/
├── README.md                          ← Du bist hier
├── docs/
│   ├── 00-discovery-scroll.html        ← ScanFair Discovery-Prototyp
│   ├── 01-wireframes.html              ← Wireframes
│   ├── 02-brand-identity.html          ← Brand Identity
│   ├── 02-score-variants.html          ← Score-Visualisierungen
│   ├── 04-screens.html                 ← Hi-Fi Screens
│   ├── DESIGN-SYNTHESIS.md             ← Inhaltliche Auswertung der Design-Artefakte
│   ├── MVP-REQUIREMENTS.md            ← Technischer Bauplan (Screens, API, Datenmodell)
│   ├── ESG-SCORING-MODELL-v1.md       ← Scoring-Methodik (Gewichtungen, Formeln, Quellen)
│   ├── PROJEKTTAGEBUCH.md             ← Wöchentliche Fortschritte & Learnings
│   └── Design/prototypes/              ← React/CSS/Demo-Daten der HTML-Prototypen
├── lib/                               ← Flutter App-Code (kommt in Phase: Entwicklung)
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── test/                              ← Tests
└── pubspec.yaml                       ← Flutter Dependencies
```

---

## 🗺️ Roadmap

### Phase 1: MVP (aktuell – 8 Wochen)
- [x] Projektplanung & Requirements
- [x] ESG-Scoring-Modell definiert
- [x] MVP Requirements Document erstellt
- [x] Discovery, Wireframes und Brand-Prototypen integriert
- [x] Score-Visualisierung und Hi-Fi Screen-Flow ausgearbeitet
- [ ] Entwicklungsumgebung aufsetzen (Flutter + Xcode)
- [ ] Home Screen & Navigation
- [ ] Barcode-Scanner Integration
- [ ] Open Food Facts API Anbindung
- [ ] E-Score Berechnungslogik
- [ ] Score-Ergebnis & Detail Screens
- [ ] S-Score (vereinfacht) & Fehlerbehandlung
- [ ] Testing & Polish

### Phase 2: Erweiterung (geplant)
- [ ] Vollständiger S-Score (Herkunftsland-Risiko, LkSG)
- [ ] G-Score (CSRD-Datenbank Anbindung)
- [ ] User-Accounts & Personalisierung
- [ ] KI-gestützte Score-Erklärungen (OpenAI API)
- [ ] Alternative Produktvorschläge

### Phase 3: Skalierung (Vision)
- [ ] Gamification & Community
- [ ] AR-Overlays im Supermarkt
- [ ] On-Device ML für Personalisierung
- [ ] Android-Version

---

## 📊 ESG-Scoring auf einen Blick

Das Scoring-Modell aggregiert bestehende, anerkannte Datenquellen – **wir erfinden keine eigenen Bewertungen**.

| Dimension | Gewicht | Datenquellen | MVP-Status |
|-----------|---------|-------------|------------|
| 🌱 **E** (Environmental) | 40% | Eco-Score, CO2-Fußabdruck, Verpackung, Herkunft, Bio-Siegel | ✅ Voll |
| 👥 **S** (Social) | 35% | Fairtrade, Rainforest Alliance, Herkunftsland-Risiko | ⚠️ Teilweise |
| 🏛️ **G** (Governance) | 25% | CSRD-Berichte, B Corp, Transparenz-Index | ❌ Phase 2 |

**Formel:** `Gesamt-Score = (E × 0.40) + (S × 0.35) + (G × 0.25)`

**Ampel-System:**
- 🟢 **7.0 – 10.0**: Gut bis sehr gut
- 🟡 **4.0 – 6.9**: Mittelmäßig
- 🔴 **0.0 – 3.9**: Schlecht

→ Vollständige Methodik: [ESG-SCORING-MODELL-v1.md](docs/ESG-SCORING-MODELL-v1.md)

---

## 🔬 Wissenschaftlicher Hintergrund

Dieses Projekt basiert auf einer Management-Präsentation für den Lebensmittelhandel und verbindet etablierte Methoden:

- **Lean Startup** (Ries, 2011) – iterative Produktentwicklung mit MVP-Ansatz
- **User-Centered Design** (Norman, 2013) – Epics & User Stories nach Scrum (Schwaber & Sutherland, 2020)
- **ESG-Frameworks** – Aggregation bestehender Indizes (ADEME Eco-Score, ITUC Global Rights Index, BAFA Risikolisten)
- **DSGVO & CSRD** – Compliance by Design

---

## 👤 Über den Autor

**Mustafa Demir** – Information Systems & Cloud Architecture Student

Dieses Projekt dokumentiert meinen Weg vom Konzept zur fertigen App. Ich bin kein erfahrener Entwickler, aber ich glaube daran, dass mit den richtigen Tools (Flutter, Claude Code, Supabase) und einer klaren Planung jeder eine App bauen kann, die einen Unterschied macht.

---

## 📝 Lizenz

Dieses Projekt ist aktuell in Entwicklung. Lizenzdetails folgen.

---

## 🔗 Weiterführende Dokumente

| Dokument | Beschreibung |
|----------|-------------|
| [MVP Requirements](docs/MVP-REQUIREMENTS.md) | Technischer Bauplan: Screens, API, Datenmodell, Zeitplan |
| [ESG-Scoring-Modell v1.0](docs/ESG-SCORING-MODELL-v1.md) | Vollständige Scoring-Methodik mit Formeln und Beispielen |
| [Design-Synthese](docs/DESIGN-SYNTHESIS.md) | Auswertung der neuen ScanFair-Prototypen und Unterschiede zum bisherigen Stand |
| [Projekttagebuch](docs/PROJEKTTAGEBUCH.md) | Wöchentliche Fortschritte, Entscheidungen und Learnings |
