# Feature-States

> Pro Feature-Modul ein `state.yaml`. Übernommen aus ai-context-vault
> chapter_state.yaml (siehe [ADR 0009](../decisions/0009-methodology-adoption.yaml) ACV-1).
> Template: [`../methodology/feature-state-template.yaml`](../methodology/feature-state-template.yaml).

## Verfügbare Features

| Feature | Status | Fortschritt | Phase | Sprint |
|---|---|---:|---|---:|
| [scanner](scanner/state.yaml) | review | 95% | phase-1-mvp | 2 |
| [scoring](scoring/state.yaml) | review | 95% | phase-1-mvp | 1 |
| [results](results/state.yaml) | review | 95% | phase-1-mvp | 2 |

## Wann ein neuer Feature-State?

- Sobald ein abgegrenztes Feature-Modul angefangen wird (Code in `esg_app/lib/`)
- VOR der ersten Code-Zeile dieses Features
- Beim Pre-Coding-Check (siehe [workflows/pre-coding-check.md](../workflows/pre-coding-check.md))

## Was ist KEIN eigenes Feature

- Setup-Tasks (Flutter-Init, CI-Setup, Hooks)
- Übergreifende Doku/Methodik
- Einmalige Spikes

## Wartung

- **Status-Updates** beim Workflow `post-feature.md` Schritt B
- **Progress (%)** ehrlich tracken, nicht aufrunden
- **decisions** bei Feature-spezifischen Entscheidungen (FD-XX), bei Architektur-Entscheidungen lieber ADR
- **cross_feature_dependencies** bei Hinzufügen NEUER Verbindungen ergänzen

## Verbindung zu Code

Aktuelle Kernstruktur:

```
esg_app/lib/
├── accessibility/
│   └── semantic_terminology.dart       ← feature: results, shared semantics
├── screens/
│   ├── scanner_screen.dart             ← feature: scanner
│   ├── result_screen.dart              ← feature: results
│   ├── detail_screen.dart              ← feature: results
│   └── ...
├── services/
│   ├── open_food_facts_service.dart  ← feature: scoring
│   ├── esg_score_calculator.dart     ← feature: scoring
│   └── ...
├── widgets/
│   └── score_widgets.dart             ← feature: results
└── models/
    ├── product.dart                    ← feature: scoring
    └── esg_score.dart                  ← feature: scoring
```

Der Phase-1-MVP verwendet Flutter-native Zustandsverwaltung mit Constructor
Injection gemaess ADR 0015. Die bestehende type-based Ordnerstruktur bleibt
fuer den aktuellen Umfang bestehen; eine spaetere Umstellung braucht eine
eigene Architekturentscheidung.
