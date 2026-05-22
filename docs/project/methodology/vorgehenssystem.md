# ScanFair Vorgehenssystem — Gesamtüberblick

> Synthese der Entwicklungs-Methodik. Vier Quellen werden zu einem
> integrierten, repo-nativen Vorgehenssystem verschmolzen.
> Dient als Basis für die README-Integration.
> Letztes Update: 2026-05-19

---

## TL;DR — Was ist das System?

ScanFair wird nicht „einfach drauflos" entwickelt, sondern nach einem
**integrierten Vorgehenssystem aus vier Quellen**, das vollständig im Git-Repo
lebt (keine externen Tools, kein Vendor-Lock-in). Jede Quelle steuert eine
Schicht bei:

| # | Quelle | Beitrag | Schicht |
|---|---|---|---|
| 1 | **DevOps / GitHub** (etablierte Best Practice) | CI/CD/CT, Hooks, Quality-Gates | Automatisierung |
| 2 | **ai-context-vault** (eigenes Kontext-Toolkit) | Kontext-Konsistenz, Feature-States, lade_manifest | Gedächtnis |
| 3 | **thesis-workflow Skills** (eigene Cowork-Skills) | Session-Workflows, Trigger-Phrasen | Ritual |
| 4 | **genaiops-compliance-gates** (Master-Thesis-Referenzarchitektur) | Compliance-as-Code, Rego-Policies, Gates | Regelkonformität |

Geklebt wird alles durch das **Projekt-Management-Fundament** (`docs/project/`)
und den Eingangspunkt **`CLAUDE.md`**.

---

## Skizze — Das Vorgehenssystem

```
                        SCANFAIR ENTWICKLUNGS-METHODIK
                   „4 Quellen → 1 integriertes Vorgehenssystem"

┌─ QUELLE 1 ─────────┐ ┌─ QUELLE 2 ──────────┐ ┌─ QUELLE 3 ─────────┐ ┌─ QUELLE 4 ───────────────┐
│ DevOps / GitHub    │ │ ai-context-vault    │ │ thesis-workflow    │ │ genaiops-compliance-     │
│ (Best Practice)    │ │ (Kontext-Toolkit)   │ │ Skills             │ │ gates (Master-Thesis)    │
│                    │ │                     │ │                    │ │                          │
│ • GitHub Actions   │ │ • Feature-State     │ │ • session-start    │ │ • Requirements (R-NN)    │
│ • Pre-Commit-Hooks │ │ • Status-Enum       │ │ • pre-coding-check │ │ • Gate-Definitions       │
│ • Test-Pyramide    │ │ • lade_manifest     │ │ • post-feature     │ │ • Rego-Policies + Tests  │
│ • Coverage-Gates   │ │ • decisions/INDEX   │ │ • Trigger-Phrasen  │ │ • CDV + Evidence-Log     │
│ • Secret-Scan      │ │ • Session-Memory    │ │                    │ │ • Cross-Regulation-Map   │
└─────────┬──────────┘ └──────────┬──────────┘ └─────────┬──────────┘ └────────────┬─────────────┘
          │                       │                      │                         │
          │   ADR 0007/0008       │   ADR 0009           │   ADR 0009              │   ADR 0012/0013
          │                       │                      │                         │
          └───────────────────────┴──────────┬───────────┴─────────────────────────┘
                                              │
                                              ▼
                  ╔═══════════════════════════════════════════════════╗
                  ║   docs/project/   —   SINGLE SOURCE OF TRUTH      ║
                  ║   (alles versioniert, diff-bar, im Git-Repo)      ║
                  ╠═══════════════════════════════════════════════════╣
                  ║  decisions/      ADRs (Architektur-Entscheidungen)║
                  ║  roadmap.yaml    Phasen + Out-of-Scope            ║
                  ║  backlog.yaml    TODOs + Ideen                    ║
                  ║  risks.yaml      Risiko-Register                  ║
                  ║  progress.yaml   Fortschritt + Weekly-Log         ║
                  ║  workflows/      Session-Rituale                  ║
                  ║  compliance/     Apple + DSGVO + Cross-Reg-Map    ║
                  ║  requirements/   R-AS-NN · R-DSGVO-NN             ║
                  ║  policies/       Rego + Tests                     ║
                  ║  features/       Feature-States                  ║
                  ╚════════════════════════════╤══════════════════════╝
                                               │
                                               ▼
                  ┌────────────────────────────────────────────────┐
                  │   CLAUDE.md   —   EINGANGSPUNKT                 │
                  │   • Session-Start-Protokoll (Pflicht-Reads)    │
                  │   • Trigger-Phrasen → Workflows                │
                  │   • Tech-Stack + Security-Baseline-Verweise    │
                  └────────────────────────────┬───────────────────┘
                                               │
                          ┌────────────────────┴────────────────────┐
                          ▼                                          ▼
            ┌──────────────────────────┐              ┌──────────────────────────┐
            │  ENTWICKLUNG (Mensch +    │              │  AUTOMATISIERUNG (CI)     │
            │  Claude Code)             │              │                           │
            │                          │              │  GitHub Actions:          │
            │  „Status?" → Dashboard   │              │  • analyze + format + test│
            │  „GO" → Pre-Coding-Check │   git push   │  • gitleaks Secret-Scan   │
            │  Code + Tests schreiben  │  ─────────►  │  • (später) Conftest      │
            │  „fertig" → Post-Feature │              │    Compliance-Gates       │
            └────────────┬─────────────┘              └────────────┬──────────────┘
                         │                                         │
                         └────────────────────┬────────────────────┘
                                               ▼
                          ┌────────────────────────────────────────┐
                          │   esg_app/   —   DIE FLUTTER-APP        │
                          │   lib/ · test/ · Theme · Feature-Code   │
                          └────────────────────────────────────────┘
```

