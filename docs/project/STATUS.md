# ScanFair Projektstatus

Stand: 23. September 2026
Phase: Phase 1, lokal validierter iOS-MVP  
Verbindliche Source of Truth: [`progress.yaml`](progress.yaml) und
[`backlog.yaml`](backlog.yaml)

Dieses Dokument hält den detaillierten, menschenlesbaren Projektstand fest.
Die Root-README bleibt bewusst eine öffentliche technische Fallstudie für
Recruiter sowie Fach- und Engineering-Verantwortliche.

## Status in einem Satz

Der vollständige lokale Scan-to-Detail-Flow funktioniert auf einem realen
iPhone. Das Compliance-Modell besitzt nun einen wirksamkeits- und
featuregesteuerten Horizon mit kanonischen Apple-Gates v2. Datenplattform,
Release- und Rechts-/Claim-Nachweise bleiben bis zu den vorgesehenen
qualifizierten Evidenzen fail-closed.

Der [Agent-Review vom 22.09.2026](audits/2026-09-22-agent-control-review.md)
hat drei PostgREST-Integrationsprobleme und zwei Cache-Frischefehler gefunden.
Die Backend-Probleme und zwei weitere HTTP-Befunde sind lokal repariert und
in [TKT-037-05 nachgewiesen](audits/2026-09-23-public-read-http-validation.md).
Der separate technische Review ist dokumentiert; PR-/Post-Merge-Evidenz fehlt noch.
Die zwei Cache-Frischefehler bleiben in TKT-038-01 offen. Lokale HTTP-Evidenz
ersetzt weder Hosted-Gateway-Pruefung noch Privacy-Freigabe.

## Validierte Baseline

| Bereich | Evidenzstand |
| --- | --- |
| Development Quality Gates | 33/33 PASS, 23. September 2026; keine Release-Freigabe |
| TODO-039 Kontrollpaket | 3/3 neue Horizon-Gates, 32 Gate-Definitionen (11 v2 kanonisch), Frist- und Quellen-Durchsetzung sowie zugehörige Selbsttests PASS, 4. September 2026 |
| Ticket-Arbeitsmodell | 7 Tickets; 31 Selbsttests mit 85 Assertions PASS; N/A-/Evidenz-/Datumsfehler korrigiert, PR-Body-Edit-Trigger ergaenzt; echter PR-/Post-Merge-Nachweis offen |
| Flutter | 122/122 Tests PASS, 84,33 % Line Coverage |
| Datenbank lokal | 15/15 Migrationen replayed, 303/303 pgTAP PASS, DB-Lint PASS; isolierter Neuaufbau am 23.09. |
| Datenbank remote | 13/13 freigegebene Migrationen abgeglichen, Schema-Diff leer, DB-Lint PASS |
| Retention Cleanup remote | Zwei geplante Läufe erfolgreich, keine offenen Cleanup-Zeilen |
| Retention Observability | Migration 13, vier echte Monitorläufe und kontrollierter Failure-/Recovery-Lifecycle remote belegt; externe Zustellung offen |
| Public-Read-Abuse-Schutz | 53/53 pgTAP, 292 HTTP-Assertions und erfolgreicher Edge-Writer-/Read-Rundlauf PASS; Migration 15 korrigiert Integration und Header-Spoofing. Remote unveraendert |
| iOS | Unsigned Simulator Compile und Privacy-Manifest-Audit PASS; physischer iPhone-Flow validiert |
| Supply Chain | 61 Dart-Pakete, 2 iOS-Plugins, 20 gepinnte Actions, 0 bekannte Schwachstellen |
| GitHub Actions | Pull Request 30 und Post-Merge-Läufe mit jeweils 6/6 Jobs PASS |

`PASS` bezeichnet hier das Development-Profil. Das Profil
`release_candidate`
bleibt erwartungsgemäß blockiert und darf nicht als App-Store-Freigabe
interpretiert werden.

## Große Meilensteine

Die Prozentwerte stammen aus dem bisherigen Planungsstand. Die neuen
Integrationsbefunde schraenken insbesondere M2 ein; die Werte sind keine
Restaufwands- oder Aktivierungszusage. Nach den Reparaturen neu bewerten.

```text
M1  Lokaler MVP und Integrationsbaseline [####################] 100%
M2  Backend- und Datenanbindung           [##################--]  90%
M3  Kaffee als Referenzfall               [#########-----------]  45%
M4  Umwelt-, Social- und Governance-Daten [###-----------------]  15%
M5  Kalibrierte Methodik 2.0              [###-----------------]  15%
M6  MVP-Beta und Product Hardening        [################----]  80%
M7  App-Store-Release-Candidate           [#########-----------]  45%
M8  TestFlight, Submission und Release    [--------------------]   0%
```

