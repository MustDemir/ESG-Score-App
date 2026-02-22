# ESG-Score App – Pitch & Konzeptdokument

> **Version 2.0 | Februar 2026 | Mustafa Demir**
>
> Aktualisiertes Konzeptdokument basierend auf der Management-Präsentation
> vom November 2025 (Modul: Design Thinking & Innovation, SRH Fernhochschule)
> und dem aktuellen Entwicklungsstand des MVP.

---

## 1. Das Problem: Ethische Informationsasymmetrien

### Die Realität

Unsere Lieferketten sind intransparent und ethisch problematisch. Kinderarbeit in der Kakaoindustrie, Ausbeutung auf Kaffeeplantagen, Zwangsarbeit in der Fischerei -- Konsumenten finanzieren diese Praktiken unwissentlich mit jedem Einkauf.

### Der Pain Point

- **73%** der Verbraucher sind bereit, mehr für nachhaltige Produkte zu zahlen
- Aber nur **12%** finden verlässliche Informationen am Point of Sale
- **61% Informationslücke** = der größte Pain Point im nachhaltigen Konsum

> "Konsumenten fehlt es an Transparenz bezüglich der ökologischen und ethischen Auswirkungen ihrer Kaufentscheidungen."
> -- Wolniak, Stecula & Aydin (2024)

### Bestehende Lösungen reichen nicht

- Siegel-Dschungel: Fragmentiert, intransparent, schwer vergleichbar
- Bestehende Apps zeigen nur Einzelaspekte (nur CO2 oder nur Bio) -- nie das Gesamtbild
- Keine App kombiniert Environmental, Social UND Governance in einem Score

**Die ESG-Score App löst genau diese Lücke.**

---

## 2. Unsere Vision

> Die Verschmelzung von digitaler Innovation und ethischem Handel, um ein transparentes, faires und nahtloses Einkaufserlebnis zu schaffen.

### Die Challenge

*Wie schaffen wir es, die Transparenz über die ethischen und ökologischen Auswirkungen des Lebensmitteleinkaufs für nachhaltigkeitsbewusste Konsumenten zu verbessern?*

### Die Lösung: Ein Scan, ein Score, eine Entscheidung

| Schritt | Was passiert |
|---------|-------------|
| 1. Barcode scannen | EAN-13 Barcode mit der Handy-Kamera scannen |
| 2. ESG-Score sehen | Gesamtscore 0-10 mit Ampelsystem (Grün/Gelb/Rot) |
| 3. Details verstehen | Aufschlüsselung nach E, S, G mit Datenquellen |
| 4. Transparent bleiben | Jeder Score zeigt seine Quellen. Fehlende Daten werden ehrlich angezeigt |

---

## 3. Markt-Evidenz: Warum jetzt?

### McKinsey/NielsenIQ-Studie (600.000 SKUs analysiert)

- **+28% Wachstum** bei ESG-Produkten vs. 20% ohne ESG
- **+40% höheres Wachstum** durch Transparenz
- **78%** der Konsumenten priorisieren Nachhaltigkeit
- **+34% Kundenloyalität** bei ESG-Feedback
- **Multi-Claim-Effekt:** Produkte mit mehreren ESG-Dimensionen wachsen **2,5x schneller**

### Harvard/Publix Retail-Praxis

- Vertrauen steigert **Kaufwahrscheinlichkeit um +54%**
- **Gen Z/Millennials:** +162% höhere Kaufbereitschaft (unsere Zielgruppe!)
- Social-Aspekt: 5% Fluktuation vs. 65% Branchendurchschnitt

### Key Insight

ESG-Transparenz ist kein Nischenthema mehr -- es ist ein messbarer Wachstumstreiber. Junge Zielgruppen (Gen Z/Millennials) zeigen +162% höhere Kaufbereitschaft für transparente Produkte.

*Quellen: Bar Am et al. (2023), McKinsey & Company; Reichheld et al. (2023), Harvard Business Review*

---

## 4. Zielgruppe

### Customer Segments

| Segment | Beschreibung | Motivation |
|---------|-------------|------------|
| **Millennials** (28-42) | Bewusste Konsumenten mit Kaufkraft | Wollen nachhaltig leben, aber effizient bleiben |
| **Gen Z** (18-27) | Digital Natives, wertegetrieben | Erwarten Transparenz als Standard |
| **Bewusste Familien** | Eltern, die für ihre Kinder bessere Produkte wollen | Gesundheit + Nachhaltigkeit kombinieren |

