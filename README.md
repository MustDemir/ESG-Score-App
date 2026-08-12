# ScanFair · ESG-Score App

> **Scan. Verstehen. Fairer entscheiden.**  
> Eine mobile App für schnelle, transparente Nachhaltigkeitsentscheidungen direkt am Regal.

**ScanFair** ist der Produktname. **ESG-Score App** bleibt der Projekt- und Repository-Name. Das Repo bündelt Produktstrategie, Discovery, Prototypen, Scoring-Methodik und den lokal validierten Flutter-MVP.

**Arbeitsrolle:** AI-gestütztes, compliance-orientiertes Product Engineering
mit Technical Product Ownership, DevSecOps und Data Governance.

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
| Open Food Facts Integration mit Evidenz-Provenienz | weitere Produktdatenquellen |
| E-Score vollständig | vollständiger S-Score und G-Score |
| S-Score über Labels/Siegel | CSRD-, Lieferketten- und Unternehmensdaten |
| Score-Ergebnis und Detailansicht | Impact-Tracker, Personalisierung, Community |

**Aktueller Leitsatz für die Umsetzung:** Erst die Kernschleife stabil bauen: `Öffnen → Scannen → Produkt finden → Score verstehen → Details prüfen`.

---

## 03 · Score-Modell

ScanFair aggregiert externe Daten und berechnet daraus nach der versionierten
ScanFair-Methodik einen Orientierungsscore. Dieser ist keine Zertifizierung:
Quellwerte, ScanFair-Regeln, Datenluecken und methodische Grenzen bleiben
sichtbar.

| Dimension | Gewicht | MVP-Status | Beispielquellen |
| --- | ---: | --- | --- |
| Environmental | 50% | implementiert | Environmental-/Eco-Score, CO2, Verpackung, Herkunft |
| Social | 30% | heuristischer MVP | Fairtrade, Bio, Rainforest Alliance, Herkunftssignale |
| Governance | 20% | heuristischer MVP | Datenvollstaendigkeit und Produkttransparenz |

```text
Gesamt-Score = Summe(verfuegbare Saeule x Gewicht) / Summe(verfuegbare Gewichte)
Voraussetzung: Environmental-Evidenz ist vorhanden.
```

Social und Governance bleiben bei fehlender Environmental-Evidenz separat
sichtbar. Fehlende Saeulen werden nicht geschaetzt, nicht als Null behandelt
und nicht durch andere Saeulen ersetzt. Diese Precedence ist in
[ADR 0027](docs/project/decisions/0027-environmental-score-precedence.yaml)
verbindlich festgelegt.

**Ampel-Logik**

| Score | Bedeutung |
| --- | --- |
| 7.0-10.0 | ueberwiegend positive MVP-Signale |
| 4.0-6.9 | gemischte MVP-Signale |
| 0.0-3.9 | ueberwiegend kritische MVP-Signale |

**Two-Score-Modell aus den Prototypen:** ESG bleibt der Hauptscore. Gesundheit, Material oder Inhaltsstoffe werden als separater Begleithinweis angezeigt und nicht in den ESG-Score eingerechnet.

→ Verbindliche Formel: [ADR 0011](docs/project/decisions/0011-esg-score-formel.yaml)

→ Daten- und Evidenzarchitektur: [docs/project/data/data-architecture.md](docs/project/data/data-architecture.md)

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
| State Management | Flutter-native + Constructor Injection | lokaler MVP-State ohne zusaetzliche Laufzeitabhaengigkeit |
| Barcode Scanner | mobile_scanner | Kamera-Scan für EAN-Barcodes |
| Produktdaten | Open Food Facts API v3 | Produktdaten plus feldgenaue Evidenz-Provenienz |
| Umwelt-LCA | AGRIBALYSE 3.2 | offizieller Kategorieproxy mit DQR; aktuell via OFF transportiert |
| Traceability | evidenzbasierte Entity-/Relationship-Schicht | GTIN, Rohstoff, Herkunft, Marke und spaeter Rechtstraeger getrennt aufloesen |
| Backend / Cache | Supabase/PostgreSQL | lokales RLS-Schema vorbereitet, Remote noch nicht verbunden |
| Lokaler Cache | geplant | Offline-Grundmodus und letzte Scans |

