# Ticket Workflow Control Validation

- Validiert: 2026-09-11
- Scope: repo-native Tickets, DoR/DoD, Abhaengigkeiten, Gate-Zuordnung und Pull-Request-Bindung
- Zielprofil: development
- Remote- oder Produktivmutation: keine

## Ausgangslage

ScanFair besass bereits `backlog.yaml`, `progress.yaml`, eine zentrale
Definition of Ready/Done, Risiko- und Gap-Register, ADRs sowie
`G-PROJECT-CONTROL`. Kleine ausfuehrbare Aktionen standen jedoch teilweise nur
als Freitext in einem groesseren TODO. Der bestehende Projekt-Validator pruefte
keine eigene Aktions-ID, keine DoR-/DoD-Zustandslogik und keine Bindung eines
Pull Requests an die konkrete Arbeitseinheit.

## Integrierte Kontrolle

ADR 0041 ergaenzt Child-Tickets unterhalb der vorhandenen TODOs. Das Backlog
bleibt Prioritaets-SSOT, das Ticket wird Ausfuehrungs-SSOT und `progress.yaml`
bleibt Nachweis-SSOT. Jedes Ticket enthaelt Scope und Nicht-Scope, Parent-TODO,
DoD-Tasktypen, Risiken, ADRs, DoR, pruefbare Akzeptanzkriterien, DoD,
Abhaengigkeiten, Gates, Evidenz, Rollback und Aktivierungsgrenze.

`G-PROJECT-CONTROL` prueft lokal und in GitHub Actions:

- Schema, Dateiname, eindeutige Ticket-ID und Pflichtfelder
- existierende Parent-TODOs, Risiken, ADRs und DoD-Tasktypen
- konsistente DoR-, Akzeptanz-, DoD- und Lifecycle-Zustaende
- existierende Evidenzpfade fuer erfuellte Kriterien
- Abhaengigkeiten, Zyklen, Indexreihenfolge und maximal ein aktives Ticket
- typgerechte Gate-Zuordnung
- bei Pull Requests genau eine reviewfaehige Ticket-ID und das passende Parent-TODO

## Validierung

| Kontrolle | Ergebnis |
|---|---:|
| Ticket-Schema- und Zustands-Selbsttests | 11 Tests, 23 Assertions PASS |
| PR-Ticket-Binding-Selbsttests | 8 Tests, 15 Assertions PASS |
| Reale Ticketdateien | 5/5 schema- und workflowkonsistent |
| Projektkontrolle | 17 Improvements, 15 Gaps, 5 Tickets, 3 Feature-States PASS |
| Gate-Definitionen | 32/32 PASS |
| Projekt-YAML | 148 Dateien syntaktisch gueltig |
| Vollstaendige Development-Pipeline | 33/33 Gates PASS |

Die Negativtests manipulieren Pflichtfelder, Readiness, DoD-Typen, Gates,
Evidenzpfade, Parent-Rueckverweise, Abhaengigkeiten, Zyklen, Abschlussstatus,
Indexabdeckung sowie PR-Ticket-/Parent-Bindung. Alle Manipulationen werden
blockiert.

## Verbleibende Grenze

Die lokale und statische CI-Konfiguration ist nachgewiesen. Ein echter Pull
Request muss die neue Event-Bindung noch auf GitHub ausfuehren; nach dem Merge
ist der Post-Merge-Stand erneut zu pruefen. Automatische Kontrollen ersetzen
keine menschliche Privacy-, Rechts-, Fach- oder Releaseentscheidung und
behaupten nicht, dass ein erfuelltes Formular allein die technische Wirkung
beweist.

## Relevante Artefakte

- `docs/project/tickets/ticket-schema.yaml`
- `docs/project/tickets/ticket-index.yaml`
- `scripts/quality/validate_tickets.rb`
- `scripts/quality/test_ticket_gate.rb`
- `scripts/quality/validate_pr_ticket_binding.rb`
- `scripts/quality/test_pr_ticket_binding.rb`
- `.github/workflows/quality-gates.yml`
- `docs/project/decisions/0041-ticket-based-execution-control.yaml`