### Personas (aus der Design-Thinking-Analyse)

**Thomas, 28** -- Single, Spontankäufer, gesundheitsbewusster Meal-Prepper
- Nutzt die App beim Einkauf für schnelle ESG-Checks
- Will wissen: "Ist das Produkt wirklich nachhaltig oder nur Greenwashing?"

**Klaus, 68** -- Rentner, tägliche kleine Einkäufe
- Will fundierte Kaufentscheidungen treffen
- Schätzt die einfache Ampel-Darstellung

**Anna, 35** -- Berufstätige Mutter, Wocheneinkauf mit Budget
- Braucht schnelle Orientierung zwischen Preis und Nachhaltigkeit
- Nutzt die Scan-Historie für wiederkehrende Einkäufe

---

## 5. Value Proposition

### Value Proposition Canvas

| KUNDE | ESG-APP |
|-------|---------|
| **Pains:** Informationsmangel, Zeitdruck, Greenwashing-Angst | **Pain Relievers:** Transparenz in Sekunden, vertrauenswürdige Quellen |
| **Gains:** Gutes Gewissen, Zeitersparnis, Orientierung | **Gain Creators:** Ampelsystem, Score-Details, Scan-Historie |
| **Jobs to be Done:** Nachhaltig einkaufen ohne Aufwand | **Products & Services:** App, ESG-Datenbank, regelbasiertes Scoring |

### Unsere Prinzipien

1. **Wir erfinden KEINE eigenen Bewertungen** -- wir aggregieren bestehende, anerkannte Datenquellen
2. **Jede Bewertung ist transparent** -- der Nutzer sieht immer die Quelle
3. **Fehlende Daten werden ehrlich kommuniziert**, nicht geschätzt
4. **DSGVO by Design** -- keine personenbezogenen Daten in Phase 1

---

## 6. Das Produkt: ESG-Score App (MVP)

### User Flow

```
App öffnen (Home Screen)
    |
    v
Scan-Button drücken
    |
    v
Kamera --> Barcode erkannt
    |
    +-- Produkt gefunden? --> JA --> Score-Ergebnis (Ampel) --> Details (E/S/G)
    |
    +-- Produkt gefunden? --> NEIN --> "Produkt nicht gefunden"
    |
    v
Zurück zu Home (Scan-Historie aktualisiert)
```

### 5 Screens im MVP

| # | Screen | Beschreibung |
|---|--------|-------------|
| S1 | **Home / Scanner** | Scan-Button, letzte Scans, Suchfeld |
| S2 | **Kamera / Scan** | Kamera-View, Barcode-Overlay |
| S3 | **Score-Ergebnis** | Produktname, Gesamt-Score + Ampel, E/S/G Einzelscores |
| S4 | **Score-Details** | Sub-Scores, Gewichtung, Datenquellen, Erklärungstexte |
| S5 | **Produkt nicht gefunden** | Fehlermeldung, manuelle Suche |

### ESG-Scoring auf einen Blick

| Dimension | Gewicht | Datenquellen | MVP-Status |
|-----------|---------|-------------|------------|
| **E** (Environmental) | 40% | Eco-Score, CO2, Verpackung, Herkunft, Bio-Siegel | Voll implementiert |
| **S** (Social) | 35% | Fairtrade, Rainforest Alliance, Herkunftsland-Risiko | Teilweise (nur Labels) |
| **G** (Governance) | 25% | CSRD-Berichte, B Corp, Transparenz-Index | Phase 2 (Platzhalter) |

**Formel:** `Gesamt-Score = (E x 0.40) + (S x 0.35) + (G x 0.25)`

**Ampel-System:**
- **Grün (7.0-10.0):** Gut bis sehr gut
- **Gelb (4.0-6.9):** Mittelmäßig
- **Rot (0.0-3.9):** Schlecht

> Vollständige Scoring-Methodik: [ESG-SCORING-MODELL-v1.md](ESG-SCORING-MODELL-v1.md)

---

## 7. Tech-Stack & Architektur

| Komponente | Technologie | Begründung |
|-----------|------------|------------|
| Frontend | Flutter (Dart) | Cross-platform, MVP nur iOS |
| Backend | Supabase (EU Frankfurt) | DSGVO-konform, kostenloser Tier |
| Produkt-API | Open Food Facts | Kostenlos, ~600.000 DE-Produkte |
| Barcode Scanner | mobile_scanner | Bewährtes Flutter-Package |
| State Management | Riverpod | Moderner Flutter-Standard |
| Lokaler Cache | Hive | Offline-Fähigkeit |
| Versionierung | GitHub | Code-Sicherung, CI/CD-ready |
| Entwicklung | Claude Code + VS Code | KI-gestützte Entwicklung |

