# ESG-Scoring-Modell v1.0
# Super-SMARTMarket ESG-Score App
# Letzte Aktualisierung: Februar 2026

---

## 1. Grundprinzipien

### Philosophie
- Wir erfinden KEINE eigenen Bewertungen
- Wir aggregieren bestehende, anerkannte Datenquellen zu einem verständlichen Score
- Jede Bewertung ist transparent und nachvollziehbar – der Nutzer sieht immer die Quelle
- Fehlende Daten werden ehrlich kommuniziert, nicht geschätzt

### Score-Skala
- Jede Dimension (E, S, G): **0 bis 10 Punkte**
- Gesamt-ESG-Score: **0 bis 10 Punkte** (gewichteter Durchschnitt)
- Ampelsystem für schnelle Orientierung:
  - 🟢 Grün: 7.0 – 10.0 (gut bis sehr gut)
  - 🟡 Gelb: 4.0 – 6.9 (mittelmäßig)
  - 🔴 Rot: 0.0 – 3.9 (schlecht)

---

## 2. Gewichtung der Dimensionen

| Dimension | Gewicht | Begründung |
|-----------|---------|------------|
| E (Environmental) | 40% | Beste Datenverfügbarkeit, höchste Relevanz für Konsumenten |
| S (Social) | 35% | Emotional wichtig, aber Datenlage oft dünn |
| G (Governance) | 25% | Für Konsumenten am abstraktesten |

### Berechnung Gesamt-Score
```
Gesamt-Score = (E-Score × 0.40) + (S-Score × 0.35) + (G-Score × 0.25)
```

### Bei fehlenden Dimensionen
- 1 Dimension fehlt → Score aus den verbleibenden 2 berechnen, Gewichte proportional anpassen
  - Beispiel: E fehlt → S-Gewicht = 35/(35+25) = 58.3%, G-Gewicht = 25/(35+25) = 41.7%
- 2 Dimensionen fehlen → Kein Gesamtscore, nur die eine verfügbare Dimension anzeigen
- Alle 3 fehlen → Produkt wird angezeigt mit "Noch keine ESG-Daten verfügbar"

**Zertifizierungen (35% des G-Scores):**
| Zertifizierung | Punkte |
|---------------|--------|
| B Corp zertifiziert | 10 |
| ISO 14001 (Umweltmanagement) | 7 |
| Mitglied UN Global Compact | 6 |
| Keine Zertifizierung bekannt | 2 |
| Nicht verfügbar | Dimension wird ausgelassen |

**Transparenz-Index (25% des G-Scores):**
| Transparenz-Level | Punkte |
|-------------------|--------|
| Lieferkette vollständig offengelegt | 10 |
| Lieferkette teilweise offengelegt | 6 |
| Keine Offenlegung | 2 |
| Nicht verfügbar | Dimension wird ausgelassen |

### G-Score Berechnung Beispiel
```
Produkt: Schokolade von Unternehmen X

CSRD: Freiwilliger Bericht → 7 Punkte × 0.40 = 2.80
Zertifizierung: Keine → 2 Punkte × 0.35 = 0.70
Transparenz: Teilweise offengelegt → 6 Punkte × 0.25 = 1.50

G-Score = 2.80 + 0.70 + 1.50 = 5.00 → 🟡 Gelb
```

---

## 3. E-Score (Environmental) – Berechnung

### Datenquellen
| Quelle | Was sie liefert | Gewicht im E-Score |
|--------|----------------|-------------------|
| Eco-Score (Open Food Facts) | Gesamtbewertung A–E basierend auf Lebenszyklusanalyse | 40% |
| CO2-Fußabdruck (Agribalyse/OFF) | kg CO2 pro kg Produkt | 25% |
| Verpackung (Open Food Facts) | Material, Recycelbarkeit | 15% |
| Herkunft/Transport (Open Food Facts) | Herkunftsland, Transportweg | 10% |
| Bio-Siegel (Open Food Facts Labels) | EU-Bio, Demeter, Naturland, Bioland | 10% |

### Umrechnung in Punkte (0–10)

**Eco-Score (40% des E-Scores):**
| Eco-Score | Punkte |
|-----------|--------|
| A | 10 |
| B | 8 |
| C | 6 |
| D | 4 |
| E | 2 |
| Nicht verfügbar | Dimension wird ausgelassen |

