# Risikobasierter Kontroll- und Agent-Review

Dieser Workflow konkretisiert den bestehenden PR-Review, die DoR/DoD und
`G-PROJECT-CONTROL`. Er wird im Ticket geplant und unter `docs/project/audits`
dokumentiert. Die Gate-Anzahl wird dadurch nicht erhoeht.

## Ausloeser

- Aenderungen an Gates, Validatoren, CI-Ausloesern oder Freigabe-Evidenz.
- Aenderungen an RLS, privilegierten Rollen, Migrationen, Datenschutz-Datenfluss
  oder Writer-/Read-API vor deren Aktivierung.
- Aenderungen an Methodik, Produktzuordnung, Claims oder Datenfrischegrenzen.
- Vor Remote-Aktivierung und vor einem Release Candidate als zusammenhaengender
  Review des relevanten Datenpfads.

Ein kleiner Doku-Patch braucht keinen Vollreview. Scope, Zielprofil und
betroffene Kontrollen stehen vor Beginn im Ticket. Fuer ausgelagerte Reviews
koennen separate Agents mit eng begrenztem Leseauftrag eingesetzt werden;
bei fehlender Delegationsmoeglichkeit erfolgt ein separater Review-Durchgang.

## Ablauf im vorhandenen Arbeitsmodell

1. Ticket und DoR pruefen; HEAD, Working-Tree-Aenderungen und relevante
   Vertrags-/Codeversionen erfassen. Vorhandene Tests als Baseline ausfuehren.
2. Reviewauftraege nach Risiko aufteilen: Kontroll-/CI-Durchsetzung,
   Datenbank-/Security-Grenzen, Client-/Datenqualitaet. Reviewer liefern
   Befunde mit Prioritaet, Datei/Zeile, Auswirkung und Reproduktionsschritt.
3. Positive und negative Pfade gegen die reale Ausfuehrungsschicht pruefen:
   zum Beispiel HTTP plus Request-Rolle und Transaktionsmodus statt nur
   direktem SQL-Aufruf als postgres. Bei Kontrollen zusaetzlich fehlende,
   abgelaufene, manipulierte oder unpassende Evidenz pruefen.
4. Hauptagent oder Engineering-Owner bestaetigt jeden Befund und trennt
   Reproduktion, statischen Nachweis und Hypothese. Doppelte Meldungen
   zusammenfuehren; widersprechende Bewertungen anhand von Belegen aufloesen.
5. Korrekturen im aktiven Ticket nur innerhalb seines Scopes umsetzen.
   Sonstige konkrete Reparaturen als Child-Tickets mit DoR/AC/DoD anlegen;
   bekannte Aktivierungsblocker in Abhaengigkeiten und Status spiegeln.
6. Fuer jeden bestaetigten Defekt einen passenden Regressionstest hinzufuegen,
   der die fehlerhafte Fassung erkennt. Fix und relevante Gates ausfuehren;
   ein Reviewer prueft die Behebung erneut. Unabhaengige Tickets bleiben
   getrennt; maximal ein Ticket ist aktiv.
7. Audit, Ticket, Backlog und Fortschritt synchronisieren. PR- und Post-Merge-
   Evidenz ergaenzen; offene profilrelevante P0/P1-Befunde verhindern eine
   Aktivierungsfreigabe. Ein erwartetes FAIL wird mit Ursache dokumentiert.

## Belege und Grenzen

Der Auditbericht enthaelt Datum, Basisrevision inklusive Dirty-State,
Reviewer-Scope, Befund-ID, Prioritaet, Beleg, Reproduktion, Reparaturticket,
Status und ausgefuehrte bzw. nicht ausgefuehrte Tests. Die PR-Verifikation
verlinkt den Bericht oder begruendet anhand des Scopes, weshalb der Trigger
nicht zutrifft.

Agents erkennen moegliche Luecken und koennen Regressionstests entwerfen.
Mehrere Agents desselben Modells sind keine unabhaengige externe Zertifizierung
und koennen dieselben Fehler uebersehen. Ein Reviewtext allein setzt kein
Gate auf PASS. CI prueft die deterministischen Regeln und Tests; technische
und menschliche Freigabe-Evidenz bleibt an ihre vorhandenen Vertraege gebunden.
Es wird kein automatischer LLM-Score als neuer Merge- oder Rechtsentscheider
eingefuehrt. Dokumentierte Reviewpflicht und maschinell erzwungene Kontrolle
werden im Bericht getrennt ausgewiesen.

Verweis: erster Durchlauf
[2026-09-22](../audits/2026-09-22-agent-control-review.md), TKT-040-01.
