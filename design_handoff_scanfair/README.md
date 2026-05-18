# Handoff: ScanFair — ESG-Score-Scanner für bewussten Konsum

## Overview

**ScanFair** ist eine mobile App (Konzept) zum Scannen von Konsumprodukten mit anschließender ESG-Bewertung (Environment / Social / Governance). Drei Produktkategorien werden unterstützt: **Lebensmittel**, **Kleidung**, **Kosmetik**. Die App liefert pro Produkt einen Gesamtscore (0–10), drei Säulenscores, ein verbal "Empfehlung / Mit Bedacht / Vermeiden"-Verdikt sowie kategoriespezifische Zusatzinfos (Gesundheit / Material & Pflege / Inhaltsstoffe).

Kernhaltung: **kein Greenwashing, keine 5-Sterne-Wohlfühl-Optik**. Wir zeigen Datengrundlage, Quellenlage und sagen explizit, wenn wir zu wenig wissen.

## About the Design Files

Die Dateien in diesem Bundle sind **Design-Referenzen** — interaktive HTML/React-Prototypen, die das beabsichtigte Aussehen und Verhalten zeigen. Sie sind **kein Production-Code zum Direktkopieren**.

Aufgabe: **Diese HTML-Designs in der Ziel-Codebase mit deren etablierten Pattern und Bibliotheken nachbauen.** Falls noch keine Codebase existiert, wähle das passendste Framework für mobile Native-Feeling (React Native + Expo, SwiftUI für reines iOS, Flutter) und implementiere dort.

Die HTML-Mocks sind in **React 18 + Babel-Standalone** geschrieben mit Inline-Styles — das ist nur fürs Prototyping; auf keinen Fall 1:1 in Production übernehmen.

## Fidelity

**High-fidelity (hifi).** Pixel-genaue Mockups mit finalen Farben, Typografie, Spacing, Kopie und Interaktionen. Recreate pixel-perfect mit den Bibliotheken der Zielcodebase.

## Screens / Views

Alle Screens sind für **iPhone 390pt × 844pt** (visible content area: 400×790 in den Mocks, einschließlich 50px Status Bar) ausgelegt. Eine Tablet-Variante existiert für E3.

### Onboarding

#### O1 — Welcome
- **Purpose:** Erstkontakt + Wertversprechen "Bewusster einkaufen, ohne Greenwashing".
- **Layout:** Vertikal zentriert. Top: Logo "ScanFair" + 3-Punkt-Stepper (linker aktiver Indicator extra-breit). Center: 96×96px grünes Glyph-Tile (Scan-Icon mit Leaf-Badge), Eyebrow "Willkommen bei ScanFair", Display-Heading 40px Instrument Serif zweizeilig, Subline 14.5px Inter. Bottom: Primary-CTA "Loslegen" full-width + Skip-Link.
- **Halo:** Radial-Gradient `radial-gradient(circle, #E8F2EE 0%, transparent 60%)`, 520×520, oben zentriert clipped.
- **CTA shadow:** `0 8px 22px rgba(15,123,92,0.22)`.

#### O2 — Wie es funktioniert
- **Purpose:** Drei Schritte: Scannen / Score lesen / Bewusst entscheiden.
- **Layout:** Header (Logo + Stepper Step 2). Display-Heading 32px "Drei Schritte — weniger als 5 Sekunden". Drei Karten gestapelt (gap 10px), je: Icon-Tile 40×40 (`#E8F2EE` bg, `#0A6248` icon) + Step-Nr "01"/"02"/"03" + Titel + Description.

#### O3 — Datenquellen & Vertrauen
- **Purpose:** Vertrauen aufbauen vor erstem Scan; transparenz-narrativ.
- **Layout:** Display "Offene Daten, nachvollziehbar". 4 Quellen-Karten (OFF / OBF / GS1 / NGO), je mit farbigem Tag-Tile, Titel, Beschreibung. Grünes Promise-Banner: "Kein Score ohne Quelle." Primary-CTA "Ersten Scan starten" (kein Skip).

### Hauptflow