```text
iPhone Kamera
  -> Flutter App
  -> Barcode Scan
  -> Open Food Facts API
  -> AGRIBALYSE-Kategorieevidenz mit Retrieval-Channel
  -> normalisierte ESGEvidence
  -> explizite Produkt-/Rohstoff-/Herkunfts-/Unternehmensbeziehungen
  -> regelbasierte ESG-Scoring Engine
  -> Score-Ergebnis + Details + Quellen
  -> spaeter optionaler Supabase-Cache
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
├── esg_app/                            # Flutter-App, iOS-Projekt und Tests
├── supabase/                           # Lokales Schema, Migrationen und pgTAP
├── scripts/                            # Quality- und Compliance-Runner
└── evidence-store/                     # Lokale, hashverkettete Gate-Evidenz
```

---

## 07 · GitHub-Arbeitsweise

GitHub soll nicht nur Ablage sein, sondern unser Steuerungsinstrument für Produkt, Code und Entscheidungen.

| Bereich | Best Practice für dieses Projekt |
| --- | --- |
| Branches | `main` bleibt stabil; Arbeit passiert auf kurzlebigen Branches wie `feature/integrate-design-artifacts` |
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
2. Branch erstellen: `feature/<kurzer-zweck>`.
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
| Phase 2 | Lebensmittel-MVP mit Scanner, Score und Details (Flutter) | implementiert und auf echtem iPhone validiert |
| Phase 3 | vollständiger S-/G-Score, Impact, Personalisierung | geplant |
| Phase 4 | Supermarkt-Integration, Payment, AR, Skalierung | Vision |

### Fortschritt der grossen Meilensteine

Die Prozentwerte messen den nachweisbaren Abschluss gegen das jeweilige
Meilensteinziel, nicht den Zeitverbrauch. Sie werden in 5-Prozent-Schritten
aktualisiert. `0%` bedeutet, dass fuer das konkrete Arbeitspaket noch keine
Implementierung begonnen hat; reine Planung oder Quellenrecherche zaehlt nicht
als technische Fertigstellung.

```text
M1  Lokaler MVP und Integrationsbaseline [####################] 100%
M2  Backend- und Datenanbindung           [#########-----------]  45%
M3  Kaffee als Referenzfall               [#########-----------]  45%
M4  Umwelt-, Social- und Governance-Daten [###-----------------]  15%
M5  Kalibrierte Methodik 2.0              [###-----------------]  15%
M6  MVP-Beta und Product Hardening        [################----]  80%
M7  App-Store-Release-Candidate           [#########-----------]  45%
M8  TestFlight, Submission und Release    [--------------------]   0%
```

| Meilenstein | Bereits erreicht | Noch bis 100% |
| --- | --- | --- |
| M1 | iOS-Kernflow, Datenarchitektur, Quality Gates und gruener Integrationsbranch | mit diesem Integrationsstand abgeschlossen |
| M2 | lokales Supabase-Schema, 13 RLS-Tabellen, 71 pgTAP-Tests sowie Backend-Threat-Model und EU-Umgebungsvertrag | EU-Entwicklungsprojekt, Server-Writer, Cache und Flutter-Read-Adapter |
| M3 | drei reproduzierbare Kaffee-GTINs, offizieller Deklarationsnachweis und produktgebundene Rohstoff-/Herkunftslinks | Umwelt-/Social-/Governance-Faktoren, versionierter Score-Snapshot und fachliche Kalibrierung |
| M4 | Quellenregister und Kandidaten fuer Wasser, Social-Risiko und Rechtstraeger | technische Anbindung, Mapping-, Lizenz- und Claim-Pruefung je Quelle |
| M5 | 26 Parameter, Safety Controls und ausgesetzte Aktivierungsregeln | Gewichte, Normalisierung, Testkorpus, Kalibrierung und Expertenreview |
| M6 | realer iPhone-Scanflow, Permission-Fallbacks, Dynamic Type, VoiceOver-Sprachwechsel und Fokusreihenfolge sowie Reduce Motion | dynamische Datenlokalisierung, Offline/History-Entscheidung und Feldtest |
| M7 | acht Apple-Gate-Gruppen, MASVS-2.1-Baseline, iOS-Compile, Privacy-Bundle-Audit sowie Claim-/Privacy-Aktivierungsgrenzen | offene Apple-/MASVS-/Rechts-/Fachreview-Evidenzen und signiertes Release-Archive |
| M8 | bewusst noch nicht begonnen | TestFlight, App-Store-Submission und Releaseentscheidung |