**CO2-Fußabdruck (25% des E-Scores):**
| kg CO2 pro kg Produkt | Punkte |
|----------------------|--------|
| < 1.0 | 10 |
| 1.0 – 2.0 | 8 |
| 2.0 – 4.0 | 6 |
| 4.0 – 8.0 | 4 |
| 8.0 – 15.0 | 2 |
| > 15.0 | 1 |
| Nicht verfügbar | Dimension wird ausgelassen |

**Verpackung (15% des E-Scores):**
| Verpackungstyp | Punkte |
|---------------|--------|
| Unverpackt / Mehrweg | 10 |
| Glas (recycelbar) | 8 |
| Papier / Karton | 7 |
| Recyceltes Plastik | 5 |
| Normales Plastik | 3 |
| Verbundmaterial (schwer recycelbar) | 1 |
| Nicht verfügbar | Dimension wird ausgelassen |

**Herkunft/Transport (10% des E-Scores):**
| Herkunft | Punkte |
|----------|--------|
| Regional (< 100 km) | 10 |
| Deutschlandweit | 8 |
| EU-Nachbarländer | 6 |
| Rest-EU | 5 |
| Europa (nicht EU) | 4 |
| Übersee (Schiff) | 2 |
| Übersee (Flugzeug) | 1 |
| Nicht verfügbar | Dimension wird ausgelassen |

**Bio-Siegel (10% des E-Scores):**
| Siegel | Punkte |
|--------|--------|
| Demeter | 10 |
| Naturland / Bioland | 9 |
| EU-Bio | 7 |
| Kein Bio-Siegel | 3 |
| Nicht verfügbar | 3 (Annahme: kein Siegel) |

### E-Score Berechnung Beispiel
```
Produkt: Bio-Hafermilch aus Deutschland, Tetra Pak

Eco-Score: B → 8 Punkte × 0.40 = 3.20
CO2: 0.9 kg/kg → 10 Punkte × 0.25 = 2.50
Verpackung: Verbundmaterial → 1 Punkt × 0.15 = 0.15
Herkunft: Deutschland → 8 Punkte × 0.10 = 0.80
Bio: EU-Bio → 7 Punkte × 0.10 = 0.70

E-Score = 3.20 + 2.50 + 0.15 + 0.80 + 0.70 = 7.35 → 🟢 Grün
```

---

## 6. Gesamt-Score Beispiel

```
Produkt: Fairtrade Bio-Schokolade aus Ghana

E-Score: 6.8 (Eco-Score C, Bio, aber Übersee-Transport)
S-Score: 7.9 (Fairtrade, aber Risikoland)
G-Score: 5.0 (teilweise transparent)

Gesamt = (6.8 × 0.40) + (7.9 × 0.35) + (5.0 × 0.25)
       = 2.72 + 2.77 + 1.25
       = 6.74 → 🟡 Gelb

Anzeige in der App:
┌──────────────────────────────┐
│  ESG-Score: 6.7 / 10  🟡    │
│                              │
│  🌱 E: 6.8  🟡              │
│  👥 S: 7.9  🟢              │
│  🏛️ G: 5.0  🟡              │
│                              │
│  Quellen: Eco-Score (ADEME), │
│  Fairtrade Int., CSRD-DB     │
└──────────────────────────────┘
```

---

## 7. Datenquellen-Übersicht

| Quelle | Typ | Kosten | Abdeckung |
|--------|-----|--------|-----------|
| Open Food Facts API | Produktdaten, Eco-Score, Labels | Kostenlos | ~600.000 DE-Produkte |
| Agribalyse (ADEME) | CO2-Daten pro Kategorie | Kostenlos | ~2.500 Kategorien |
| BAFA Risikoländerliste | Länder-Risikobewertung Social | Kostenlos | Alle Länder |
| ITUC Global Rights Index | Arbeitnehmerrechte pro Land | Kostenlos | Alle Länder |
| WikiRate | Governance-Daten Unternehmen | Kostenlos | Begrenzt |
| CSRD-Datenbank (EU) | Nachhaltigkeitsberichte | Kostenlos | Wachsend ab 2025 |

---

## 4. S-Score (Social) – Berechnung

### Datenquellen
| Quelle | Was sie liefert | Gewicht im S-Score |
|--------|----------------|-------------------|
| Soziale Siegel (Open Food Facts Labels) | Fairtrade, Rainforest Alliance, UTZ etc. | 50% |
| Herkunftsland-Risiko | Risikobewertung nach BAFA/ILO | 30% |
| Unternehmens-Sozialdaten | LkSG-Compliance, Sozialberichte | 20% |