#### S1 — Home (Light)
- **Purpose:** Einstieg + Recent Scans.
- **Layout (top→bottom):**
  1. Top bar: Logo links, 36×36 User-Bubble rechts.
  2. Greeting: Eyebrow "Donnerstag, 21. Mai" → Display "Was gibt's heute im Wagen?" (38px serif, 2 Zeilen, "im Wagen" italic green).
  3. **Primary CTA "Barcode scannen"** — full-width grüner Button (radius 20, shadow `0 12px 28px rgba(15,123,92,0.25)`), eyebrow "Hauptaktion" + Label + 48×48 Icon-Tile rechts.
  4. Sekundär: 2 Buttons "Suchen" / "Manuell eingeben" (cream cards).
  5. "Was du scannen kannst": 3 Tiles (Lebensmittel / Kleidung / Kosmetik).
  6. "Zuletzt gescannt" — Liste von 3 Items, je mit Emoji-Tile, Name, Zeit, Score-Pill (farbig nach Verdict).
  7. Bottom Tabs: Scannen (active) · Verlauf · Impact · Profil.

#### S2 — Camera Scanner
- **Purpose:** Kamera-Scan-View.
- **Layout:** Dunkler Hintergrund `#1a1814` mit subtilem Gradient. Top-Chrome: cream-tinted Glass-Pills (X-Close, "SCANNER"-Label, Flash). Mitte: 260×180 Scanframe mit grünen Eckwinkeln (`#C5DFD3`, 3px), animierte Scanline horizontal mittig (linear-gradient + glow). Hint "Barcode in den Rahmen halten" 18px unter Frame.
- **Footer:** cream Card "Barcode manuell eingeben" + chevron.

#### S2.5 — Detection / Routing
- **Purpose:** Übergang nach erkanntem Produkt; routet zur passenden Result-View.
- **Layout:** ScreenNav (Back · "Erkennung"). Center: 110×110 Pulse-Circle mit Kategorie-Emoji + dünnem grünen Ring (-8px inset, opacity 0.25). Eyebrow "Erkannt" → Display 36px Serif Kategorie-Name → Beschreibung. Loading-Dots ("Lade kategorie-spezifische Bewertung..."). Korrektur-Card mit 2 Pill-Buttons für andere Kategorien.

#### S3 — Result
- **Purpose:** Hauptergebnis. Hero-Score + Drei-Säulen + Secondary-Bar + CTAs.
- **Components (top→bottom):** ScreenNav · ProductCard · **ScoreHero** (color band oben (Verdict-Farbe), riesige Zahl 60px serif, "/10", Verdict-Pill, Tagline) · **ScoreBars** (3 Pillar-Rows mit Mini-Progress-Bars, je Eyebrow + Hint) · **SecondaryBar** (variant linear|discrete|minimal — Begleitbalken, NICHT Teil des Scores, mit Disclaimer "kein Score · zur Information") · MethodFootnote · ScoreCTAs (Merken/Alternativen/Erneut).

#### S4 — Details
- **Purpose:** Tiefe — pro Säule expandable Liste der Faktoren + Checkliste.
- Wie S3, aber:
  - ScoreBars **expandable** (Pfeil-Button, expandiertes Panel mit Faktor-Liste je Säule).
  - **SecondaryChecklist** statt SecondaryBar — Liste von ✓/✗-Items mit Note + Quelle.

#### S5 — Not Found
- **Purpose:** Produkt nicht in DB. Crowdsourcing-Aufruf.
- **Layout:** Icon-Bubble 88×88 (cream) → Display "Dieses Produkt kennen wir noch nicht.". 3 Optionen-Liste (Foto machen [primary green tile] · Manuell hinzufügen · Hersteller anfragen). Footer-Hinweis: "ScanFair lebt von Crowdsourcing."

### Edge-States

#### E1 — Offline
- Yellow Status-Banner oben (`#FEF3C7`/`#FCD34D`, "Keine Verbindung"). Cache-Hinweis "12 Produkte weiterhin abrufbar". Liste gecachter Scans (ähnlich Recent-Scans). Retry-Button.

#### E2 — Low Data
- Statt ScoreHero: gestreiftes Warn-Banner (`repeating-linear-gradient(90deg, #D9A35A 12px, #B8853F 12px 24px)`), Eyebrow "Datengrundlage zu dünn", Display "Wir geben hier keinen Score." Sektion "Datenqualität" mit Mini-Progress 38% + Liste von Indikatoren (✓ vs `?`). CTA "Hersteller anfragen".

