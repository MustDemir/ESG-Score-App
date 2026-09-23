# Ausfuehrbare Tickets

Die Tickets ergaenzen das bestehende ScanFair-Arbeitsmodell. Sie ersetzen
weder `backlog.yaml` noch `progress.yaml`: Das Backlog beschreibt das
Arbeitspaket, ein Ticket beschreibt genau eine ausfuehrbare Aktion darunter,
und `progress.yaml` dokumentiert den nachgewiesenen Stand.

Vor jeder Aenderung an Code, Konfiguration, Datenbank, Compliance- oder
Betriebsstatus wird ein Ticket angelegt. Reine Statusabfragen und lesende
Diagnosen benoetigen kein eigenes Ticket. Einzelne Testkommandos sind keine
separaten Tickets, sondern Verifikationsschritte des zugehoerigen Tickets.

## Ablauf

1. Backlog-TODO und Risiko bestimmen.
2. Ticket aus `_ticket-template.yaml` erstellen und im `ticket-index.yaml`
   einordnen.
3. Definition of Ready vervollstaendigen und `G-PROJECT-CONTROL` ausfuehren.
4. Erst bei `ready` den Status auf `in_progress` setzen.
5. Akzeptanzkriterien implementieren und jeweils mit Evidenz belegen.
6. Relevante Gates und Tests ausfuehren.
7. Risikobasierten [Kontrollreview](../workflows/control-assurance-review.md)
   ausfuehren und Definition of Done pruefen; nach Implementierung `review`,
   erst nach allen Nachweisen einschliesslich Post-Merge-CI `done`.
8. Ticket-ID in Branch, Commit oder Pull Request sowie in der
   Fortschrittsdokumentation referenzieren.

`G-PROJECT-CONTROL` prueft Schema, Pflichtfelder, DoR-/DoD-Logik,
Abhaengigkeiten, Backlog-Rueckverweise, Ticket-Reihenfolge, Gate-Zuordnung und
Evidenzanforderungen. Es bestaetigt keine menschliche Rechts- oder
Privacy-Freigabe.

Bei Pull Requests prueft die CI zusaetzlich, ob der PR genau eine existierende
Ticket-ID und das dazugehoerige Parent-TODO nennt. Auch Body-Aenderungen
loesen die Pruefung erneut aus. Das prueft die Referenz, nicht automatisch
die fachliche Passung jeder geaenderten Codezeile zum Ticket-Scope.

`not_applicable` verlangt `not_applicable_reason`, `decision_owner` und
Evidenz. Mit `not_applicable_allowed: false` werden Pflichtkriterien wie der
menschliche Privacy-Review von solchen Ausnahmen ausgeschlossen. Die
Dateipruefung bestaetigt keine menschliche Unterschrift oder Rechtsfreigabe.
