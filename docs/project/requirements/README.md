# Requirements

> Strukturierte Anforderungs-Doku. Pattern übernommen aus
> [genaiops-compliance-gates/requirements/](https://github.com/MustDemir/genaiops-compliance-gates).
> Siehe [ADR 0009](../decisions/0009-methodology-adoption.yaml) und
> [ADR 0012](../decisions/0012-apple-review-compliance.yaml).

## ID-Schema

| Präfix | Quelle | Beispiel | Status |
|---|---|---|---|
| `R-AS-NN` | **A**pple **S**tore Guidelines | R-AS-01, R-AS-12 | 5 aktiv |
| `R-DSGVO-NN` | DSGVO (EU 2016/679) | R-DSGVO-01, R-DSGVO-07 | 5 aktiv |
| `R-OFF-NN` | OFF CC-BY-SA Lizenz | R-OFF-01 | via R-AS-06 + R-DSGVO-03 abgedeckt |
| `R-TMG-NN` | Telemediengesetz (DE Impressumspflicht) | R-TMG-01 | via R-AS-08 abgedeckt |
| `R-INT-NN` | Interne Anforderungen | R-INT-01 | tbd |

Siehe [ADR 0013 — Multi-Regulation-Strategy](../decisions/0013-multi-regulation-strategy.yaml)
für die Logik wie Anforderungen über Regulierungen hinweg gestackt werden.

## Status (Phase 1 MVP, aus Apple-Mapping)

| ID | Titel | Phase | Gate(s) |
|---|---|---|---|
| [R-AS-01](R-AS-01.yaml) | Privacy Policy Link Pflicht | 1 | G-AS-PRIVACY-URL |
| R-AS-02 (TODO) | Consent für Datenerfassung | 1 | G-AS-CONSENT |
| [R-AS-03](R-AS-03.yaml) | Kamera-Purpose-String präzise | 1 | G-AS-CAMERA-PURPOSE |
| R-AS-04 (TODO) | Datensparsamkeit | 1 | G-AS-MIN-PERMS |
| R-AS-05 (TODO) | Account-Löschung wenn Auth | 1 (Phase 2 IAP-Add-On) | G-AS-ACCOUNT-DELETE |
| [R-AS-06](R-AS-06.yaml) | OFF als externe Quelle offenlegen | 1 | G-AS-DATA-SOURCE-DISCLOSE |
| R-AS-07 (TODO) | ATT-Prompt wenn Tracking | 1 | G-AS-ATT-PROMPT |
| [R-AS-08](R-AS-08.yaml) | Support-URL erreichbar | 1 | G-AS-SUPPORT-URL |
| R-AS-09 (TODO) | Demo-Account für Reviewer | 1 (vor TestFlight) | G-AS-DEMO-ACCOUNT (Hybrid) |
| R-AS-10 (TODO) | Screenshots zeigen App in Use | 1 (vor Submission) | G-AS-SCREENSHOTS (Hybrid) |
| R-AS-11 (TODO) | Altersfreigabe ehrlich beantwortet | 1 | G-AS-AGE-RATING |
| [R-AS-12](R-AS-12.yaml) | App-Name ≤ 30 Zeichen + saubere Metadata | 1 | G-AS-NAME-LENGTH, G-AS-PLATFORM-NAMES |
| R-AS-13 (TODO) | Keine Background-Mining | 1 | (trivial) |
| R-AS-14 (TODO) | Standard-Review-API für Bewertungs-Prompt | 1 | G-AS-REVIEW-API |
| R-AS-15 (TODO) | Ortung nur mit Zweck-Erklärung | 2+ | G-AS-LOCATION-PURPOSE |
| R-AS-16 (TODO) | OFF-CC-BY-SA-Attribution dokumentiert | 1 | G-AS-LICENSE-DOC (redundant zu R-AS-06) |

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
| R-AS-20 | Chatbot-Inhaltsfilter | 4.7.1 |
| R-AS-21 | Chatbot-Reporting-Mechanismus | 4.7.1 |
| R-AS-22 | Chatbot-Sperr-Mechanismus | 4.7.1 |
| R-AS-23 | Chatbot-Software-Index | 4.7.4 |
| R-AS-24 | Chatbot-Altersbeschränkung | 4.7.5 |
| R-AS-25 | Sign in with Apple wenn Social-Login | 4.8 |
| R-AS-26 | Push-Notifications nur mit Consent | 4.5.3, 4.5.4 |

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
