# ScanFair · ESG-Score App

> **Scan. Verstehen. Fairer entscheiden.**  
> Eine mobile App für schnelle, transparente Nachhaltigkeitsentscheidungen direkt am Regal.

**ScanFair** ist der Produktname. **ESG-Score App** bleibt der Projekt- und Repository-Name. Das Repo bündelt Produktstrategie, Discovery, Prototypen, Scoring-Methodik und später den Flutter-Code.

---

## 00 · Strategischer Kontext

Nachhaltige Kaufentscheidungen scheitern selten am Willen, sondern an der Situation: wenig Zeit, viele Siegel, uneinheitliche Daten, Greenwashing-Verdacht. ScanFair übersetzt vorhandene Produkt- und ESG-Daten in eine Entscheidungshilfe, die am Point of Sale funktioniert.

| Kernfrage | ScanFair-Antwort |
| --- | --- |
| Was kaufe ich gerade? | Barcode scannen, Produkt erkennen, relevante Daten laden |
| Ist das Produkt nachhaltig? | ESG-Score 0-10 mit Ampel-Logik anzeigen |
| Warum ist der Score so? | E/S/G-Säulen, Quellen und Datenqualität offenlegen |
| Gibt es eine bessere Wahl? | Alternative Produkte und künftige Personalisierung vorbereiten |

**Produktprinzip:** Der Score soll Orientierung geben, aber keine Scheingenauigkeit erzeugen. Fehlende Daten werden sichtbar gemacht.

---

## 01 · Discovery-Fundament

Die aktuelle Discovery verdichtet Personas, Customer Journey, Value Proposition, Feature-Priorisierung, Epics, Roadmap und Risiken.

| Discovery-Signal | Erkenntnis für die App |
| --- | --- |
| Personas | Klaus braucht Einfachheit, Thomas Planbarkeit, Anna schnelle Orientierung trotz Budget- und Zeitdruck |
| Customer Journey | Der wichtigste Moment ist der Einkauf am Regal: Scan → Score → Entscheidung |
| Value Proposition | Transparenz in Sekunden, vertrauenswürdige Quellen, kein unnötiges Tracking |
| Conjoint-Priorisierung | Echtzeit-ESG-Scores, Empfehlungen und Lieferketten-Transparenz sind die stärksten Nutzenversprechen |
| Risiken | Datenqualität, Datenschutz und Greenwashing-Vorwurf müssen im Produkt sichtbar adressiert werden |

→ Discovery Scroll: [docs/00-discovery-scroll.html](docs/00-discovery-scroll.html)  
→ Discovery Canvas (alle Artefakte nebeneinander): [docs/00-discovery.html](docs/00-discovery.html)  
→ Auswertung der Artefakte: [docs/DESIGN-SYNTHESIS.md](docs/DESIGN-SYNTHESIS.md)

---

## 02 · MVP-Scope

Der MVP bleibt bewusst fokussiert: **Lebensmittel zuerst**. Kleidung und Kosmetik sind in den Hi-Fi-Prototypen bereits vorgedacht, sollten aber als Phase-2-Ausbau oder Stretch Goal behandelt werden.

| Im MVP | Später / Ausbau |
| --- | --- |
| iOS-first Flutter App | Android-Version |
| Barcode-Scan für Lebensmittel | Kleidung und Kosmetik als eigene Kategorien |
| Open Food Facts Integration | weitere Produktdatenquellen |
| E-Score vollständig | vollständiger S-Score und G-Score |
| S-Score über Labels/Siegel | CSRD-, Lieferketten- und Unternehmensdaten |
| Score-Ergebnis und Detailansicht | Impact-Tracker, Personalisierung, Community |

**Aktueller Leitsatz für die Umsetzung:** Erst die Kernschleife stabil bauen: `Öffnen → Scannen → Produkt finden → Score verstehen → Details prüfen`.

---

## 03 · Score-Modell

ScanFair aggregiert bestehende, anerkannte Datenquellen. Die App erfindet keine eigenen Nachhaltigkeitsurteile, sondern macht verfügbare Signale verständlich.

