# ScanFair Delivery Operating Model

Status: verbindlicher Arbeitsrahmen
Version: 1.0
Stand: 2026-07-28
Owner: Mustafa Demir

## 1. Ziel

Dieses Operating Model beschreibt, wie ScanFair von einer Produktidee zu einem
nachvollziehbaren, sicheren und spaeter releasefaehigen iOS-Produkt entwickelt
wird. Es verbindet Product Ownership, Software Engineering, Data Governance,
Compliance Engineering, DevSecOps und Release Governance.

Kein Prozess und kein Quality Gate kann eine Annahme durch Apple oder
rechtliche Mangelfreiheit garantieren. Das Ziel ist, vermeidbare Fehler zu
reduzieren, Entscheidungen nachvollziehbar zu machen und fuer jede Freigabe
belastbare Evidenz vorzuhalten.

## 2. Arbeitsprinzipien

1. **Product value first:** Jede Aenderung braucht ein fachliches Ziel und
   pruefbare Akzeptanzkriterien.
2. **Evidence first:** Score-relevante Daten brauchen Quelle, Datensatz,
   Zeitpunkt, Lizenz, Confidence und eine belastbare Beziehung zum Produkt.
3. **Risk based:** Kontrollen richten sich nach Auswirkung und Risiko, nicht
   nach einer moeglichst hohen Anzahl an Gates.
4. **Vertical slices:** Neue Faehigkeiten werden Ende-zu-Ende an einem
   Referenzfall entwickelt.
5. **Fail closed at release:** Offene anwendbare MUST-Nachweise blockieren
   `release_candidate` und `submission`.
6. **Visible uncertainty:** Fehlende oder unsichere Daten werden angezeigt und
   nicht positiv, neutral oder mit null ersetzt.
7. **Human accountability:** Produkt-, Methodik-, Claim- und
   Releaseentscheidungen bleiben menschlich verantwortet.
8. **Small reversible changes:** Branches und Pull Requests bleiben
   thematisch fokussiert und rollback-faehig.

## 3. Vier Ebenen

### Ebene 1: Prozess und Governance

Zweck: Sicherstellen, dass Aenderungen kontrolliert entschieden, entwickelt,
geprueft und integriert werden.

Artefakte und Kontrollen:

- Roadmap, Backlog, ADRs und Akzeptanzkriterien
- Lifecycle-Gap-Analyse mit Reifegrad, Owner, Zielprofil und Closure-Evidenz
- Feature- oder Prozessbranch statt direkter Arbeit auf `main`
- Pull Request mit Risiko-, Evidenz- und Rollbackangaben
- verpflichtende Statuschecks vor dem Merge
- geschuetzter `main`-Branch
- dokumentierte Freigabe- und Ausnahmeentscheidungen

Exit-Kriterium: Aenderung ist fachlich eingeordnet, lokal geprueft, im Pull
Request nachvollziehbar und durch die erforderlichen CI-Checks freigegeben.

### Ebene 2: Compliance, Security und Data Governance

Zweck: Sicherstellen, dass technische, regulatorische, lizenzrechtliche und
methodische Grenzen vor der Aktivierung einer Faehigkeit geprueft sind.

Artefakte und Kontrollen:

- Apple-Requirements, acht Apple-Gate-Gruppen und Enforcement-Profile
- Privacy Manifest, Dateninventar und Third-Party-SDK-Review
- RLS, Secret Scan, Dependency Scan und Mobile-Security-Baseline
- Quellenregister, Lizenzpruefung und Attribution
- Methodikversion, Claim-Regeln, Confidence und Evidence Lineage
- manuelle Fach- oder Rechtsfreigabe, wo Automation keine Aussage treffen kann

Exit-Kriterium: Alle fuer die Zielstufe faelligen MUST-Kriterien sind erfuellt;
SHOULD-Abweichungen sind sichtbar, begruendet, terminiert und einem Owner
zugeordnet.

### Ebene 3: Produkt und Entwicklung

Zweck: Eine fachlich nuetzliche Faehigkeit als getesteten vertikalen Schnitt
liefern.

Artefakte und Kontrollen:

- Produktanforderung und UX-Ziel
- Flutter-/iOS-Code, Datenmodelle und Fehlerzustaende
- Unit-, Widget-, Policy-, Datenbank- und Build-Tests
- Quellen- und Methodikabbildung
- Ergebnis-, Detail- und Unsicherheitsdarstellung
- physischer Device-Smoke-Test bei nativen Aenderungen

Exit-Kriterium: Der vertikale Nutzerflow funktioniert, ist erklaerbar und
erfuellt seine fachlichen, technischen und Compliance-Akzeptanzkriterien.

### Ebene 4: Betrieb, Release und Lernen

Zweck: Sicherstellen, dass das Produkt nach der technischen Fertigstellung
kontrolliert getestet, betrieben, beobachtet und zurueckgerollt werden kann.

Artefakte und Kontrollen:

- getrennte Development-, Staging- und Production-Umgebungen
- Backup-, Restore-, Migration- und Rollbacktests
- datenschutzfreundliches Crash-, API- und Datenfrische-Monitoring
- Incident-, Support- und Datenkorrekturprozess
- TestFlight-Feedback und reale Device-/Netzwerktests
- versionierte App-Store-Metadaten und Release Evidence

Exit-Kriterium: Ein reproduzierbarer Release Candidate ist technisch,
fachlich und operativ freigegeben; Betrieb und Rueckfallweg sind nachgewiesen.