### Umrechnung in Punkte (0–10)

**Soziale Siegel (50% des S-Scores):**
| Siegel | Punkte |
|--------|--------|
| Fairtrade (Produkt-Siegel) | 10 |
| Fairtrade (Programm-Siegel) | 8 |
| Rainforest Alliance | 7 |
| UTZ (jetzt Teil von Rainforest Alliance) | 7 |
| GEPA fair+ | 9 |
| Kein soziales Siegel vorhanden | 2 |

Mehrere Siegel: höchstes Siegel zählt + 1 Bonuspunkt (max. 10)

**Herkunftsland-Risiko (30% des S-Scores):**

Basierend auf dem Global Rights Index (ITUC) und BAFA-Risikoländerlisten:
| Risikokategorie des Herkunftslandes | Punkte |
|-------------------------------------|--------|
| Niedriges Risiko (z.B. Deutschland, Schweiz, Skandinavien) | 9 |
| Mittleres Risiko (z.B. Türkei, Brasilien, China) | 5 |
| Hohes Risiko (z.B. Elfenbeinküste, Myanmar, Bangladesch) | 2 |
| Nicht verfügbar | Dimension wird ausgelassen |

Hinweis: Die Länder-Risikoeinstufung basiert auf öffentlich zugänglichen Indizes.
Diese Liste muss regelmäßig aktualisiert werden.

**Unternehmens-Sozialdaten (20% des S-Scores):**
| Kriterium | Punkte |
|-----------|--------|
| Unternehmen erfüllt LkSG + veröffentlicht Sozialbericht | 10 |
| Unternehmen erfüllt LkSG | 7 |
| Keine Informationen verfügbar | 3 |

### S-Score Berechnung Beispiel
```
Produkt: Fairtrade-Kaffee aus Kolumbien

Siegel: Fairtrade → 10 Punkte × 0.50 = 5.00
Herkunft: Kolumbien (mittleres Risiko) → 5 Punkte × 0.30 = 1.50
Unternehmen: LkSG erfüllt → 7 Punkte × 0.20 = 1.40

S-Score = 5.00 + 1.50 + 1.40 = 7.90 → 🟢 Grün
```

---

## 5. G-Score (Governance) – Berechnung

### Datenquellen
| Quelle | Was sie liefert | Gewicht im G-Score |
|--------|----------------|-------------------|
| CSRD-Berichterstattung | Hat das Unternehmen einen Nachhaltigkeitsbericht? | 40% |
| Zertifizierungen (B Corp etc.) | Unternehmenszertifizierungen | 35% |
| Transparenz-Index | Offenlegung von Lieferketten, Methodik | 25% |

### Umrechnung in Punkte (0–10)

**CSRD-Berichterstattung (40% des G-Scores):**
| Status | Punkte |
|--------|--------|
| CSRD-Bericht veröffentlicht und geprüft | 10 |
| Freiwilliger Nachhaltigkeitsbericht vorhanden | 7 |
| Nur gesetzliches Minimum | 4 |
| Keine Berichterstattung | 1 |
| Nicht verfügbar | Dimension wird ausgelassen |

**Zertifizierungen (35% des G-Scores):**
| Zertifizierung | Punkte |
|---------------|--------|
| B Corp zertifiziert | 10 |
| ISO 14001 (Umweltmanagement) | 7 |
| Mitglied UN Global Compact | 6 |
| Keine Zertifizierung bekannt | 2 |
| Nicht verfügbar | Dimension wird ausgelassen |

---

## 8. Bekannte Limitationen (v1.0)

- S-Score ist die schwächste Dimension – für viele Produkte fehlen soziale Daten
- G-Score ist auf Unternehmensebene, nicht auf Produktebene – alle Produkte eines Herstellers bekommen den gleichen G-Score
- CO2-Daten sind oft Kategoriedurchschnitte, nicht produktspezifisch
- Herkunftsland-Risiko ist eine Vereinfachung – innerhalb eines Landes gibt es große Unterschiede
- Die Gewichtung (40/35/25) ist eine erste Annahme und sollte durch Nutzerfeedback validiert werden
- Länder-Risikoeinstufungen können sich ändern und müssen regelmäßig aktualisiert werden

---

## 9. Zukünftige Verbesserungen (Phase 2+)

