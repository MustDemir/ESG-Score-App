# ScanFair Projektstatus

Stand: 31. August 2026  
Phase: Phase 1, lokal validierter iOS-MVP  
Verbindliche Source of Truth: [`progress.yaml`](progress.yaml) und
[`backlog.yaml`](backlog.yaml)

Dieses Dokument hält den detaillierten, menschenlesbaren Projektstand fest.
Die Root-README bleibt bewusst eine öffentliche technische Fallstudie für
Recruiter sowie Fach- und Engineering-Verantwortliche.

## Status in einem Satz

Der vollständige lokale Scan-to-Detail-Flow funktioniert auf einem realen
iPhone und besteht die Development-Quality-Gates. Datenplattform,
Compliance-Modell und Retention Controls sind weit entwickelt, bleiben aber
bis zu den vorgesehenen Fach-, Rechts-, Security- und Release-Nachweisen
fail-closed.

## Validierte Baseline

| Bereich | Evidenzstand |
| --- | --- |
| Development Quality Gates | 30/30 PASS, 31. August 2026 |
| Flutter | 122/122 Tests PASS, 84,33 % Line Coverage |
| Datenbank lokal | 13/13 Migrationen replayed, 250/250 pgTAP PASS, DB-Lint PASS |
| Datenbank remote | 12/12 freigegebene Migrationen abgeglichen, Schema-Diff leer, DB-Lint PASS |
| Retention Cleanup remote | Zwei geplante Läufe erfolgreich, keine offenen Cleanup-Zeilen |
| Retention Observability | Lokal PASS; Migration 13, echter Monitorlauf und Notification Drill remote offen |
| iOS | Unsigned Simulator Compile und Privacy-Manifest-Audit PASS; physischer iPhone-Flow validiert |
| Supply Chain | 61 Dart-Pakete, 2 iOS-Plugins, 20 gepinnte Actions, 0 bekannte Schwachstellen |
| GitHub Actions | Pull Request 30 und Post-Merge-Läufe mit jeweils 6/6 Jobs PASS |

`PASS` bezeichnet hier das Development-Profil. Das Profil
`release_candidate`
bleibt erwartungsgemäß blockiert und darf nicht als App-Store-Freigabe
interpretiert werden.

## Große Meilensteine

Die Prozentwerte messen den nachweisbaren Abschluss gegen die jeweiligen
Akzeptanzkriterien. Sie werden in Fünf-Prozent-Schritten fortgeschrieben.

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
| M2 | Trusted Writer, bounded RPCs, read-only Cache, RLS, Retention Cleanup und lokale Observability | Migration 13 remote, Monitorlauf, Notification Drill, Read-Abuse-Schutz und qualifizierte Provider-Reviews |
| M3 | Drei Kaffee-GTINs, Deklarationsnachweis und produktgebundene Rohstoff-/Herkunftslinks | Umwelt-, Social- und Governance-Faktoren, Score-Snapshot und fachliche Kalibrierung |
| M4 | Quellenregister und Kandidaten für Wasser, Social-Risiko und Rechtsträger | technische Anbindung und Mapping-, Lizenz-, Claim- und Qualitätsprüfung je Quelle |
| M5 | 26 Parameter, Safety Controls und ausgesetzte Aktivierungsregeln | Gewichte, Normalisierung, Testkorpus, Kalibrierung und Expertenreview |
| M6 | iPhone-Scanflow, Permission-Fallbacks, Dynamic Type, VoiceOver und Reduce Motion | dynamische Datenlokalisierung, Offline-/History-Entscheidung und Feldtest |
| M7 | Acht Apple-Gate-Gruppen, MASVS-2.1-Baseline, iOS-Compile, Privacy-Bundle-Audit und Claim-/Privacy-Grenzen | offene Apple-, MASVS-, Rechts- und Fachreview-Evidenz sowie signiertes Release-Archive |
| M8 | bewusst nicht begonnen | TestFlight, App-Store-Submission und Releaseentscheidung |

## Nächste Arbeitspakete

```text
N0  Compliance-/Security-Baseline         [#################---]  85%
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

1. `TODO-039`: Compliance Horizon 2026 mit aktuellen offiziellen Quellen,
   regulatorischer Anwendbarkeit und aktualisierten Apple-Kontrollen umsetzen.
2. Retention-Observability-Migration remote kontrolliert anwenden, echten
   Monitorlauf beobachten und Failure-/Recovery-Zustellung nachweisen.
3. Read-Abuse-Schutz und qualifizierte DPA-, Unterauftragsverarbeiter-,
   Lizenz-, Privacy- und Security-Reviews schließen.
4. WRI Aqueduct, ILAB sowie GLEIF/BRIS nacheinander als nicht score-aktive
   Quellen anbinden und deren Mapping-, Lizenz- und Claim-Verträge validieren.
5. Methodik 2.0 anhand des Kaffee-Referenzfalls kalibrieren und unabhängig
   fachlich reviewen lassen.
6. Erst danach einen Release Candidate mit vollständiger Apple-, MASVS-,
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