#### E3 — Tablet (Result, 2-Spalten)
- 1024×720 Frame. Top-Bar: Logo + Breadcrumb + Share/Merken-Buttons. Grid 2-spaltig (1.05fr / 1fr): Links ProductCard XL + Hero-Score (Zahl 96px, Pillars als 3 Mini-Cards inline). Rechts SecondaryBar + Checklist + Method-Footnote.

## Interactions & Behavior

### Flow
```
O1 → O2 → O3 → S1 (Home)
S1 [Scan-CTA] → S2 (Scanner)
S2 [auto 1.6s] → S2.5 (Detection)
S2.5 [auto 1.4s] → S3 (Result)
S3 [Tap "Details & Quellen"] → S4 (Details)
S4 [Back] → S3
Edge-Pfade: → S5 NotFound · → E1 Offline · → E2 LowData
```

### Auto-Transitions
- S2 → S2.5: 1.6s timeout (mockt Barcode-Erkennung)
- S2.5 → S3: 1.4s timeout (mockt Module-Loading)

### Hotspots (im Prototyp `05-prototype.html`)
Tappable Regionen pro Screen — detaillierte Koordinaten siehe `05-prototype-app.jsx` (Funktion `HotspotsFor`).

### Animationen
- ScoreBar-Fill: `width 0.6s cubic-bezier(0.4,0,0.2,1)` von 0 nach Score-Prozent.
- Onboarding-Stepper aktiver Indicator: `width 0.3s` (10→22px).
- Scanline (S2): kann als `@keyframes` Sweep top-to-bottom animiert werden (im Mock statisch).
- Pillar-Expand (S4): rotate-180 Pfeil + slide-down Panel.
- Keyboard-Shortcut (nur im Prototyp): `Escape`/`←` triggert Back-Navigation.

### Loading / Empty States
- S2.5 ist effektiv ein dedizierter Loading-Screen.
- E1 / E2 für No-Connection / No-Data.
- S5 für No-Match.

### Responsive
- iPhone-Layout primär.
- Tablet (E3) demonstriert das 2-Spalten-Grid für Web/iPad.

## State Management

### Globaler App-State (mind. nötig)
- `currentScreen: ScreenId` — Stack-basiertes Routing.
- `history: ScreenId[]` — für Back-Navigation.
- `lastScannedProduct: Product | null`.
- `cache: Product[]` — gecachte Scans für Offline-Modus.
- `connectivity: 'online' | 'offline'`.

### Per-Screen-State
- **S3/S4 ScoreBars expandable:** `openPillar: 'e'|'s'|'g'|null`.
- **S2 Scanner:** Camera-stream, BarcodeDetectorAPI / ML-Kit / Vision.

### Data Layer
- API-Endpoint `GET /products/:barcode` → liefert `Product`-Objekt (siehe `data/products.js` für Schema).
- `Product`-Schema:
  ```ts
  type Verdict = 'green' | 'yellow' | 'red';
  type ProductType = 'food' | 'clothing' | 'cosmetics';

  interface Product {
    barcode: string;
    brand: string;
    product_name: string;
    category: string;
    origin: string;
    image_emoji: string;            // Placeholder bis echte Images
    productType: ProductType;
    esg: {
      e: number; s: number; g: number;   // 0–10
      total: number;                      // 0–10
      verdict: Verdict;
      verdict_label: string;              // "Empfehlung" / "Mit Bedacht" / "Vermeiden"
      tagline: string;                    // 1 Satz
    };
    secondaryInfo: {
      title: string;            // "Gesundheit" / "Material & Pflege" / "Inhaltsstoffe"
      position: number;          // 0–10 für Bar-Marker
      label: string;             // z.B. "Ausgewogen"
      barLeft: string;           // z.B. "ungünstig"
      barRight: string;          // z.B. "nährstoffreich"
      facts: string;             // Erklärung 1–2 Sätze
    };
    checklist?: Array<{ ok: boolean; label: string; note?: string }>;
    data_completeness: number;   // 0–1
  }
  ```