### Naechste Arbeitspakete

Die Pakete werden erst bei nachweisbarer Implementierung fortgeschrieben:

```text
N0  Compliance-/Security-Baseline        [################----]  80%
N1  Kaffee-Pilotprodukte festlegen        [####################] 100%
N2  Produkt -> Rohstoff -> Herkunft       [####################] 100%
N3  EU-Supabase-Projekt verbinden         [--------------------]   0%
N4  Server-Writer und Flutter-Cache       [--------------------]   0%
N5  WRI-Aqueduct-Wasserrisiko             [--------------------]   0%
N6  ILAB-Social-Risikomapping             [--------------------]   0%
N7  GLEIF/BRIS-Rechtstraegermapping       [--------------------]   0%
N8  Kalibrierung und Expertenreview       [--------------------]   0%
```

**Umsetzungsreihenfolge:** N0 besitzt jetzt den Dependency-/Supply-Chain-Scan,
die risikobasierte OWASP-MASVS-Baseline, fail-closed Claim-/Privacy-Grenzen
sowie ein STRIDE-/OWASP-API-Threat-Model mit EU-Supabase-Umgebungsvertrag;
offen sind die priorisierten manuellen Apple-, MASVS-, Rechts- und
Fachreview-Evidenzen. N1 und N2 des lokalen
evidence-first Kaffee-Referenzfalls sind abgeschlossen. Die produktgebundenen
Herkunfts-, Evidenz- und Backend-Sicherheitsvertraege sind jetzt stabil. Als
naechstes beginnen die offenen M2-Arbeiten mit dediziertem EU-Supabase-
Development-Projekt, vertrauenswuerdigem Server-Writer und read-only
Flutter-Cache. Erst danach werden WRI, ILAB und GLEIF/BRIS
kontrolliert angebunden; score-relevant werden sie erst nach Kalibrierung und
Fachreview.