| Meilenstein | Erreicht | Noch bis 100 % |
| --- | --- | --- |
| M1 | iOS-Kernflow, Datenarchitektur, Quality Gates und validierte Integrationsbaseline | abgeschlossen |
| M2 | Trusted Writer, bounded RPCs, read-only Cache, RLS, Retention Cleanup, remote verifizierte Observability und lokal vollständig geprüfter Read-Abuse-Schutz | Privacy-freigegebene Remote-Anwendung von Migration 14, externe Notification-Drills und qualifizierte Provider-Reviews |
| M3 | Drei Kaffee-GTINs, Deklarationsnachweis und produktgebundene Rohstoff-/Herkunftslinks | Umwelt-, Social- und Governance-Faktoren, Score-Snapshot und fachliche Kalibrierung |
| M4 | Quellenregister und Kandidaten für Wasser, Social-Risiko und Rechtsträger | technische Anbindung und Mapping-, Lizenz-, Claim- und Qualitätsprüfung je Quelle |
| M5 | 26 Parameter, Safety Controls und ausgesetzte Aktivierungsregeln | Gewichte, Normalisierung, Testkorpus, Kalibrierung und Expertenreview |
| M6 | iPhone-Scanflow, Permission-Fallbacks, Dynamic Type, VoiceOver und Reduce Motion | dynamische Datenlokalisierung, Offline-/History-Entscheidung und Feldtest |
| M7 | Acht Apple-Gate-Gruppen im v2-Profil, MASVS-2.1-Baseline, iOS-Compile, Privacy-Bundle-Audit und Claim-/Privacy-Grenzen | offene Apple-, MASVS-, Rechts- und Fachreview-Evidenz sowie signiertes Release-Archive |
| M8 | bewusst nicht begonnen | TestFlight, App-Store-Submission und Releaseentscheidung |

## Nächste Arbeitspakete

```text
N0  Compliance-/Security-Baseline         [##################--]  90%
N1  Kaffee-Pilotprodukte                  [####################] 100%
N2  Produkt -> Rohstoff -> Herkunft       [####################] 100%
N3  EU-Supabase-Projekt                   [##############------]  70%
N4  Server-Writer und Flutter-Cache       [##################--]  90%
N5  WRI-Aqueduct-Wasserrisiko             [--------------------]   0%
N6  ILAB-Social-Risikomapping             [--------------------]   0%
N7  GLEIF/BRIS-Rechtsträgermapping        [--------------------]   0%
N8  Kalibrierung und Expertenreview       [--------------------]   0%
```

### Aktuelle Ausführungsreihenfolge

Vorrangiger technischer Pfad seit 22.09.: TKT-040-01 PR-/CI-Nachweis,
TKT-037-05 PostgREST-Reparatur, TKT-038-01 Cache-Frische, anschliessend
TKT-037-01 bis TKT-037-04. Die fachlichen Quellen-/Review-Aufgaben unten
bleiben offen. Docker muss fuer den echten lokalen API-/DB-Test laufen.

1. Die sechs im aktuellen Quellenbericht offenen Signale manuell bewerten und
   mit exakter Signatur als Requirement, ADR oder begründetes No-Impact
   protokollieren; bis dahin blockiert ein strenges Profil bewusst.
2. Qualifiziertes Rechtsreview für öffentliche Nachhaltigkeitsvergleiche vor
   deren Wirksamkeit abschließen.
3. Least-Privilege-Alarmkanal festlegen und Failure-/Recovery-Zustellung
   einschließlich Delivery-Failure-Drill nachweisen.
4. Privacy-Freigabe für die pseudonyme Rate-Limit-Telemetrie einholen,
   Migration 14 kontrolliert remote anwenden und den bestehenden Linked-Verifier
   erneut ausführen. Danach qualifizierte DPA-, Unterauftragsverarbeiter-,
   Lizenz- und Security-Reviews schließen.
5. WRI Aqueduct, ILAB sowie GLEIF/BRIS nacheinander als nicht score-aktive
   Quellen anbinden und deren Mapping-, Lizenz- und Claim-Verträge validieren.
6. Methodik 2.0 anhand des Kaffee-Referenzfalls kalibrieren und unabhängig
   fachlich reviewen lassen.
7. Erst danach einen Release Candidate mit vollständiger Apple-, MASVS-,
   Privacy-, Support- und Signed-Archive-Evidenz bewerten.

## Daten- und Runtime-Grenze

Das dedizierte Supabase-Development-Projekt `scanfair-dev` liegt in Frankfurt
(`eu-central-1`). Es enthält das kontrolliert ausgerollte Development-Schema
und öffentliche beziehungsweise synthetische Testdaten, aber keine
Personendaten. App-Zugriff, Writer Runtime, Accounts, Produktionsbetrieb und
externe Alarmzustellung sind deaktiviert.

Der Flutter-Client verwendet standardmäßig Open Food Facts direkt. Ein
read-only Cache-Adapter ist implementiert und testbar, wird jedoch erst nach
den vorgesehenen Aktivierungsnachweisen freigegeben. Mobile Clients erhalten
keine privilegierten Writer- oder Service-Role-Schlüssel.

## Release-Grenze

Aktuell ausdrücklich ausgeschlossen:

- automatisches Deployment oder Hosting
- TestFlight-Upload
- App-Store-Submission oder öffentlicher Release
- Produktionsruntime und Verarbeitung von Personendaten
- Android-Release
- Kubernetes und OPA Gatekeeper

Die Development-Pipeline darf grün sein, während strengere Profile rot
bleiben. Dieses Verhalten ist beabsichtigt: Es ermöglicht lokale Entwicklung,
ohne fehlende Release-Evidenz stillschweigend als erfüllt zu behandeln.

## Pflege

Bei einer Statusänderung werden zuerst die maschinenlesbaren SSOT-Dateien
aktualisiert. Dieses Dokument wird anschließend aus ihnen nachgezogen. Historie
und einzelne Nachweise liegen in:

- [`progress.yaml`](progress.yaml): chronologischer Fortschritt und letzte Validierung
- [`backlog.yaml`](backlog.yaml): offene Arbeit, Prioritäten und Akzeptanzkriterien
- [`audits/`](audits/README.md): datierte Assessments und Remote-Nachweise
- [`decisions/`](decisions/INDEX.md): Architecture Decision Records
- [`quality-strategy.md`](quality-strategy.md): vollständiger Gate- und Testprozess
