# Evidence Store

> Solo-Variante des Evidence-Stores aus der Master-Thesis-Referenzarchitektur
> (`genaiops-compliance-gates`, dort Postgres + Blob + Hash-Chain).
> Hier: dateibasiert mit SHA-256-Chain. Siehe
> [ADR 0009](../docs/project/decisions/0009-methodology-adoption.yaml) (GCG-3)
> und [evidence-model.md](../docs/project/compliance/evidence-model.md).

## Inhalt (generiert, gitignored)

| Datei | Was | Erzeugt von |
|---|---|---|
| `app_extracted.json` | Kategorie-A-Felder aus echten App-Files | `extract_app_metadata.sh` |
| `compliance_input.json` | Merge A + B, von Conftest geprüft | `build_compliance_input.sh` |
| `evidence-log.jsonl` | Audit-Trail mit SHA-256-Chain, ein Eintrag pro Gate-Lauf | `run_gates.sh` |

Diese Dateien sind **transient** (gitignored) — bei jedem Lauf neu erzeugt.
Lokale Test-Läufe würden sonst Commit-Noise erzeugen.

## Hash-Chain

Jeder `evidence-log.jsonl`-Eintrag enthält:
- `prev_entry_hash` — SHA-256 des vorherigen Eintrags (oder "GENESIS")
- `entry_hash` — SHA-256 dieses Eintrags

Manipulation eines früheren Eintrags bricht die Kette → erkennbar.

## Lokal ausführen

```bash
bash scripts/compliance/run_gates.sh
```

## CI (geplant, TODO-022)

In `.github/workflows/compliance.yml` läuft `run_gates.sh`, das Ergebnis wird
als CI-Artefakt hochgeladen (nicht ins Repo committet).
