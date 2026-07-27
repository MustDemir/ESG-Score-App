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
| `latest-gate-results.json` | Letzte Gesamt- und Einzelentscheidungen | `run_gates.sh` |
| `ios_privacy_audit.json` | Privacy Manifests aus dem gebauten `Runner.app` | `audit_ios_privacy_bundle.sh` |

Diese Dateien sind **transient** (gitignored) — bei jedem Lauf neu erzeugt.
Lokale Test-Läufe würden sonst Commit-Noise erzeugen.

## Hash-Chain

Jeder Version-2-Eintrag enthaelt Profil, Einzelentscheidungen der acht Apple-Gates,
Input-Hash, Commit, Ref, Workflow-Run, Actor und Dirty-Status sowie:
- `prev_entry_hash` - SHA-256 des vorherigen Eintrags (oder "GENESIS")
- `entry_hash` - SHA-256 dieses Eintrags

`verify_evidence_chain.sh` berechnet jeden Hash und Link neu. Die lokale Datei
ist damit manipulations**erkennbar**, aber kein unveraenderlicher externer Store.

## Lokal ausführen

```bash
bash scripts/compliance/run_gates.sh
bash scripts/compliance/verify_evidence_chain.sh
COMPLIANCE_PROFILE=release_candidate bash scripts/compliance/run_gates.sh
```

## CI

`.github/workflows/quality-gates.yml` fuehrt den Runner aus, zeigt alle acht
Entscheidungen in der GitHub-Zusammenfassung und laedt Input, Einzelresultate,
Hash-Chain und Quality-Logs als CI-Artefakt hoch.