### System-Überblick

```
+-------------+     +------------------+     +-----------------+
|   iPhone     |---->|  Flutter App      |---->| Open Food Facts |
|   Kamera     |     |  (Dart)           |     | API (REST)      |
|   Barcode    |     |                   |     +-----------------+
+-------------+     |  ESG-Scoring      |
                     |  Engine            |     +-----------------+
                     |  (regelbasiert)    |---->| Supabase (EU)   |
                     |                   |     | Cache & Auth     |
                     +------------------+     +-----------------+
```

---

## 8. Abgrenzung: MVP vs. Zukunft

### Was das MVP KANN (Phase 1)

- Barcode scannen und Produkt identifizieren
- E-Score vollständig berechnen (5 Sub-Scores)
- S-Score teilweise (soziale Siegel)
- Ampel-Anzeige mit Score-Details
- Scan-Historie (letzte 10 Produkte)
- Offline-Zugriff auf bereits gescannte Produkte
- Transparente Quellenangabe bei jedem Score

### Was das MVP NICHT KANN (Phase 2+)

| Feature | Phase | Aus Original-Pitch |
|---------|-------|--------------------|
| KI-Orchestrierung / NLP | Phase 2 | Folie 19: KI-Middleware |
| Bilderkennung (Google Vision) | Phase 2 | Folie 19: Produkterkennung |
| Personalisierung / ML | Phase 2 | Folie 19: ML-Präferenzanalyse |
| Gamification & Community | Phase 3 | Folie 11: Impact-Tracker |
| AR-Overlays | Phase 3 | Folie 17: Sustainability-Badges |
| Kassenbonscan | Phase 3 | Folie 16: Meal-Prep |
| Vollständiger G-Score (CSRD) | Phase 2 | Folie 15: ESG-Bewertungssystem |
| Alternative Produktvorschläge | Phase 2 | Folie 15: Personalisierung |
| User-Accounts & Profile | Phase 2 | Folie 14: Nutzerprofil-Epic |

---

## 9. Entwicklungsplan

### Phase 1: MVP (8 Wochen, aktuell)

| Woche | Aufgabe | Ergebnis |
|-------|---------|----------|
| W1 | Flutter + Xcode Setup, Projektstruktur | App startet im Simulator |
| W2 | Home Screen, Navigation, Design-System | Navigierbarer Home Screen |
| W3 | Barcode-Scanner Integration | Barcode wird erkannt |
| W4 | Open Food Facts API Anbindung | Produktdaten geladen |
| W5 | E-Score Berechnungslogik | E-Score korrekt berechnet |
| W6 | Score-Ergebnis + Details Screens | Score visuell angezeigt |
| W7 | S-Score, Fehlerbehandlung, Cache | App funktioniert end-to-end |
| W8 | Testing, Bug-Fixing, UI-Polish | MVP fertig |

### Phase 2: Erweiterung (geplant)

- Vollständiger S-Score (Herkunftsland-Risiko, LkSG)
- G-Score (CSRD-Datenbank Anbindung)
- User-Accounts & Personalisierung
- KI-gestützte Score-Erklärungen
- Alternative Produktvorschläge

### Phase 3: Skalierung (Vision)

- Gamification & Community
- AR-Overlays im Supermarkt
- On-Device ML für Personalisierung
- Android-Version
- B2B-Partnerschaften mit Supermarktketten

---

## 10. Wissenschaftlicher Hintergrund

Dieses Projekt basiert auf einer Management-Präsentation aus dem Modul "Design Thinking & Innovation" (SRH Fernhochschule, Nov 2025) und verbindet etablierte Methoden:

### Methodik

- **Design Thinking** (Schallmo, 2017) -- Nutzerzentrierte Problemanalyse und Lösungsfindung
- **Requirements Engineering** (Pohl & Rupp, 2021) -- Systematische Anforderungserfassung
- **Lean Startup** (Ries, 2011) -- Iterative Produktentwicklung mit MVP-Ansatz
- **User-Centered Design** (Norman, 2013) -- Epics & User Stories
- **Value Proposition Canvas** (Osterwalder et al., 2014) -- Product-Market-Fit

