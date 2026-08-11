# ScanFair Lifecycle Gap Analysis

Status: verbindliche Analysemethode
Version: 1.0
Stand: 2026-08-10
Owner: Mustafa Demir

## 1. Zweck

Die ScanFair Lifecycle Gap Analysis (SLGA) findet systematisch Fähigkeiten,
Pflichten, Risiken und Nachweise, die im aktuellen Vorgehen fehlen, nur
teilweise umgesetzt oder noch nicht operationalisiert sind. Sie verhindert,
dass ein grüner Entwicklungsstand mit fachlicher, rechtlicher oder operativer
Release-Reife verwechselt wird.

Die Methode kombiniert:

- Requirements- und Evidence-Traceability
- Capability-Maturity-Assessment
- FMEA-orientierte Risiko- und Fehlerfolgenanalyse
- Security Threat Modeling und Privacy Data-Flow Review
- Non-Functional-Requirements- und Quality-Attribute-Review
- Release-Premortem und Operations-Readiness
- Compliance Horizon Scanning gegen aktuelle Primärquellen

Die Methode ist eine technische und organisatorische Risikoanalyse, keine
Rechtsberatung. Rechts-, ESG-, LCA-, Menschenrechts- und Health-Claims müssen
vor öffentlicher Aktivierung durch qualifizierte Personen geprüft werden.

## 2. Sources of Truth

| Artefakt | Funktion |
| --- | --- |
| `methodology/product-engineering-handbook.md` | vollständige Disziplinen- und Lifecycle-Landkarte |
| `gap-register.yaml` | aktueller, maschinenprüfbarer Gap-Bestand |
| `improvement-register.yaml` | Umsetzung und Closure der priorisierten Gaps |
| `risks.yaml` | Produktrisiko, Eintrittswahrscheinlichkeit und Mitigation |
| `backlog.yaml` | konkrete Arbeitspakete und Trigger |
| `compliance/source-register.yaml` | Primärquellen, Versionen und Review-Datum |
| `audits/` | unveränderlicher Befund zum jeweiligen Prüfzeitpunkt |
| `progress.yaml` | belegter Projektfortschritt und Session-Handoff |

Ein Auditbericht dokumentiert den Befund. Der Status wird danach nicht im
Auditbericht überschrieben, sondern im Gap- und Verbesserungsregister gepflegt.

## 3. Zwölf Prüffelder

| ID | Prüffeld | Kernfrage |
| --- | --- | --- |
| D01 | Product und Nutzerwert | Löst das Inkrement ein validiertes Problem ohne Dark Patterns oder Scheinnutzen? |
| D02 | UX, Accessibility und Lokalisierung | Können alle gemeinsamen Aufgaben verständlich, sprachsicher und barrierearm erledigt werden? |
| D03 | Mobile und iOS | Sind Lifecycle, Permissions, Build, Signing, Plattformverhalten und Gerätefälle beherrscht? |
| D04 | ESG-Methodik und wissenschaftliche Validität | Sind Parameter, Normalisierung, Gewichte, Unsicherheit und Kalibrierung belastbar? |
| D05 | Daten und Lizenzen | Sind Quelle, Produktbezug, Provenienz, Qualität, Frische, Lizenz und Korrekturweg geklärt? |
| D06 | Claims und Verbraucherrecht | Ist jede Umwelt-, Nachhaltigkeits-, Social-, Governance- und Health-Aussage belegbar und zulässig? |
| D07 | Privacy und Datenschutz | Sind Datenfluss, Rechtsgrundlage, Minimierung, Löschung, Betroffenenrechte und Drittparteien kontrolliert? |
| D08 | Security und Supply Chain | Sind Bedrohungen, Trust Boundaries, Abhängigkeiten, Secrets, Missbrauch und Manipulation kontrolliert? |
| D09 | Testing und Quality Engineering | Decken Tests Regeln, Grenzen, Fehler, Verträge, Builds, Geräte und Regressionen risikogerecht ab? |
| D10 | DevOps und Delivery Governance | Sind Branch, PR, CI, Evidenz, Rollback und Integration reproduzierbar? |
| D11 | Betrieb, Support und Resilience | Sind Monitoring, SLO, Incident, Backup, Restore, Datenkorrektur und Provider-Ausfall vorbereitet? |
| D12 | Release, Recht und Organisationsfähigkeit | Sind Store-Metadaten, Archive, Freigaben, Verantwortlichkeiten und Business Continuity belastbar? |

## 4. Acht Lifecycle-Phasen