Die Regeln fuer deutsche, englische und buchstabierte VoiceOver-Begriffe sind
in der [VoiceOver language and terminology policy](docs/project/accessibility/voiceover-language-policy.md)
zentral dokumentiert und automatisiert getestet.

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
| [ESG-Scoring-Modell v1.0](docs/ESG-SCORING-MODELL-v1.md) | historischer Konzeptstand; ADR 0011 ist fuer die Formel verbindlich |
| [ESG-Datenarchitektur](docs/project/data/data-architecture.md) | Provenienzmodell, Supabase-Grenze und Quellenregeln |
| [ESG-Methodikkatalog](docs/project/methodology-catalog/README.md) | versionierter Parameterkern und Pilotprofile fuer Kaffee, Banane und Kakao |
| [Delivery Operating Model](docs/project/delivery-operating-model.md) | verbindlicher Arbeitsrahmen fuer Prozess, Compliance, Entwicklung und Release |
| [Product Engineering Handbook](docs/project/methodology/product-engineering-handbook.md) | praktisches Gesamthandbuch zu Disziplinen, Methoden, Branches, Tests, DevSecOps und Reifepfad |
| [Lifecycle Gap Analysis](docs/project/methodology/gap-analysis-process.md) | systematische Suche nach fehlenden, partiellen, veralteten und noch nicht operationalisierten Fähigkeiten |
| [Gap-Register](docs/project/gap-register.yaml) | priorisierte P0-P2-Lücken mit Reifegrad, Owner, Trigger, Closure-Kriterien und Control-Mapping |
| [Verbesserungsregister](docs/project/improvement-register.yaml) | priorisierte Prozess-, Compliance-, Entwicklungs- und Betriebsverbesserungen mit Evidenz |
| [Supply-Chain-Policy](docs/project/compliance/supply-chain-policy.yaml) | OSV-, Lizenz-, native iOS-, Action-Pin- und Ausnahmevorgaben |
| [OWASP-MASVS-iOS-Baseline](docs/project/compliance/owasp-masvs-ios-baseline.yaml) | risikobasierte Klassifikation aller 24 MASVS-2.1-Kontrollen mit Release-Profil |
| [Claim-Inventar](docs/project/compliance/claim-inventory.yaml) | App-, Store- und Webseitenclaims mit Health-Grenze, Evidenz und Freigabestatus |
| [Privacy-Dateninventar](docs/project/compliance/privacy-data-inventory.yaml) | Datentypen, Zwecke, Empfänger, Regionen, Retention und Aktivierungsprofile |
| [Privacy-Datenfluss](docs/project/compliance/privacy-data-flow.md) | aktueller und geplanter Datenpfad sowie DPIA-Entscheidungsweg |
| [Design-Synthese](docs/DESIGN-SYNTHESIS.md) | Unterschiede zwischen altem Konzeptstand und neuen ScanFair-Prototypen |
| [Developer-Handoff](design_handoff_scanfair/README.md) | Vollständiges Paket für Claude Code: Tokens, Daten, Komponenten, Screens |
| [Pitch](docs/PITCH.md) | Projektargumentation und fachlicher Kontext |
| [Projekttagebuch](docs/PROJEKTTAGEBUCH.md) | Fortschritte, Entscheidungen und Learnings |

---

## 11 · Lokale Entwicklung & Quality Gates

Der aktuelle Entwicklungsstand bleibt lokal: kein TestFlight, kein App-Store,
kein Hosting und kein Online-Release. Die App scannt EAN-/UPC-Barcodes mit der
iPhone-Kamera und laedt Produktdaten ueber Open Food Facts API v3. Manuelle
Barcode-Eingabe und injizierbare Demo-Daten bleiben als Fallback und fuer
deterministische Tests erhalten. ESG-Score-Logik, Result-/Detail-Screens,
Low-Data-, Not-Found-, Permission- und technische Fehlerzustaende sind
implementiert.

**Validierter MVP-Stand (11. August 2026)**

| Bereich | Ergebnis |
| --- | --- |
| Zielplattform | iOS-first Flutter-MVP auf physischem iPhone installiert |
| App-Start | Signierter Profile-Build startet eigenstaendig vom Home-Bildschirm |
| Kamera | Kameraberechtigung und nativer Barcode-Scanner erfolgreich getestet |
| Scan-Flow | EAN-/UPC-Barcode erkannt und an den Produktlookup uebergeben |
| Produktdaten | Open Food Facts API v3 liefert reale Produktinformationen mit feldgenauer Evidenz-Provenienz |
| Umweltquelle | AGRIBALYSE 3.2 liefert offiziellen GHG-Kategorieproxy, DQR und Attribution; noch nicht score-aktiv |
| Scoring | ESG-Gesamtscore sowie E-/S-/G-Details werden regelbasiert berechnet |
| Ergebnis-UX | Resultat, Detailinformationen und Quellen sind sichtbar; Nährwerte erscheinen neutral ohne Health-Score oder Fortschrittsbalken |
| Methodik | Formel v1.0 aktiv; v2-Parameterkatalog mit 26 Parametern und vier Profilen als gepruefter Entwurf |
| Datenbank | Dreizehn Supabase-Tabellen reproduzierbar; 55 pgTAP-Tests und DB-Lint bestanden, Remote noch nicht verbunden |
| Traceability | Rohstoff-, Produktherkunfts- und Markenhinweise werden mit Quelle, Assertion-Klasse und Confidence modelliert; OFF-Hinweise bleiben noch nicht score-aktiv |
| Supply Chain | 59 Dart-Pakete, 2 iOS-Plugins und 16 Action-Referenzen inventarisiert; OSV meldet 0 bekannte Schwachstellen |
| Fallbacks | Manuelle Eingabe, Demo-Daten, Not Found, Low Data, Permission- und API-Fehler vorhanden |
| Release-Scope | Kein TestFlight, App-Store-Release, Hosting oder iOS-Deployment |