### ESG-Frameworks

- **ADEME Eco-Score** -- Lebenszyklusanalyse-basierte Umweltbewertung
- **ITUC Global Rights Index** -- Arbeitnehmerrechte pro Land
- **BAFA Risikoländerlisten** -- Soziale Risikobewertung
- **CSRD** -- EU Corporate Sustainability Reporting Directive
- **LkSG** -- Lieferkettensorgfaltspflichtengesetz

### Regulatorischer Kontext

- **DSGVO** -- Privacy by Design, keine personenbezogenen Daten in Phase 1
- **EU AI Act** -- Relevant für Phase 2 (KI-Features), Compliance by Design
- **CSRD (ab 2025)** -- Wachsende Datenverfügbarkeit für G-Score

---

## 11. Risiken & Mitigationen

| Risiko | Schwere | Mitigation |
|--------|---------|-----------|
| Open Food Facts hat kein Eco-Score für viele DE-Produkte | HOCH | API vorab testen mit 20 typischen Barcodes. Fallback: nur verfügbare Daten, ehrlich kommunizieren |
| CO2-Daten sind Kategoriedurchschnitte | MITTEL | Transparent machen: "Basierend auf Durchschnitt der Kategorie X" |
| Flutter-Lernkurve unterschätzt | MITTEL | Claude Code generiert den Code. Fokus auf Verstehen |
| Scope Creep (zu viele Features) | HOCH | Strikt am MVP-Requirements-Dokument festhalten |
| Greenwashing-Vorwurf | MITTEL | Offene Methodik, transparente Datenquellen, ehrliche Datenlücken |
| Datenqualität & -verfügbarkeit | HOCH | Stufenweiser Datenbankaufbau, Transparenz über Datenlücken |

---

## 12. Vom Uni-Projekt zur echten App

### Was sich seit dem Original-Pitch (Nov 2025) geändert hat

| Aspekt | Original-Pitch (Nov 2025) | Aktueller Stand (Feb 2026) |
|--------|---------------------------|---------------------------|
| **Kontext** | Fiktive Präsentation für Supermarktkette "WeRe" | Eigenständige Consumer-App |
| **Scope** | Breite Vision (AR, KI, Gamification, Meal-Prep) | Fokussiertes MVP: Scan -> Score -> Anzeige |
| **Tech-Stack** | Konzeptionell (KI-Middleware, Google Vision, OpenAI) | Konkret: Flutter, Supabase, Open Food Facts |
| **Scoring** | Konzept-Level | Vollständiges Scoring-Modell mit Formeln und Mappings |
| **Business Case** | WeRe-ROI (400 Mio. Basis, Pilot 80.000 EUR) | Solo-Projekt, Open Source, Community-getrieben |
| **Status** | Präsentation (Papier) | GitHub-Repo, Entwicklung gestartet |

### Was geblieben ist

- Die Kernvision: Transparenz beim Lebensmitteleinkauf durch ESG-Scoring
- Das 3-Dimensionen-Modell (E, S, G) mit Ampelsystem
- Der nutzerzentrierte Ansatz (Barcode scannen -> sofort Score sehen)
- Die Marktvalidierung durch McKinsey/NielsenIQ-Daten
- DSGVO-Konformität als Grundprinzip
- Lean Startup: MVP first, dann iterieren

---

## 13. Links & Weiterführende Dokumente

| Dokument | Beschreibung |
|----------|-------------|
| [MVP Requirements](MVP-REQUIREMENTS.md) | Technischer Bauplan: Screens, API, Datenmodell, Zeitplan |
| [ESG-Scoring-Modell v1.0](ESG-SCORING-MODELL-v1.md) | Vollständige Scoring-Methodik mit Formeln und Beispielen |
| [Projekttagebuch](PROJEKTTAGEBUCH.md) | Wöchentliche Fortschritte, Entscheidungen und Learnings |
| [GitHub Repository](https://github.com/MustDemir/ESG-Score-App) | Source Code und Dokumentation |
| Original-Pitch (Nov 2025) | Management-Präsentation aus Design Thinking & Innovation |

---

> **Mustafa Demir** -- Digital Management & Transformation (M.Sc.), SRH Fernhochschule
>
> Dieses Projekt verbindet akademische Methodik mit realer Produktentwicklung.
> Von der Management-Präsentation zum funktionierenden MVP -- ein Scan, ein Score, eine Entscheidung.