---

## Die 4 Quellen im Detail

### Quelle 1 — DevOps / GitHub (Automatisierung)

Etablierte Software-Engineering-Best-Practice, von Anfang an minimal integriert.

| Element | Datei / Ort | ADR |
|---|---|---|
| CI/CD-Pipeline | `.github/workflows/ci.yml` | 0007 |
| Pre-Commit-Hooks (gitleaks, dart format) | `scripts/hooks/pre-commit` | 0008 |
| Test-Pyramide + Coverage-Gates | `quality-strategy.md` | 0007 |
| Failure-Modes-Register | `failure-modes.yaml` | — |
| Security-Baseline (7 Praktiken) | `decisions/0008-*` | 0008 |

**Prinzip:** Catch fast, fail loud. Jeder Commit/PR durchläuft automatische Checks.

### Quelle 2 — ai-context-vault (Gedächtnis)

Eigenes Context-Engineering-Toolkit (entwickelt für Master-Thesis-Workflow).
Übernommen wurden die HIGH-ROI-Patterns, nicht das Voll-Framework.

| Element | Übersetzt zu | ADR |
|---|---|---|
| chapter_state.yaml | `features/<x>/state.yaml` | 0009 (ACV-1) |
| Status-Enum | `conventions.md` (planned→…→done) | 0009 (ACV-2) |
| lade_manifest | in `definition-of-done.yaml` | 0009 (ACV-3) |
| entscheidungsregister | `decisions/INDEX.md` | 0009 (ACV-4) |

**Prinzip:** Kein „wo waren wir nochmal?". Alles steht im Repo, Claude liest es.
**Bewusst nicht übernommen:** Azure-Hub, eigene Skills, Plugins (Overkill für Solo).

### Quelle 3 — thesis-workflow Skills (Ritual)

Die 7 Cowork-Skills der Master-Thesis als Vorlage. Übernommen als Markdown-
Workflows (keine eigenen Skills bauen — wartungsärmer).

| Vault-Skill | ScanFair-Workflow | Trigger |
|---|---|---|
| thesis-session-manager (S1-S5) | `workflows/session-start.md` | „Status?" |
| thesis-preflight (P0-P6) | `workflows/pre-coding-check.md` | „GO" |
| thesis-post-session (A-F) | `workflows/post-feature.md` | „fertig für heute" |

**Prinzip:** Strukturierter Ein- und Ausstieg pro Session.
**Bewusst nicht übernommen:** thesis-writer, evidence-matrix-builder,
consistency/reviewer (durch Anthropic-Skills + CI abgedeckt).

### Quelle 4 — genaiops-compliance-gates (Regelkonformität)

Die Master-Thesis-Referenzarchitektur (EU-AI-Act-Compliance via Policy-as-Code,
DOI 10.5281/zenodo.19920310). Solo-Variante übernommen, regulation-agnostic
angewendet auf Apple + DSGVO.

| Element | Bei ScanFair | ADR |
|---|---|---|
| Requirement-YAML (7-Felder) | `requirements/R-AS-NN`, `R-DSGVO-NN` | 0012/0013 |
| Gate-Definition (7-Attribute) | `gate-definitions/apple/` | 0012 |
| Rego-Policy + Tests | `policies/apple/` | 0012 |
| CDV-Pattern | in Rego-Policies | 0012 |
| Evidence-Log (SHA-256) | `evidence-store/` (geplant) | 0009 (GCG-3) |
| Cross-Regulation-Mapping | `compliance/cross-regulation-map.md` | 0013 |