## Design Tokens

Vollständige Definitionen in `tokens.css` (im Bundle).

### Colors
- **Backgrounds:** `--sf-bg #FBFAF6` (warm off-white) · `--sf-bg-alt #F4F2EB` (sand) · `--sf-bg-card #FFFFFF` · `--sf-bg-deep #0E1B17` (forest-tinted slate).
- **Ink:** `#1A2622` / `#4A5650` / `#7A857F`.
- **Borders:** `#E5E2D8` · `#EFEDE5` (soft) · `#C7C3B6` (strong).
- **Brand Forest Green:** 50 `#E8F2EE` · 100 `#C5DFD3` · 200 `#8FC2A8` · 400 `#3D9B76` · **500 `#0F7B5C` ⭐ Primary** · 600 `#0A6248` · 700 `#074A36` · 900 `#042A1E`.
- **Pillar-Farben:** E `#0F7B5C` · S `#C97B5C` (Clay) · G `#4F46E5` (Indigo).
- **Ampel:** Green `#0F7B5C` (≥7.0) · Yellow `#D97706` (4.0–6.9) · Red `#C2410C` (<4.0).
- **Status:** Success `#DCFCE7`/`#15803D` · Warning `#FEF3C7`/`#B45309` · Danger `#FEE2E2`/`#991B1B`.

### Typography
- **Display:** Instrument Serif — Hero, Display-Headings, Score-Numbers (italic für betonte Wörter).
- **UI:** Inter — alles andere; Weights 400/500/600/700.
- **Mono:** ui-monospace fallback chain.
- **Scale (iPhone 390pt):** xs 11 · sm 13 · base 15 · md 17 · lg 20 · xl 24 · 2xl 28 · 3xl 34 · display 48 · score 72.
- **Eyebrow:** 11px, weight 700, letter-spacing 0.08em, uppercase, color brand-green.
- **Display-Tracking:** -0.02em.

### Spacing
1=4 · 2=8 · 3=12 · 4=16 · 5=24 · 6=32 · 7=40 · 8=64.

### Radii
xs 4 · sm 8 · md 12 · lg 16 · xl 20 · 2xl 28 · pill 999.

### Shadows
- xs `0 1px 2px rgba(26,38,34,0.04)`
- sm `0 2px 8px rgba(26,38,34,0.06)`
- md `0 4px 16px rgba(26,38,34,0.08)`
- lg `0 12px 32px rgba(26,38,34,0.10)`
- xl `0 24px 48px rgba(26,38,34,0.14)`
- glow `0 8px 24px rgba(15,123,92,0.20)` (für Primary-CTA)

### Motion
- `--sf-ease cubic-bezier(0.4, 0, 0.2, 1)` (default)
- `--sf-ease-bounce cubic-bezier(0.175, 0.885, 0.32, 1.275)`
- Durations: fast 0.20s · base 0.30s · slow 0.45s.

## Voice & Tone

- **Deutsch, Du-Form**, ruhig, sachlich, leicht warmherzig.
- **Keine Aufrufzeichen**, keine Marketing-Floskeln.
- **"Wir geben hier keinen Score."** — App ist ehrlich über Wissensgrenzen.
- Display-Headlines oft 2-zeilig, das emotional gefärbte Wort kursiv (Instrument Serif italic) in Brand-Green: z.B. "Bewusster einkaufen, *ohne Greenwashing.*"
- Eyebrows kurz und nicht-werblich: "Erkannt" / "Datengrundlage zu dünn" / "Aus dem Cache".

## Assets

- **Keine custom Bilder/Icons** verwendet — alle Icons sind Inline-SVGs (lucide-style strokes 2px) oder Unicode-Glyphen (▾ ↗ × ‹ etc.). Produktbilder sind Emoji-Placeholder.
- **Bei Production:** Lucide-React (oder Heroicons) als Icon-Lib. Echte Produktbilder über Open Food Facts / Open Beauty Facts API.
- **Fonts:** Google Fonts — Inter (300/400/500/600/700) + Instrument Serif (regular + italic).

## Files in Bundle