## 4. Standard-Workflow pro Aenderung

1. Ziel, betroffene Ebene und Risiko festlegen.
2. Requirement, Issue oder ADR referenzieren oder erstellen.
3. Betroffene Gap-Domaenen und Capability-Trigger klassifizieren.
4. Akzeptanzkriterien und erforderliche Evidenz definieren.
5. Fokussierten Branch von aktuellem `main` erstellen.
6. Kleinsten vertikalen oder prozessualen Schnitt implementieren.
7. Relevante lokale Tests und Gates ausfuehren.
8. Pull Request mit Risiko, Evidenz, offenen Punkten und Rollback erstellen.
9. Verpflichtende GitHub-Checks abwarten.
10. Nur bei gruener Entscheidung nach `main` mergen.
11. Post-Merge-CI pruefen und Fortschritt sowie Dokumentation aktualisieren.

Direkte Pushes auf `main`, unversionierte Produktionsaenderungen und
undokumentierte Gate-Ausnahmen sind nicht Teil des Standardprozesses.

## 5. Definition of Ready

Eine Aenderung ist bereit fuer die Umsetzung, wenn:

- Ziel und Nutzer- oder Kontrollnutzen klar sind.
- Scope und Nicht-Scope benannt sind.
- Akzeptanzkriterien pruefbar formuliert sind.
- Datenquellen, Claims, Datenschutz und Lizenzen bewertet wurden, sofern
  betroffen.
- erwartete Tests und Gates feststehen.
- P0-/P1-Luecken, Claim-, Lizenz-, Privacy- und Capability-Trigger bewertet sind.
- Owner fuer fachliche Entscheidung und technische Umsetzung bekannt sind.

## 6. Definition of Done

Eine Aenderung ist fertig, wenn:

- Akzeptanzkriterien nachweisbar erfuellt sind.
- Code, Konfiguration und Dokumentation konsistent sind.
- relevante lokale Tests und GitHub-Checks bestanden wurden.
- keine Secrets oder unbeabsichtigten Artefakte committed wurden.
- Daten-, Methodik- und Claim-Lineage bei Score-Aenderungen erhalten bleibt.
- Risiken, bekannte Grenzen und spaetere Arbeiten dokumentiert sind.
- Rollback oder sichere Deaktivierung beschrieben ist.
- der Post-Merge-Stand auf `main` gruen ist.

## 7. Gate-Aufnahmeregel

Ein neues Gate wird nur aufgenommen, wenn:

- ein konkretes Produkt-, Security-, Compliance-, Daten- oder Release-Risiko
  existiert;
- ein eindeutiger Trigger und eine reproduzierbare Entscheidung definiert sind;
- benoetigte Artefakte und Evidenz benannt sind;
- ein Owner und eine Behebungsaktion existieren;
- Automation nicht mehr Sicherheit behauptet, als die Evidenz erlaubt;
- Ausnahme, Ablaufdatum und erneute Pruefung dokumentierbar sind.

Nicht deterministische Rechts-, Claim-, UX- oder Methodikentscheidungen bleiben
HYBRID und brauchen menschliche Freigabe. Gate-Anzahl ist keine
Qualitaetsmetrik.

## 8. Rollen und Entscheidungsrechte

| Rolle | Verantwortung |
| --- | --- |
| Mustafa / Product Owner | Vision, Scope, Prioritaet, Risikoakzeptanz, Methodikaktivierung und Releaseentscheidung |
| Codex / Engineering Partner | Repo-Analyse, Implementierung, Tests, technische Dokumentation und transparente Risikomeldung |
| Externe Fachpruefung | ESG-Methodik, Umwelt-/Gesundheitsaussagen, Datenschutz und Rechtsfragen |
| GitHub Actions | Reproduzierbare technische und Policy-as-Code-Evidenz |
| Apple App Review | Unabhaengige finale Plattformentscheidung |

Codex darf reversible technische Details innerhalb bestehender ADRs
selbststaendig entscheiden. Neue Produktclaims, regulatorische Interpretation,
Methodikaktivierung und externe Releases brauchen eine explizite menschliche
Entscheidung.

## 9. Release-Profile

| Profil | Zweck | Verhalten |
| --- | --- | --- |
| `development` | schnelle, sichere Iteration | objektive Fehler blockieren; spaetere Release-Evidenz bleibt als Warnung sichtbar |
| `release_candidate` | strenge lokale Releaseprobe | jede anwendbare offene MUST-Anforderung blockiert |
| `submission` | finale Freigabeprobe | zusaetzlich finale signierte und manuelle Evidence erforderlich |

Eine gruene Development-Pipeline ist kein App-Store-Go-live.

## 10. Aktuelle Umsetzungsreihenfolge

1. Prozessebene staerken: Operating Model, PR-Qualitaet, CI-Effizienz und
   Branchschutz.
2. Compliance-Ebene staerken: Dependency-/Supply-Chain-Scan,
   OWASP-MASVS-Baseline und offene Apple-/Claim-Evidenz.
3. Kaffee als evidence-first Referenzfall entwickeln.
4. Nach stabilen Relationship- und Evidenzvertraegen M2 parallelisieren:
   EU-Supabase, Server-Writer und read-only Flutter-Cache.
5. Betriebs- und Releaseebene vor TestFlight schliessen.

Compliance und Entwicklung laufen ab Schritt 3 pro vertikalem Schnitt
gemeinsam. Security, Datenschutz, Lizenzen und Claims werden nicht als
nachtraegliche Endkontrolle behandelt.
