# Tech-Stack-Erklärung — Was ich als Solo-Founder gebaut habe

> Zwei Ebenen: erst die **nicht-technische Tisch-Erklärung** (für Investoren,
> Familie, nicht-technische Gesprächspartner), dann die **technische
> Aufschlüsselung** mit allen Tools. Companion zu
> [vorgehenssystem.md](vorgehenssystem.md).
> Letztes Update: 2026-05-22

---

## Teil 1 — Die Tisch-Erklärung (nicht-technisch)

> Stell dir vor, ich baue die App nicht einfach drauflos, sondern wie eine
> **sehr ordentliche Fabrik mit eingebautem Qualitäts-Inspektor**. Ich bin zwar
> allein, aber ich habe mir lauter unsichtbare Helfer gebaut, die aufpassen.

1. **Bautagebuch** — Jede wichtige Entscheidung schreibe ich auf. So weiß ich
   in drei Monaten noch warum ich was gemacht habe.
2. **Gedächtnis** — Ich muss nie überlegen „wo war ich nochmal?". Alles ist
   ordentlich abgelegt; ich tippe „Status?" und sehe sofort den Stand.
3. **TÜV bei jedem Speichern** — Bei jedem Speichern prüft automatisch ein
   Wächter: keine Passwörter im Code, sauberer Code, Tests grün. Sonst kein
   Speichern. Wie ein Auto das ohne Gurt nicht anspringt.
4. **Regel-Wächter** — Apples 40 Seiten Regeln + EU-Datenschutz habe ich in
   einen kleinen Roboter übersetzt, der automatisch prüft. Das ist genau das
   System aus meiner Masterarbeit — und es funktioniert für Apple-Regeln UND
   Datenschutz gleichzeitig.
5. **Blackbox** — Von jeder Prüfung gibt es ein fälschungssicheres Protokoll,
   wie die Blackbox im Flugzeug.

**Ein-Satz-Pitch:**
> „Ich hab mir als Solo-Entwickler ein System gebaut, das automatisch aufpasst
> dass mein Code sicher ist, alle Apple- und Datenschutz-Regeln eingehalten
> werden und jede Entscheidung dokumentiert ist — die Regel-Prüfung kommt
> direkt aus meiner Masterarbeit."

---

## Teil 2 — Technische Aufschlüsselung

### Fundament — die Werkzeuge unter allem

| Tool | Was ist das? | Wofür bei uns |
|---|---|---|
| **Git** | Versionskontrolle — speichert jede Änderung als Schnappschuss | Alles versioniert + rückverfolgbar |
| **GitHub** | Cloud-Hosting für Git + Automatisierungs-Plattform | Backup, Pull Requests, CI |
| **Homebrew** | Paket-Manager für macOS | Flutter, gitleaks, conftest installiert |
| **YAML / Markdown** | Menschen-lesbare Text-Formate | ADRs, Roadmap, Requirements, Doku |

### Netz 1 — Bautagebuch (Entscheidungen)

| Tool / Methode | Was ist das? | Eingesetzt für |
|---|---|---|
| **ADR** (Architecture Decision Record) | Pattern: jede Entscheidung als Dokument mit Kontext + Alternativen + Begründung | 13 ADRs in `decisions/` |
| **YAML** | Strukturiertes Format für Mensch + Maschine | ADRs maschinell auswertbar |
| **Git append-only** | Entscheidungen nie überschreiben, nur ersetzen | `supersedes`-Verkettung |

### Netz 2 — Gedächtnis (Kontext)

| Tool / Methode | Was ist das? | Eingesetzt für |
|---|---|---|
| **`CLAUDE.md`** | Datei die Claude Code beim Start automatisch liest | Session-Start-Protokoll |
| **Single Source of Truth** | Prinzip: eine maßgebliche Quelle | `docs/project/` |
| **Feature-States** (YAML) | Status-Datei pro Feature | `features/*/state.yaml` |
| **lade_manifest** | Aus ai-context-vault: deklariert relevante Dateien | Token-Effizienz |

### Netz 3 — TÜV bei jedem Speichern (CI/CD/CT)