| Dimension | Gewicht | MVP-Status | Beispielquellen |
| --- | ---: | --- | --- |
| Environmental | 40% | vollständig geplant | Eco-Score, CO2, Verpackung, Herkunft, Bio-Siegel |
| Social | 35% | vereinfacht | Fairtrade, Rainforest Alliance, soziale Labels |
| Governance | 25% | Platzhalter | CSRD, B Corp, Transparenzdaten |

```text
Gesamt-Score = (E x 0.40) + (S x 0.35) + (G x 0.25)
```

**Ampel-Logik**

| Score | Bedeutung |
| --- | --- |
| 7.0-10.0 | gute bis sehr gute Wahl |
| 4.0-6.9 | mit Bedacht kaufen |
| 0.0-3.9 | kritisch prüfen oder vermeiden |

**Two-Score-Modell aus den Prototypen:** ESG bleibt der Hauptscore. Gesundheit, Material oder Inhaltsstoffe werden als separater Begleithinweis angezeigt und nicht in den ESG-Score eingerechnet.

→ Methodik: [docs/ESG-SCORING-MODELL-v1.md](docs/ESG-SCORING-MODELL-v1.md)

---

## 04 · Design-System & Prototypen

Die Designsprache folgt ScanFair: warm, vertrauenswürdig, reduziert, entscheidungsnah. Forest Green ist die Primärfarbe, warme Neutrals bilden den Hintergrund, E/S/G bekommen eigene Akzentfarben.

| Phase | Design-Artefakt | Zweck |
| --- | --- | --- |
| 0 | [Discovery Scroll](docs/00-discovery-scroll.html) · [Discovery Canvas](docs/00-discovery.html) | Strategischer Kontext und Research-Synthese |
| 1 | [Wireframes](docs/01-wireframes.html) | Frühe Screen-Strukturen |
| 2.1 | [Brand Identity](docs/02-brand-identity.html) | Farben, Typografie, Score-System, UI-Komponenten |
| 2.2 | [Score-Varianten](docs/02-score-variants.html) | Ampel-Karte, Radial-Donut, Editorial-Score im Vergleich |
| 2.3 | [Hi-Fi Hauptscreens](docs/02-screens.html) | S1 Home · S2 Scanner · S3 Result · S4 Detail · S5 Alternativen |
| 2.4 | [Multi-Kategorie + Onboarding + Edge-States](docs/04-screens.html) | Multi-Kategorie-Screens, Onboarding O1–O3, Edge-States E0–E3 |
| 3 | [Klickbarer Prototyp](docs/05-prototype.html) | Vollständiger Flow mit Hotspots, Scan-Animation, Tweaks-Panel |
| 4 | [Developer-Handoff](design_handoff_scanfair/README.md) | Tokens, Daten-Schema, Komponenten, Screens für Claude Code |

**Design-Entscheidung für den MVP:** Ampel-Karte als schnelle Standardansicht, Editorial-/Detail-Elemente für Nutzer, die tiefer verstehen wollen.

---

## 05 · Architektur

| Komponente | Technologie | Rolle |
| --- | --- | --- |
| Mobile App | Flutter / Dart | iOS-first App, später cross-platform |
| State Management | Riverpod | klarer Datenfluss zwischen Scan, Produkt und Score |
| Barcode Scanner | mobile_scanner | Kamera-Scan für EAN-Barcodes |
| Produktdaten | Open Food Facts API | Produkt-, Label-, Eco-Score- und Verpackungsdaten |
| Backend / Cache | Supabase EU | Auth, Cache, optionale Datenpersistenz |
| Lokaler Cache | Hive | Offline-Grundmodus und letzte Scans |

```text
iPhone Kamera
  -> Flutter App
  -> Barcode Scan
  -> Open Food Facts API
  -> regelbasierte ESG-Scoring Engine
  -> Score-Ergebnis + Details + Quellen
  -> optionaler Supabase/Hive Cache
```

---

## 06 · Repository-Struktur