- Nutzer können eigene Gewichtung einstellen (z.B. "mir ist Social wichtiger als Environmental")
- KI-gestützte Datenanreicherung für fehlende Dimensionen
- Direkte Anbindung an EU CSRD-Datenbank wenn verfügbar
- Community-basierte Datenvalidierung (Nutzer melden falsche Daten)
- Detailliertere Länder-Risikobewertungen auf Regionsebene
- Integration weiterer Siegel und Zertifizierungen

---

## 10. Versionierung

| Version | Datum | Änderung |
|---------|-------|----------|
| v1.0 | Februar 2026 | Initiales Scoring-Modell erstellt |

**Transparenz-Index (25% des G-Scores):**
| Transparenz-Level | Punkte |
|-------------------|--------|
| Lieferkette vollständig offengelegt | 10 |
| Lieferkette teilweise offengelegt | 6 |
| Keine Offenlegung | 2 |
| Nicht verfügbar | Dimension wird ausgelassen |

### G-Score Berechnung Beispiel
```
Produkt: Schokolade von Unternehmen X

CSRD: Freiwilliger Bericht → 7 Punkte × 0.40 = 2.80
Zertifizierung: Keine → 2 Punkte × 0.35 = 0.70
Transparenz: Teilweise offengelegt → 6 Punkte × 0.25 = 1.50

G-Score = 2.80 + 0.70 + 1.50 = 5.00 → 🟡 Gelb
```

---

## 6. Gesamt-Score Beispiel

```
Produkt: Fairtrade Bio-Schokolade aus Ghana

E-Score: 6.8 (Eco-Score C, Bio, aber Übersee-Transport)
S-Score: 7.9 (Fairtrade, aber Risikoland)
G-Score: 5.0 (teilweise transparent)

Gesamt = (6.8 × 0.40) + (7.9 × 0.35) + (5.0 × 0.25)
       = 2.72 + 2.77 + 1.25
       = 6.74 → 🟡 Gelb

Anzeige in der App:
┌──────────────────────────────┐
│  ESG-Score: 6.7 / 10  🟡    │
│                              │
│  🌱 E: 6.8  🟡              │
│  👥 S: 7.9  🟢              │
│  🏛️ G: 5.0  🟡              │
│                              │
│  Quellen: Eco-Score (ADEME), │
│  Fairtrade Int., CSRD-DB     │
└──────────────────────────────┘
```

---

## 7. Datenquellen-Übersicht

| Quelle | Typ | Kosten | Abdeckung |
|--------|-----|--------|-----------|
| Open Food Facts API | Produktdaten, Eco-Score, Labels | Kostenlos | ~600.000 DE-Produkte |
| Agribalyse (ADEME) | CO2-Daten pro Kategorie | Kostenlos | ~2.500 Kategorien |
| BAFA Risikoländerliste | Länder-Risikobewertung Social | Kostenlos | Alle Länder |
| ITUC Global Rights Index | Arbeitnehmerrechte pro Land | Kostenlos | Alle Länder |
| WikiRate | Governance-Daten Unternehmen | Kostenlos | Begrenzt |
| CSRD-Datenbank (EU) | Nachhaltigkeitsberichte | Kostenlos | Wachsend ab 2025 |

---

## 8. Bekannte Limitationen (v1.0)

- S-Score ist die schwächste Dimension – für viele Produkte fehlen soziale Daten
- G-Score ist auf Unternehmensebene, nicht auf Produktebene – alle Produkte eines Herstellers bekommen den gleichen G-Score
- CO2-Daten sind oft Kategoriedurchschnitte, nicht produktspezifisch
- Herkunftsland-Risiko ist eine Vereinfachung – innerhalb eines Landes gibt es große Unterschiede
- Die Gewichtung (40/35/25) ist eine erste Annahme und sollte durch Nutzerfeedback validiert werden
- Länder-Risikoeinstufungen können sich ändern und müssen regelmäßig aktualisiert werden

---

## 9. Zukünftige Verbesserungen (Phase 2+)

- Nutzer können eigene Gewichtung einstellen (z.B. "mir ist Social wichtiger als Environmental")
- KI-gestützte Datenanreicherung für fehlende Dimensionen
- Direkte Anbindung an EU CSRD-Datenbank wenn verfügbar
- Community-basierte Datenvalidierung (Nutzer melden falsche Daten)
- Detailliertere Länder-Risikobewertungen auf Regionsebene
- Integration weiterer Siegel und Zertifizierungen

---

## 10. Versionierung

| Version | Datum | Änderung |
|---------|-------|----------|
| v1.0 | Februar 2026 | Initiales Scoring-Modell erstellt |
