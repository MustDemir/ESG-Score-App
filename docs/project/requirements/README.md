# Requirements

> Strukturierte Anforderungs-Doku. Pattern übernommen aus
> [genaiops-compliance-gates/requirements/](https://github.com/MustDemir/genaiops-compliance-gates).
> Siehe [ADR 0009](../decisions/0009-methodology-adoption.yaml) und
> [ADR 0012](../decisions/0012-apple-review-compliance.yaml).

## ID-Schema

| Präfix | Quelle | Beispiel | Status |
|---|---|---|---|
| `R-AS-NN` | **A**pple **S**tore Guidelines | R-AS-01, R-AS-29 | 19 spezifiziert |
| `R-DSGVO-NN` | DSGVO (EU 2016/679) | R-DSGVO-01, R-DSGVO-07 | 5 aktiv |
| `R-OFF-NN` | OFF CC-BY-SA Lizenz | R-OFF-01 | via R-AS-06 + R-DSGVO-03 abgedeckt |
| `R-DDG-NN` | Digitale-Dienste-Gesetz | R-DDG-01 | via R-AS-08 abgedeckt |
| `R-INT-NN` | Interne Anforderungen | R-INT-01 | tbd |

Siehe [ADR 0013 — Multi-Regulation-Strategy](../decisions/0013-multi-regulation-strategy.yaml)
für die Logik wie Anforderungen über Regulierungen hinweg gestackt werden.

## Apple-Anforderungen und Gate-Gruppen

| Requirement(s) | Thema | Gate |
|---|---|---|
| [R-AS-01](R-AS-01.yaml), [02](R-AS-02.yaml), [04](R-AS-04.yaml), [05](R-AS-05.yaml), [07](R-AS-07.yaml), [15](R-AS-15.yaml) | Privacy, Consent, bedingte Datenfunktionen | G-AS-PRIVACY |
| [R-AS-03](R-AS-03.yaml) | Kamera-Purpose und Laufzeitverhalten | G-AS-CAMERA |
| [R-AS-06](R-AS-06.yaml), [16](R-AS-16.yaml) | OFF- und Drittanbieter-Rechte | G-AS-THIRD-PARTY-RIGHTS |
| [R-AS-08](R-AS-08.yaml) | Support und Anbieteridentitaet | G-AS-SUPPORT-IDENTITY |
| [R-AS-09](R-AS-09.yaml), [13](R-AS-13.yaml), [14](R-AS-14.yaml) | Review-, Device- und Netzwerkbereitschaft | G-AS-REVIEW-READINESS |
| [R-AS-10](R-AS-10.yaml), [11](R-AS-11.yaml), [12](R-AS-12.yaml) | App-Store-Metadaten | G-AS-METADATA |
| [R-AS-04](R-AS-04.yaml), [13](R-AS-13.yaml) | Build- und Plattformintegritaet | G-AS-BUILD-INTEGRITY |
| [R-AS-27](R-AS-27.yaml) | Nachvollziehbare ESG-Aussagen | G-AS-CLAIMS-TRANSPARENCY |
| [R-AS-28](R-AS-28.yaml) | Aktivierungskontrolle fuer IAP, Login, AI, Chatbot, UGC und Push | G-AS-PRIVACY, G-AS-REVIEW-READINESS |
| [R-AS-29](R-AS-29.yaml) | Apple HIG und Accessibility als SHOULD | G-AS-REVIEW-READINESS |

`always`-Requirements gelten durchgehend. `conditional`-Requirements werden
durch einen nachpruefbaren Feature-Trigger aktiviert; ein Feature-Flag ist keine
Ausnahmegenehmigung. Details stehen im
[`apple-compliance-control-model.md`](../compliance/apple-compliance-control-model.md).

## DSGVO Phase-1 (5 aktiv)

| ID | Titel | Artikel | Gate(s) | Overlap |
|---|---|---|---|---|
| [R-DSGVO-01](R-DSGVO-01.yaml) | Rechtsgrundlage pro Zweck | 6 | G-DSGVO-LAWFUL-BASIS | — |
| R-DSGVO-02 (TODO) | Consent-Mechanismus | 7 | G-DSGVO-CONSENT | R-AS-07 |
| R-DSGVO-03 (TODO) | Privacy Policy nach Art. 13 | 12, 13 | G-DSGVO-POLICY | R-AS-01, R-AS-06 |
| R-DSGVO-04 (TODO) | Auskunftsrecht erfüllen | 15 | G-DSGVO-EXPORT | — |
| R-DSGVO-05 (TODO) | Datenminimierung + Zweckbindung | 5(1)(b,c) | G-DSGVO-MIN-DATA | R-AS-04 |
| R-DSGVO-06 (TODO) | Aufbewahrungsfristen | 5(1)(e) | G-DSGVO-RETENTION | — |
| [R-DSGVO-07](R-DSGVO-07.yaml) | Recht auf Löschung | 17 | G-DSGVO-DELETE | R-AS-05 |
| R-DSGVO-08 (TODO) | Datenübertragbarkeit | 20 | G-DSGVO-EXPORT | — |
| [R-DSGVO-09](R-DSGVO-09.yaml) | TOMs nach Art. 32 | 32 | G-DSGVO-TOMS | ADR 0008 |
| [R-DSGVO-10](R-DSGVO-10.yaml) | Privacy by Design + Default | 25 | G-DSGVO-PRIVACY-DESIGN | R-AS-04, R-DSGVO-05 |
| [R-DSGVO-11](R-DSGVO-11.yaml) | AVV mit Supabase | 28 | G-DSGVO-AVV | — |
| R-DSGVO-12 (TODO) | VVT (Verzeichnis Verarbeitungstätigkeiten) | 30 | G-DSGVO-VVT | — |
| R-DSGVO-13 (TODO) | Incident-Response 72h | 33, 34 | G-DSGVO-INCIDENT | — |

## Phase-2-Add-Ons (geplant)

Werden aktiviert mit ScanFair+ Membership + KI-Chat:

| ID | Titel | Apple-Ref |
|---|---|---|
| R-AS-17 | IAP-Pflicht für KI-Features | 3.1.1 |
| R-AS-18 | Subscription ≥ 7 Tage | 3.1.2(a) |
| R-AS-19 | Subscription-Info-Transparenz | 3.1.2(c) |
| R-AS-20 bis R-AS-24 | Architekturabhaengige Chatbot-/4.7-Kontrollen | 4.7.1-4.7.5 |
| R-AS-25 | Gleichwertige datenschutzfreundliche Login-Option, soweit erforderlich | 4.8 |
| R-AS-26 | Push-Notifications nur mit Consent | 4.5.3, 4.5.4 |

R-AS-28 blockiert die Aktivierung dieser Featureklassen bereits jetzt. Vor der
eigentlichen Umsetzung werden die jeweils aktuellen Detailrequirements gegen
Architektur, Vertriebsregion und Apple-Fassung materialisiert.

### Phase 2 DSGVO-Add-Ons

| ID | Titel | Artikel | Trigger |
|---|---|---|---|
| R-DSGVO-14 | Auto-Entscheidung-Recht-auf-Mensch | 22 | KI-Score-Layer |
| R-DSGVO-15 | Drittland-Transfer-Klausel | 44-49 | US-KI-Provider |
| R-DSGVO-16 | DSFA bei hohem Risiko | 35 | Falls Profiling |
| R-DSGVO-17 | Einwilligungs-Widerruf KI | 7(3) | ScanFair+ |

## Wartung

- Bei neuem Apple-Guidelines-Update: `apple-review-relevance.md` neu prüfen, dann hier ergänzen
- Bei neuer R: ID-Reihenfolge halten, hier eintragen, Status updaten
- Status-Werte: `(TODO)` wenn YAML noch nicht geschrieben, `(active)` wenn live, `(deferred)` wenn nach Phase 1