Der physische Smoke-Test deckt die Kernschleife
`Oeffnen -> Scannen -> Produkt finden -> Score verstehen -> Details pruefen`
vollstaendig ab. Fachliche Spezifikationen, weitere Datenquellen und die
Vertiefung des S-/G-Scores bleiben Gegenstand der naechsten Iterationen.

**App lokal starten**

```bash
cd /Users/mustafademir/ESG-Score-App/esg_app
flutter pub get
flutter run
```

Die Kamera kann nicht realistisch im iOS-Simulator getestet werden. Fuer einen
lokalen Test auf dem eigenen iPhone: iPhone per USB verbinden, entsperren,
diesem Mac vertrauen und den Developer Mode aktivieren. Danach in Xcode unter
`Runner > Signing & Capabilities` das eigene Apple-Team auswaehlen und starten:

```bash
cd /Users/mustafademir/ESG-Score-App/esg_app
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter devices
flutter run -d <IPHONE_DEVICE_ID>
```

`flutter run` installiert einen Debug-Build. Dieser kann auf aktuellen
iOS-Versionen nur mit aktiver Flutter-/Xcode-Verbindung gestartet werden. Fuer
einen lokal installierten Build, der eigenstaendig vom Home-Bildschirm startet,
wird der Profile-Modus verwendet:

```bash
cd /Users/mustafademir/ESG-Score-App/esg_app
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter run --profile --no-resident -d <IPHONE_DEVICE_ID>
```

**Quality Gates lokal ausfuehren**

```bash
cd /Users/mustafademir/ESG-Score-App
bash scripts/quality/run_quality_gates.sh
bash scripts/quality/run_supply_chain_gate.sh
bash scripts/quality/run_ios_build_gate.sh
bash scripts/quality/run_data_database_gate.sh

# Lizenzarchitektur: lokal gruen, Remote-Profil bleibt bis zur Freigabe rot
DATA_LICENSE_PROFILE=development bash scripts/quality/run_quality_gates.sh
ruby scripts/quality/validate_data_license_composition.rb --profile remote_backend

# Claim-/Privacy-Grenzen: lokal gruen, strikte Profile bis zur Freigabe rot
ruby scripts/quality/validate_claims_privacy_boundaries.rb --gate claims --profile development
ruby scripts/quality/validate_claims_privacy_boundaries.rb --gate privacy --profile development
ruby scripts/quality/validate_claims_privacy_boundaries.rb --gate claims --profile release_candidate
ruby scripts/quality/validate_claims_privacy_boundaries.rb --gate privacy --profile release_candidate

# Backend-Grenze: Definition-of-ready gruen, Remote bis zur Implementierung rot
ruby scripts/quality/validate_backend_boundary.rb --profile development
ruby scripts/quality/validate_backend_boundary.rb --profile remote_backend
ruby scripts/quality/validate_backend_boundary.rb --profile release_candidate

# Strenger App-Store-Release-Check (offene MUST-Evidenz blockiert)
COMPLIANCE_PROFILE=release_candidate bash scripts/quality/run_quality_gates.sh
```

Das Script erzeugt `.quality/quality-gate-report.md` und fuehrt diese Gates aus:

| Gate | Zweck |
| --- | --- |
| `G-FLT-DEPS` | Flutter Dependencies reproduzierbar aufloesen |
| `G-SUPPLY-CHAIN` | Lockfile, OSV-Findings, Lizenzen, native iOS-Plugins und unveraenderliche Action-SHAs pruefen |
| `G-MASVS` | Risikobasierte OWASP-MASVS-2.1-Baseline und offene Device-Evidenz pruefen |
| `G-FLT-FORMAT` | Format-Drift blocken |
| `G-FLT-ANALYZE` | Statische Analyse mit `--fatal-infos` |
| `G-FLT-TEST` | Unit- und Widget-Tests mit Coverage |
| `G-FLT-COVERAGE` | Mindestens 60% Line-Coverage gemaess Sprint-2-Baseline |
| `G-CMP-SCHEMA` | Requirement-, Source-, Gate- und Policy-Links validieren |
| `G-REG-UNIT` | Rego-Policy-Tests fuer Compliance-Regeln |
| `G-CMP-APPLE` | Acht Apple-Entscheidungs-Gates via Conftest auswerten |
| `G-CMP-EVIDENCE` | SHA-256-Evidence-Chain vollstaendig verifizieren |
| `G-DATA-ARCH` | Supabase-Migration, RLS, Client-Rechte und Datenlizenzen pruefen |
| `G-DATA-LICENSE` | ODbL-Komposition, Quellen-Trennung, Attribution und Remote-Freigabegrenzen pruefen |
| `G-METHOD-CATALOG` | Parameter, Profile, Vererbung, Claims und ausgesetzte Gewichtung validieren |
| `G-LINK-INTEGRITY` | Produkt-, Rohstoff-, Herkunfts- und Rechtstraegerlinks auf Evidenz und Confidence pruefen |
| `G-MISSING-DATA` | Positive, neutrale oder Null-Imputation bei fehlenden Daten verbieten |
| `G-RED-FLAG` | Nicht-kompensierbare Regeln fuer bestaetigte schwere Risiken pruefen |
| `G-SCORE-REPRO` | Formel-, Evidenz-, Relationship- und Fingerprint-Lineage validieren |
| `G-CLAIM-SAFETY` | Risiko-, Proxy- und Kundenaussagen gegen unzulaessige Behauptungen pruefen |
| `G-CLAIM-GOVERNANCE` | Claim-Inventar, neutrale Nährwertgrenze und gehashte Rechts-/Fachreview-Evidenz pruefen |
| `G-PRIVACY-BOUNDARY` | Ist-Datenfluss, Retention, DPIA-Entscheidung und Beta-/Remote-Aktivierung pruefen |
| `G-BACKEND-BOUNDARY` | Threat Model, Trusted-Writer-, Secret-, Rate-, Idempotenz-, Audit- und EU-Aktivierungsvertrag pruefen |
| `G-DATA-RLS` | Migration real abspielen, 55 pgTAP-RLS-Tests und PostgreSQL-Lint ausfuehren |
| `G-PROJECT-CONTROL` | Lifecycle-Gaps, Improvements, Quellen-/Risiko-Mappings und Feature-Status gegen Drift pruefen |
| `G-DOC-TRACE` | README/Workflow-Dokumentation gegen Drift pruefen |
| `G-DOC-YAML` | Alle YAML-Dateien der Projekt-SSOT syntaktisch validieren |
| `G-IOS-COMPILE` | Nativen unsigned iOS-Simulator-Build und gebuendelte Privacy Manifests auf macOS/Xcode validieren |

Die fuenf Scoring-Safety-Gates sichern die Aktivierungsregeln fuer
Methodik `2.0-draft`. Sie erklaeren Formel v1.0 nicht nachtraeglich fuer
wissenschaftlich kalibriert oder rechtlich ESG-konform; deren S-/G-Anteile
bleiben als heuristischer MVP-Stand gekennzeichnet.