- `README.md` — dieses Dokument.
- `tokens.css` — Design-Token (CSS-Variablen + utility classes).
- `data/products.js` — Demo-Daten für 3 Kategorien (Schema-Referenz).

### HTML-Prototypen (Design-Referenzen)
- `00-discovery.html` — Discovery-Doc: Personas, Customer Journey Map, Value Proposition Canvas, Scenarios, Epics.
- `02-brand-identity.html` — Brand-Identity-Sheet (Colors, Typo, Tonalität).
- `02-screens.html` — frühere Hi-Fi-Hauptscreens (V1+V3-Hybrid mit Health-Bar-Varianten).
- `04-screens.html` — **Multi-Kategorie-Architektur (3 Result-Screens) + Onboarding + Edge-States** — Hauptreferenz für Designer.
- `05-prototype.html` — **Klickbarer Prototyp mit Hotspots + Tweaks** — Hauptreferenz für Flow & Interaktion.

### React-Komponenten (in den HTMLs eingebunden)
- `02-screens-components.jsx` — `ProductCard`, `ScoreHero`, `ScoreBars`, `PillarRow`, `SecondaryBar`, `SecondaryChecklist`, `HealthBar`, `MethodFootnote`, `ScoreCTAs`, `ScreenNav`.
- `04-screens-shell.jsx` — `S1_HomeLight`, `S2_ScannerLight`, `S25_Detection`, `S5_NotFound`.
- `04-screens-results.jsx` — `S3_Result`, `S4_Details` + `PROD_DETAILS_BY_TYPE` (Säulen-Faktoren).
- `04-screens-onboarding.jsx` — `O1_Welcome`, `O2_How`, `O3_Trust`, `E1_Offline`, `E2_LowData`, `E3_TabletResult`.
- `05-prototype-app.jsx` — Screen-Router, Hotspots, Flow-Sidebar, Tweaks-Panel.
- `ios-frame.jsx` — iOS-Device-Frame + Statusbar (nur fürs Mockup-Display).

## Implementation Notes

- **Inline-Styles im Mock sind nicht idiomatisch** für Production. Übersetze in:
  - **Tailwind:** Mappe Tokens nach `tailwind.config.js` (`extend.colors.sf-green` etc.). Spacings & Radii über Custom-Theme.
  - **CSS-Modules / Styled Components:** Halte Token-Layer (CSS-Vars) und nutze sie in Komponenten.
  - **React Native:** StyleSheet-Approach, Tokens als JS-Konstanten exportieren.
- **Score-Berechnung** ist kein Frontend-Concern — kommt aus dem Backend (Methodik v1.0). Frontend rendert nur.
- **Accessibility:**
  - Verdict darf NICHT nur durch Farbe transportiert werden — immer Label + Pill.
  - Score-Pills haben Mindest-Kontrast (getestet: ≥4.5:1 für Text).
  - Hit-Targets ≥44pt — siehe Bottom-Tabs, CTAs, Pillar-Expand-Buttons.
- **i18n:** Aktuell DE-only. Strings extrahieren in eine i18n-Lib (i18next o.ä.) — alle UI-Strings im Mock sind kandidat für Extraktion.
- **Datenbasis:**
  - Open Food Facts API (Lebensmittel) — public, CC-BY-SA.
  - Open Beauty Facts API (Kosmetik) — public.
  - Kleidung: aktuell keine offene API — Crowdsourcing + manuelle Kuration vorgesehen.

## Quick Start für den Implementierer

1. `tokens.css` als Style-Quelle ins Projekt bringen (oder in das jeweilige Theme-System mappen).
2. `data/products.js` als Schema-Referenz für API-Contract verwenden.
3. Mit **S3 (Result)** anfangen — das ist der Kern-Screen. Die ScoreHero/ScoreBars/SecondaryBar-Komponenten sind die wiederverwendbaren Atome.
4. Dann S1 (Home), S2 (Scanner mit BarcodeDetector / Vision), S2.5 (Detection-Loader), S4 (Details).
5. Onboarding zuletzt — wird nur einmal gezeigt (LocalStorage-Flag).
6. Edge-States parallel zu jeweiligen Pfaden.
7. Klickbarer Prototyp `05-prototype.html` ist die "lebende Spezifikation" für den End-to-End-Flow.