Jedes Prüffeld wird gegen jede Phase betrachtet. Dadurch werden besonders die
Lücken sichtbar, die zwischen Entwicklung und Betrieb liegen.

| Phase | Leitfrage |
| --- | --- |
| L1 Discover | Haben wir Nutzerproblem, Stakeholder, Schaden und Annahmen verstanden? |
| L2 Define | Sind Requirement, Nicht-Scope, Risiko, Quelle und Akzeptanzkriterium definiert? |
| L3 Design | Gibt es Architektur, Datenvertrag, Threat Model, UX und Kontrollentscheidung? |
| L4 Build | Ist die Fähigkeit mit sicheren Defaults und Fehlerzuständen implementiert? |
| L5 Verify | Ist sie automatisch, manuell und gegebenenfalls fachlich geprüft? |
| L6 Integrate | Ist sie über Branch, PR, CI, Review und Evidenz kontrolliert integriert? |
| L7 Release | Sind Release-Profil, Archive, Metadaten, Recht und Freigabe geschlossen? |
| L8 Operate | Sind Monitoring, Support, Korrektur, Incident, Änderung und Abschaltung möglich? |

## 5. Reifegrad

| Stufe | Bedeutung | Zulässige Aussage |
| ---: | --- | --- |
| 0 | nicht betrachtet | keine |
| 1 | erkannt | Gap und Owner sind benannt |
| 2 | entworfen | Requirement, Akzeptanzkriterien und Zielkontrolle existieren |
| 3 | implementiert | Code, Prozess oder Artefakt ist vorhanden |
| 4 | validiert | relevante Tests, Reviews und Evidenz sind grün |
| 5 | operationalisiert | Kontrolle funktioniert wiederholt unter realen Betriebs-/Releasebedingungen |

Mindestwerte:

- `development`: risikorelevante Entwicklungsfähigkeit mindestens Stufe 3;
  objektiv prüfbare MUST-Kriterien mindestens Stufe 4.
- `release_candidate`: alle anwendbaren MUST-Kriterien mindestens Stufe 4.
- `submission`: Release-, Support-, Privacy- und Betriebsfähigkeit mindestens
  Stufe 4; wiederkehrende Betriebskontrollen mit geplantem Owner und Cadence.
- nach Go-live: kritische Betriebs-, Incident- und Restore-Fähigkeiten Stufe 5.

## 6. Gap-Typen

| Typ | Bedeutung |
| --- | --- |
| `absent` | Fähigkeit oder Kontrolle fehlt vollständig |
| `partial` | wesentliche Teile existieren, aber Coverage oder Evidenz ist unvollständig |
| `documented_not_operational` | beschrieben, aber noch nicht real ausgeführt oder getestet |
| `stale` | vorhandene Entscheidung oder Quelle ist nicht mehr aktuell genug |
| `trigger_based` | aktuell nicht anwendbar; wird durch eine neue Capability verpflichtend |

## 7. Sieben Prüfdurchgänge

### Pass 1: Inventar und Traceability

Requirements, ADRs, Code, Tests, Datenquellen, Gates, manuelle Evidenz,
Feature States, Risiken und Release-Artefakte inventarisieren. Jede wichtige
Produktzusage muss zu einer Quelle, Regel, Implementierung und Erklärung
rückverfolgbar sein.

### Pass 2: Coverage-Matrix

Die zwölf Prüffelder gegen L1–L8 bewerten. Leere Zellen, ein Reifegrad unter
dem Zielprofil oder ein fehlender Owner erzeugen einen Gap-Kandidaten.

### Pass 3: Negative-Space- und Premortem-Review

Für jeden vertikalen Schnitt fragen:

- Was passiert bei falschen, fehlenden, alten oder manipulierten Daten?
- Was passiert bei Provider-, Netzwerk-, Backend- oder Geräteausfall?
- Welche Aussage könnte ein Nutzer stärker verstehen, als sie belegt ist?
- Was kann ein Angreifer, ein fehlerhafter Client oder ein unberechtigter
  Server-Writer verändern?
- Was passiert bei Accountverlust, Zertifikatsverlust oder Ausfall des Owners?
- Wie wird ein fehlerhafter Score korrigiert, zurückgezogen und kommuniziert?

### Pass 4: External Horizon Scan

Nur Primärquellen für aktuelle technische, regulatorische und
Plattformanforderungen verwenden. Je Quelle werden Version, Prüftag,
Anwendbarkeit, Änderung und nächster Review erfasst. Beispiele:

- Apple App Review Guidelines und App Store Connect Help
- Apple Privacy Manifests und Accessibility Nutrition Labels
- OWASP MASVS/MASTG
- EUR-Lex und Europäische Kommission für DSGVO, Umwelt- und Health-Claims
- Originalbedingungen jedes Datenproviders

Ein geändertes MUST oder ein überschrittenes `next_review_due` erzeugt einen
`stale`-Gap und kann ein Releaseprofil blockieren.

### Pass 5: Priorisierung

Priorität wird nicht aus der Anzahl offener Punkte, sondern aus vier Faktoren
abgeleitet:

- Schaden für Nutzer, Rechte, Score-Richtigkeit oder Geschäft
- Eintrittswahrscheinlichkeit
- zeitliche Nähe des Aktivierungstriggers
- Erkennbarkeit vor Veröffentlichung

| Priorität | Regel |
| --- | --- |
| P0 | rechtlicher, Security-, Privacy- oder schwerer Score-/Claim-Schaden vor dem nächsten Zielprofil möglich |
| P1 | hohe Produkt-/Betriebswirkung oder Releaseblocker mit absehbarem Trigger |
| P2 | wichtige Härtung ohne unmittelbaren Blocker |
| P3 | Optimierung oder langfristige Verbesserung |

### Pass 6: Control Design

Jeder P0-/P1-Gap braucht:

- eindeutigen Owner und Zielprofil
- Aktivierungstrigger oder Fälligkeitsereignis
- testbare Closure-Kriterien
- Mapping auf Improvement, Risiko, Requirement, Gate oder Backlog
- erwartete Evidenz und erneutes Review

Automation wird nur verwendet, wenn eine reproduzierbare technische
Entscheidung möglich ist. Rechtliche, wissenschaftliche, methodische und
Releasefreigaben bleiben HYBRID oder manuell.

### Pass 7: Closure und Regression

Ein Gap ist erst `closed`, wenn:

1. alle Closure-Kriterien erfüllt sind;
2. Evidenzpfade oder Reviewnachweise existieren;
3. relevante lokale und GitHub-Gates grün sind;
4. das Zielprofil den Gap nicht mehr als offen meldet;
5. ein Regressions- oder Wiederholungsmechanismus existiert;
6. verbleibendes Restrisiko ausdrücklich akzeptiert oder weitergeführt wird.

`documented`, `planned` oder ein grünes Development-Profil schließen keinen
Release-Gap.

## 8. Auslöser und Cadence

Die SLGA wird ausgeführt:

- bei jedem Phasenwechsel
- vor Aktivierung einer neuen Datenquelle oder Score-Regel
- vor Einrichtung eines Remote-Backends
- vor TestFlight, Release Candidate und Submission
- bei neuem SDK, Login, Payment, UGC, Analytics, Standort oder AI/ML
- nach schwerem Finding, Incident oder relevanter Regeländerung
- als vollständiger Review mindestens quartalsweise

Compliance-Primärquellen werden separat nach dem im Quellenregister gesetzten
Termin geprüft; aktuell gilt ein 30-Tage-Rhythmus bis zum ersten Release.

## 9. Verantwortlichkeiten

| Rolle | Verantwortung |
| --- | --- |
| Mustafa / Product Owner | Scope, Priorität, Risikoakzeptanz, Claim-, Methodik- und Releaseentscheidung |
| Codex / Engineering Partner | Coverage-Analyse, Implementierung, Tests, Traceability und transparente Unsicherheit |
| ESG-/LCA-/Human-Rights-Review | Fachvalidierung von Parametern, Proxies, Gewichtung und Interpretation |
| Datenschutz-/Rechtsreview | Rechtsgrundlage, Privacy, Lizenzen, Umwelt-/Health-Claims und Veröffentlichung |
| GitHub Actions | reproduzierbare technische und Policy-as-Code-Evidenz |

Codex darf einen rechtlichen oder wissenschaftlichen Gap finden und technisch
strukturieren, aber nicht allein als rechtskonform oder wissenschaftlich
validiert schließen.

## 10. Anti-Patterns

- Gate-Anzahl als Qualitätskennzahl verwenden
- dokumentierte Absicht als implementierte Kontrolle zählen
- Coverage-Prozent mit fachlicher Richtigkeit gleichsetzen
- Hersteller-, Community- oder Kategorieangabe als Produktnachweis behandeln
- Disclaimer als Ersatz für belastbare Evidenz verwenden
- Releasewarnungen dauerhaft im Development-Profil verstecken
- Trigger-Gaps vergessen, wenn Login, Payment, UGC, Analytics oder AI später
  aktiviert werden
- Auditbefunde löschen, sobald eine Maßnahme begonnen wurde