Das Backend-Development-Profil beweist nur die Definition-of-Ready bei
deaktiviertem Remote-Pfad. `remote_backend` verlangt drei Implementierungs- und
Betriebsreviews; `release_candidate` verlangt zusaetzlich und unabhaengig vom
Aktivierungsstatus einen an den geprueften Commit gebundenen Security-Review.

**GitHub Actions**

Die Action [Quality Gates](.github/workflows/quality-gates.yml) laeuft auf
Pushes nach `main`, Pull Requests nach `main` und manuell via
`workflow_dispatch`. Branch-Pushes ohne Pull Request erzeugen bewusst keinen
doppelten Lauf.
Sie veroeffentlicht Gate-Summaries und die Artefakte
`scanfair-quality-gate-results`, `scanfair-supply-chain-evidence` sowie
`scanfair-ios-simulator-app`. Das
iOS-Artefakt enthaelt neben `Runner.app` auch `ios_privacy_audit.json` mit den
geprueften App-, Flutter- und `mobile_scanner`-Privacy-Manifests. Neben den
fuenfundzwanzig lokalen Gate-Gruppen laufen ein sichtbarer
Supply-Chain-/Dependency-Review-Job, ein eigener nativer
iOS-Compile-/Privacy-Job, der echte Supabase-/RLS-Datenbanktest und ein
separater Gitleaks-Secret-Scan. Dependabot prueft `pub` und GitHub Actions
woechentlich; ein geplanter Montagslauf prueft den bestehenden Lockfile-Stand
erneut gegen neu veroeffentlichte Schwachstellen. Bei manuellen Laeufen kann zwischen
`development`, `release_candidate` und `submission` gewaehlt werden.

`G-CMP-APPLE` umfasst `G-AS-BUILD-INTEGRITY`, `G-AS-PRIVACY`, `G-AS-CAMERA`,
`G-AS-METADATA`, `G-AS-REVIEW-READINESS`, `G-AS-CLAIMS-TRANSPARENCY`,
`G-AS-THIRD-PARTY-RIGHTS` und `G-AS-SUPPORT-IDENTITY`. Im Entwicklungsprofil bleiben noch nicht faellige
Release-Nachweise als sichtbare Warnungen offen. Ab `release_candidate`
blockiert jede anwendbare, unerfuellte MUST-Anforderung.

Der operative Kontrollrahmen steht in
[`apple-compliance-control-model.md`](docs/project/compliance/apple-compliance-control-model.md).
Die bisherige gruene MVP-Pipeline bleibt ein Entwicklungsnachweis; sie ist nicht
mit einer App-Store-Releasefreigabe gleichzusetzen. Der strenge Release-Check
bleibt rot, bis Privacy-, Store-, Device-, Claims-, Lizenz- und Support-Evidenz
vollstaendig vorliegt. Die technischen Privacy-Teile von
`G-AS-BUILD-INTEGRITY` sind geschlossen: Das App-Privacy-Manifest ist im
Xcode-Projekt eingebunden, das gebaute Bundle wird geprueft und der
SDK-/Required-Reason-Review ist per SHA-256 an `pubspec.lock`,
`PrivacyInfo.xcprivacy` und den iOS-Plugin-Registrant gebunden. Eine
Abhaengigkeits- oder Manifest-Aenderung macht diesen Review automatisch
ungueltig. Das strikte Gate bleibt bis zur Publisher-Signaturvalidierung der
gelisteten binaeren SDKs am signierten Release-Archive bewusst rot.

Explizit ausgeschlossen: iOS-Deployment, Online-Release, Hosting-Provider,
Kubernetes und OPA Gatekeeper. Die App uebernimmt aus
`genaiops-compliance-gates` nur die relevanten Muster: Gate-Definitionen,
Policy-as-Code, Evidence-Log und sichtbare CI/CD-Entscheidung.

---

## Autor

**Mustafa Demir**  
Digitale Transformation Consulting AI & Cloud Solution Architecture

Dieses Projekt dokumentiert den Weg vom Konzept zur App: methodisch, transparent und mit dem Ziel, nachhaltige Kaufentscheidungen verständlicher zu machen.