```text
ESG-Score-App/
├── README.md
├── CLAUDE.md
├── docs/
│   ├── 00-discovery-scroll.html        # Research-Scroll
│   ├── 00-discovery.html               # Discovery-Canvas (NEU)
│   ├── 01-wireframes.html
│   ├── 02-brand-identity.html
│   ├── 02-score-variants.html
│   ├── 02-screens.html                 # Hi-Fi S1–S5 (NEU)
│   ├── 04-screens.html                 # Multi-Kategorie + Onboarding + Edge-States
│   ├── 05-prototype.html               # Klickbarer Prototyp (NEU)
│   ├── DESIGN-SYNTHESIS.md
│   ├── ESG-SCORING-MODELL-v1.md
│   ├── MVP-REQUIREMENTS.md
│   ├── PITCH.md
│   ├── PROJEKTTAGEBUCH.md
│   └── Design/prototypes/
│       ├── tokens.css
│       ├── products.js
│       ├── design-canvas.jsx
│       ├── ios-frame.jsx
│       ├── tweaks-panel.jsx
│       ├── 02-screens-components.jsx   # NEU
│       ├── 02-screens-app.jsx          # NEU
│       ├── 04-screens-shell.jsx
│       ├── 04-screens-results.jsx
│       ├── 04-screens-onboarding.jsx   # NEU
│       ├── 04-screens-app.jsx
│       └── 05-prototype-app.jsx        # NEU
├── design_handoff_scanfair/            # Developer-Handoff (NEU)
│   ├── README.md
│   ├── tokens.css
│   ├── products.js, brand/, data/
│   └── screens, prototype, components, ios-frame…
├── lib/                                # Flutter-App-Code, sobald die Umsetzung startet
├── test/                               # Tests
└── pubspec.yaml                        # Flutter Dependencies
```

---

## 07 · GitHub-Arbeitsweise

GitHub soll nicht nur Ablage sein, sondern unser Steuerungsinstrument für Produkt, Code und Entscheidungen.

| Bereich | Best Practice für dieses Projekt |
| --- | --- |
| Branches | `main` bleibt stabil; Arbeit passiert auf Feature-Branches wie `codex/integrate-design-artifacts` |
| Pull Requests | Jeder größere Schritt bekommt einen PR mit Ziel, Änderungen, offenen Entscheidungen und Screenshots/Links |
| Issues | Anforderungen, Bugs, Design-Entscheidungen und Forschungsfragen als Issues erfassen |
| Labels | `type:feature`, `type:bug`, `type:docs`, `type:design`, `area:scoring`, `area:flutter`, `area:research` |
| Milestones | `MVP Foundation`, `Scanner Flow`, `Scoring Engine`, `Result Screens`, `Testing & Polish` |
| Decisions | Wichtige Produktentscheidungen im PR oder als kurze Decision Note in `docs/` dokumentieren |
| README | Einstiegspunkt für den aktuellen Projektstand, nicht Ablage für jedes Detail |

Dieses Repo enthält dafür Vorlagen:

- [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md)
- [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)
- [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md)
- [Design Decision Template](.github/ISSUE_TEMPLATE/design_decision.md)

**Empfohlener Workflow**

1. Issue anlegen: Was soll gebaut oder entschieden werden?
2. Branch erstellen: `codex/<kurzer-zweck>` oder `feature/<kurzer-zweck>`.
3. Änderung klein halten: ein Thema pro Branch.
4. PR öffnen: Kontext, Screenshots/Links, Testhinweise, offene Fragen.
5. Review nutzen: fachlich, technisch und UX-seitig prüfen.
6. Nach Merge: Projekttagebuch oder relevante Docs aktualisieren.

**Definition of Ready für App-Features**

- Nutzerproblem ist klar.
- Screen oder Flow ist im Prototyp verlinkt.
- Datenquelle und Fallback sind beschrieben.
- Akzeptanzkriterien sind testbar.

**Definition of Done für App-Features**

- Flutter-Code ist implementiert.
- Score-/Datenlogik ist getestet.
- Fehlende Daten werden transparent angezeigt.
- UI entspricht ScanFair-Designprinzipien.
- README oder relevante Docs sind nachgezogen, wenn sich Produktverhalten geändert hat.

---

## 08 · Roadmap

| Phase | Fokus | Status |
| --- | --- | --- |
| Phase 0 | Discovery, Research, Design-System, Prototypen | abgeschlossen |
| Phase 1 | Hi-Fi-Designs, klickbarer Prototyp, Developer-Handoff | abgeschlossen |
| Phase 2 | Lebensmittel-MVP mit Scanner, Score und Details (Flutter) | nächster Umsetzungsschritt |
| Phase 3 | vollständiger S-/G-Score, Impact, Personalisierung | geplant |
| Phase 4 | Supermarkt-Integration, Payment, AR, Skalierung | Vision |