**Prinzip:** Compliance ist eine Pipeline-Eigenschaft, kein Dokument danach.
**Solo-Anpassung:** Kein K8s/Gatekeeper/Postgres — Conftest + JSONL reichen.
**Generalisierung:** Phasen 2-7 des Thesis-Prozessmodells sind regulation-agnostic.

---

## Wie ein Feature durch das System fließt (Lifecycle)

```
1. Session-Start
   │  User: „Status?" → CLAUDE.md → session-start.md → Dashboard
   ▼
2. Pre-Coding-Check
   │  User: „GO" → pre-coding-check.md (P1-P6)
   │  Prüft: Roadmap-Scope · ADRs · Failure-Modes · Risks · Test-Plan
   │  Bei Architektur-Entscheidung → neue ADR
   ▼
3. Implementation
   │  Code + Tests schreiben (Test-Pyramide aus quality-strategy.md)
   │  Feature-State.yaml aktualisieren (Status-Enum)
   ▼
4. Pre-Commit (lokal, automatisch)
   │  gitleaks + dart format + Merge-Marker-Check
   ▼
5. CI (GitHub Actions)
   │  analyze + format + test + Secret-Scan
   │  (später) Conftest Compliance-Gates gegen requirements/
   ▼
6. Post-Feature
   │  User: „fertig für heute" → post-feature.md (A-F)
   │  Prüft: Code+Tests · Feature-State · ADRs · progress.yaml · Diff · Commit
   ▼
7. Evidence
      Commit + (später) evidence-log.jsonl Eintrag mit SHA-256
```

---

## Warum dieses System? (Begründung für README)

| Problem (typisch Solo-Founder) | Unsere Lösung |
|---|---|
| „Wo waren wir nochmal?" nach Pause | Quelle 2: Repo ist Gedächtnis |
| Vergessene Tests, Build-Drift | Quelle 1: CI erzwingt Qualität |
| Unstrukturierter Wiedereinstieg | Quelle 3: Session-Workflows |
| Compliance erst nach Launch (Abmahnung) | Quelle 4: Compliance-as-Code |
| Entscheidungen vergessen / widersprüchlich | ADRs (append-only) |
| Scope-Creep | roadmap.yaml Out-of-Scope-Liste |

**Kern-Eigenschaft:** Alles lebt im Git-Repo. Versioniert, diff-bar, ohne
externe Tools, ohne Vendor-Lock-in. Jede neue Claude-Code-Session hat sofort
vollen Kontext.

---

## Akademische Note (für Thesis-Bezug)

Quelle 4 (genaiops-compliance-gates) ist Mustafas eigene Master-Thesis-
Referenzarchitektur. Die Anwendung auf ScanFair beweist die **Generalisierbarkeit
des Frameworks**: das in der Thesis für den EU AI Act entwickelte 7-Phasen-
Prozessmodell funktioniert identisch für Apple Guidelines und DSGVO. Nur Phase 1
(Regulatorische Analyse) wechselt den Input — Phasen 2-7 sind wiederverwendbar.

Dies ist potenzielles Future-Work / Diskussions-Material für die Thesis:
„Cross-Regulation Compliance-as-Code — Generalisierung jenseits des EU AI Act".

---

## Datei-Landkarte (für README-Verweis)

```
ESG-Score-App/
├── CLAUDE.md                      # Eingangspunkt + Session-Protokoll
├── .github/workflows/ci.yml       # Quelle 1: CI/CD
├── scripts/hooks/pre-commit       # Quelle 1: Pre-Commit-Hooks
├── docs/project/
│   ├── methodology/               # Wie wir arbeiten (inkl. dieser Datei)
│   ├── decisions/                 # ADRs + INDEX.md
│   ├── workflows/                 # Quelle 3: Session-Rituale
│   ├── features/                  # Quelle 2: Feature-States
│   ├── compliance/                # Quelle 4: Regel-Mappings
│   ├── requirements/              # Quelle 4: R-AS / R-DSGVO
│   ├── policies/                  # Quelle 4: Rego-Policies
│   ├── gate-definitions/          # Quelle 4: Gate-Specs
│   ├── roadmap.yaml · backlog.yaml · risks.yaml · progress.yaml
│   ├── quality-strategy.md · failure-modes.yaml · definition-of-done.yaml
│   └── implementation-plan.yaml   # 22-Schritte-Plan
└── esg_app/                       # Die Flutter-App
```