| Tool | Was ist das? | Eingesetzt für |
|---|---|---|
| **Git Pre-Commit-Hook** | Skript das vor jedem Commit läuft | `scripts/hooks/pre-commit` |
| **gitleaks** | Scanner für Passwörter/API-Keys im Code | Secret-Schutz |
| **dart format** | Dart-Code-Formatierer | Einheitlicher Stil |
| **flutter analyze** | Statische Code-Analyse | Lint-Prüfung |
| **flutter test** | Test-Runner | 3 Widget-Tests pro Lauf |
| **GitHub Actions** | CI/CD-Plattform, läuft bei jedem Push | `.github/workflows/ci.yml` |

Zwei Verteidigungslinien: **lokal** (Pre-Commit-Hook) + **remote** (GitHub Actions).

### Netz 4 — Regel-Wächter (Compliance-as-Code)

| Tool | Was ist das? | Eingesetzt für |
|---|---|---|
| **OPA** (Open Policy Agent) | Industrie-Standard-Engine zum Regel-Prüfen | Fundament der Master-Thesis-Methodik |
| **Rego** | Sprache für OPA-Regeln | `policy_app_name_length.rego` (8 Regeln) |
| **Conftest** | Führt Rego gegen Config-Dateien aus | Gate-Ausführung |
| **CDV-Pattern** | Contract → Validation → Severity → Decision (aus Thesis) | Policy-Struktur |
| **`compliance-manifest.json`** | Hand-gepflegte Deklarationen | Privacy-URL, Support-URL, ... |
| **plutil** | macOS-Tool für Apple-Plist-Dateien | App-Name aus `Info.plist` extrahieren |
| **jq** | JSON-Verarbeitung auf der Kommandozeile | Daten-Quellen zu Prüf-Datei mergen |

Ablauf:
```
echte App-Dateien ──(plutil/grep)──► app_extracted.json ──┐
                                                           ├─(jq merge)─► compliance_input.json
compliance-manifest.json ──────────────────────────────────┘                    │
                                                                                 ▼
                                            conftest test ──(Rego)──► PASS/FAIL
```

### Netz 5 — Blackbox (Audit-Trail)

| Tool / Methode | Was ist das? | Eingesetzt für |
|---|---|---|
| **SHA-256** | Kryptografische Hash-Funktion (eindeutiger Fingerabdruck) | Fingerabdruck pro Protokoll-Eintrag |
| **Hash-Chain** | Jeder Eintrag enthält Fingerabdruck des vorherigen | `evidence-log.jsonl` manipulationssicher |
| **JSONL** | Eine JSON-Zeile pro Eintrag | Audit-Trail-Format |

Manipulation eines alten Eintrags bricht die Kette → sofort erkennbar. Solo-
Variante des Evidence-Stores aus der Master-Thesis (dort Postgres + Hash-Chain).

### Die App selbst

| Tool | Was ist das? |
|---|---|
| **Flutter** | Google-Framework für iOS + Android aus einer Codebase |
| **Dart** | Programmiersprache von Flutter |
| **google_fonts** | Flutter-Paket für Schriften (Inter, Instrument Serif) |
| **Mermaid** | „Diagramm-als-Text", GitHub rendert es zur Grafik |

---

## Der Satz für technische Gesprächspartner

> „Ich habe einen **repo-nativen DevSecOps-Stack** für Solo-Entwicklung gebaut:
> Git + GitHub Actions für CI/CD, gitleaks + Git-Hooks als Security-Gate, und —
> als Kern — **Policy-as-Code mit OPA/Rego + Conftest** das regulatorische
> Anforderungen (Apple, DSGVO) automatisch gegen den echten App-Zustand prüft,
> mit SHA-256-Hash-Chain als manipulationssicherem Audit-Trail. Die Compliance-
> Methodik stammt aus meiner Masterarbeit über EU-AI-Act-Quality-Gates."

---

## Mapping: Tisch-Erklärung ↔ Technik (Spickzettel)

| Tisch-Begriff | Technisch |
|---|---|
| Bautagebuch | ADRs (YAML) in Git |
| Gedächtnis | CLAUDE.md + docs/project/ SSOT + Feature-States |
| TÜV bei jedem Speichern | Pre-Commit-Hook (gitleaks, dart format) + GitHub Actions |
| Regel-Wächter | OPA/Rego + Conftest + compliance-manifest |
| Blackbox | SHA-256 Hash-Chain in evidence-log.jsonl |
| Roboter aus der Masterarbeit | genaiops-compliance-gates Methodik (regulation-agnostic) |