---

## 09 · Wissenschaftlicher Rahmen

Das Projekt verbindet Management- und Produktmethoden mit einem umsetzbaren App-MVP:

- Design Thinking für Problemverständnis und Lösungsideen
- Customer Journey Mapping für Pain Points im Einkaufsprozess
- Value Proposition Canvas für Product-Market-Fit
- Requirements Engineering für Anforderungen und User Stories
- Lean Startup für MVP, Validierung und Iteration
- ESG-Frameworks für nachvollziehbare Bewertungslogik
- DSGVO und CSRD als Rahmenbedingungen für Daten und Transparenz

---

## 10 · Wichtige Dokumente

| Dokument | Beschreibung |
| --- | --- |
| [MVP Requirements](docs/MVP-REQUIREMENTS.md) | technischer Bauplan für den ersten App-MVP |
| [ESG-Scoring-Modell v1.0](docs/ESG-SCORING-MODELL-v1.md) | Gewichtungen, Formeln, Datenquellen und Beispiele |
| [Design-Synthese](docs/DESIGN-SYNTHESIS.md) | Unterschiede zwischen altem Konzeptstand und neuen ScanFair-Prototypen |
| [Developer-Handoff](design_handoff_scanfair/README.md) | Vollständiges Paket für Claude Code: Tokens, Daten, Komponenten, Screens |
| [Pitch](docs/PITCH.md) | Projektargumentation und fachlicher Kontext |
| [Projekttagebuch](docs/PROJEKTTAGEBUCH.md) | Fortschritte, Entscheidungen und Learnings |

---

## 11 · Lokale Entwicklung & Quality Gates

Der aktuelle Entwicklungsstand bleibt lokal: kein iOS-Deployment, kein Hosting,
kein Online-Release. Die App startet als Flutter-MVP mit lokal simuliertem
Barcode-Flow, Demo-/OFF-aehnlichen Produktdaten, ESG-Score-Logik,
Result-/Detail-Screens sowie Low-Data- und Not-Found-Zustaenden.

**App lokal starten**

```bash
cd /Users/mustafademir/ESG-Score-App/esg_app
flutter pub get
flutter run
```

**Quality Gates lokal ausfuehren**

```bash
cd /Users/mustafademir/ESG-Score-App
bash scripts/quality/run_quality_gates.sh
```

Das Script erzeugt `.quality/quality-gate-report.md` und fuehrt diese Gates aus:

| Gate | Zweck |
| --- | --- |
| `G-FLT-DEPS` | Flutter Dependencies reproduzierbar aufloesen |
| `G-FLT-FORMAT` | Format-Drift blocken |
| `G-FLT-ANALYZE` | Statische Analyse mit `--fatal-infos` |
| `G-FLT-TEST` | Unit- und Widget-Tests mit Coverage |
| `G-REG-UNIT` | Rego-Policy-Tests fuer Compliance-Regeln |
| `G-CMP-APPLE` | Conftest Apple-Compliance-Gates plus Evidence-Log |
| `G-DOC-TRACE` | README/Workflow-Dokumentation gegen Drift pruefen |

**GitHub Actions**

Die neue Action [Quality Gates](.github/workflows/quality-gates.yml) laeuft auf
`main`, `dev`, `codex/**`, Pull Requests und manuell via `workflow_dispatch`.
Sie veroeffentlicht ein Summary und das Artefakt
`scanfair-quality-gate-results` mit `.quality/**` sowie generierten
Evidence-Dateien.

Explizit ausgeschlossen: iOS-Deployment, Online-Release, Hosting-Provider,
Kubernetes und OPA Gatekeeper. Die App uebernimmt aus
`genaiops-compliance-gates` nur die relevanten Muster: Gate-Definitionen,
Policy-as-Code, Evidence-Log und sichtbare CI/CD-Entscheidung.

---

## Autor

**Mustafa Demir**  
Digitale Transformation Consulting AI & Cloud Solution Architecture

Dieses Projekt dokumentiert den Weg vom Konzept zur App: methodisch, transparent und mit dem Ziel, nachhaltige Kaufentscheidungen verständlicher zu machen.
