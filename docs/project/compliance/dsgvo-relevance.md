# DSGVO — Relevanz-Mapping für ScanFair

> Analyse der DSGVO/GDPR-Anforderungen für ScanFair. Methodik identisch zu
> [`apple-review-relevance.md`](apple-review-relevance.md) — übernommen aus
> Master-Thesis-Repo `genaiops-compliance-gates`.
> Quelle: Verordnung (EU) 2016/679, anwendbar seit 25.05.2018.
> Letztes Update: 2026-05-19

## Bewertungs-Legende

| Symbol | Bedeutung |
|---|---|
| 🔴 | **Pflicht für ScanFair MVP** — Verstoß = Bußgeld bis 20 M€ / 4% Umsatz |
| ⚠️ | **Phase 2+** oder bedingt relevant |
| ✅ | Erfüllt sich durch unsere Architektur / nicht anwendbar |
| ⬜ | Nicht relevant (z.B. wir sind nicht DSB-pflichtig) |

---

## Kapitel I — Allgemeine Bestimmungen (Art. 1-4)

| Artikel | Inhalt | Relevanz | Begründung / Defense |
|---|---|---|---|
| Art. 1 Gegenstand | Schutz personenbezogener Daten | ✅ | Anwendbarkeit klar |
| Art. 2 Sachlicher AB | Automatisierte Verarbeitung | ✅ | App fällt darunter |
| Art. 3 Räumlicher AB | EU-Bezug | ✅ | Wir verkaufen in DE/EU |
| Art. 4 Begriffe | Definitionen | ✅ | Referenz-Glossar |

## Kapitel II — Grundsätze (Art. 5-11) 🔴 KERN

| Artikel | Inhalt | Relevanz | Anforderung |
|---|---|---|---|
| **Art. 5(1)(a) Rechtmäßigkeit** | Daten nur rechtmäßig verarbeitet | 🔴 | R-DSGVO-01 |
| **Art. 5(1)(b) Zweckbindung** | Daten nur für bestimmten Zweck | 🔴 | R-DSGVO-05 |
| **Art. 5(1)(c) Datenminimierung** | Nur was nötig ist | 🔴 | R-DSGVO-05 (überlappt mit R-AS-04) |
| Art. 5(1)(d) Richtigkeit | Daten aktuell halten | 🔴 | Implizit: User können Daten korrigieren |
| **Art. 5(1)(e) Speicherbegrenzung** | Nicht ewig speichern | 🔴 | R-DSGVO-06 (Aufbewahrungsfristen) |
| **Art. 5(1)(f) Integrität/Vertraulichkeit** | TOMs | 🔴 | R-DSGVO-09 (überlappt mit ADR 0008) |
| Art. 5(2) Rechenschaftspflicht | Verarbeitungs-Doku | 🔴 | VVT nach Art. 30 |
| **Art. 6 Rechtmäßigkeit der Verarbeitung** | Rechtsgrundlage | 🔴 | R-DSGVO-01 — für Scans = Art. 6(1)(b) Vertrag; für Membership = Vertrag; für KI-Cache = berechtigtes Interesse |
| **Art. 7 Einwilligung** | Wenn auf Consent gestützt | 🔴 | R-DSGVO-02 — bei Tracking/Analytics |
| Art. 8 Kinder-Einwilligung | < 16 Jahre Elternzustimmung | ⚠️ | Wir richten App nicht an Kinder, aber Age-Check nötig |
| Art. 9 Besondere Kategorien | Gesundheit/Bio etc. | ⬜ | ESG-Daten sind keine besondere Kategorie |
| Art. 10 Strafrechtliche Daten | | ⬜ | N/A |

## Kapitel III — Rechte der betroffenen Person (Art. 12-23) 🔴 KERN

| Artikel | Inhalt | Relevanz | Anforderung |
|---|---|---|---|
| **Art. 12 Transparenz** | Verständliche Information | 🔴 | R-DSGVO-03 (Privacy Policy) |
| **Art. 13 Info bei Erhebung** | Privacy-Pflicht-Felder | 🔴 | R-DSGVO-03 (überlappt mit R-AS-01) |
| Art. 14 Info bei nicht-direkter Erhebung | OFF ist öffentliche DB | ⚠️ | OFF-Daten sind keine personenbezogenen → Art. 14 trifft nicht zu für OFF, aber wenn wir je Daten von Dritten kaufen |
| **Art. 15 Auskunftsrecht** | User darf Datenkopie verlangen | 🔴 | R-DSGVO-04 (Phase 1 manuell, später Self-Service) |
| Art. 16 Berichtigung | Korrektur-Recht | 🔴 | Im User-Profil bearbeitbar |
| **Art. 17 Recht auf Löschung** | "Recht auf Vergessenwerden" | 🔴 | R-DSGVO-07 (überlappt mit R-AS-05) |
| Art. 18 Einschränkung | Verarbeitung pausieren | ⚠️ | Implementation in Phase 2 |
| Art. 19 Mitteilungspflicht | Bei Berichtigung/Löschung | 🔴 | Trivial wenn keine Empfänger |
| **Art. 20 Datenübertragbarkeit** | Export-Format | 🔴 | R-DSGVO-08 (JSON/CSV-Export) |
| Art. 21 Widerspruchsrecht | Gegen Verarbeitung | 🔴 | Settings: „Datenverarbeitung beenden" |
| **Art. 22 Automatisierte Entscheidung** | Profiling | ⚠️ Phase 2 | KI-Score könnte als „automatisierte Einzelfallentscheidung" gewertet werden — bei Score-Erklärung mit LLM relevant |
| Art. 23 Beschränkungen | | ⬜ | N/A |

## Kapitel IV — Verantwortlicher und Auftragsverarbeiter (Art. 24-43) 🔴 KERN

| Artikel | Inhalt | Relevanz | Anforderung |
|---|---|---|---|
| Art. 24 Verantwortlichkeit | Doku der Maßnahmen | 🔴 | Wir = Verantwortlicher |
| **Art. 25 Privacy by Design + Default** | Datenschutz von Anfang | 🔴 | R-DSGVO-10 (überlappt mit ADR 0008) |
| Art. 26 Gemeinsame Verantwortliche | | ⬜ | Wir entscheiden alleine |
| **Art. 28 Auftragsverarbeitung (AVV)** | Vertrag mit Dienstleistern | 🔴 | R-DSGVO-11 — Supabase-AVV, OFF braucht keine (keine personenbezogenen Daten) |
| Art. 29 Verarbeitung unter Aufsicht | | ✅ | Trivial bei Solo |
| **Art. 30 Verzeichnis der Verarbeitungstätigkeiten (VVT)** | Pflicht ab 250 MA oder bei Risiko | 🔴 | R-DSGVO-12 — wir < 250 MA, aber regelmäßige Verarbeitung → empfohlen |
| Art. 31 Zusammenarbeit Aufsichtsbehörde | | ✅ | Bei Anfrage |
| **Art. 32 Technische + organisatorische Maßnahmen (TOMs)** | Sicherheit | 🔴 | R-DSGVO-09 (überlappt mit ADR 0008 stark) |
| **Art. 33 Meldepflicht bei Datenpanne** | 72h Frist | 🔴 | R-DSGVO-13 — Incident-Response-Prozess vor TestFlight nötig |
| **Art. 34 Benachrichtigung Betroffene** | Bei hohem Risiko | 🔴 | Teil von R-DSGVO-13 |
| Art. 35 DSFA | Bei hohem Risiko | ⚠️ | Wahrscheinlich nicht nötig (kein hohes Risiko), aber dokumentieren warum nicht |
| Art. 36 Vorherige Konsultation | | ⬜ | Nur bei DSFA-Pflicht |
| Art. 37-39 Datenschutzbeauftragter | DSB-Pflicht | ⬜ | Solo-Founder nicht DSB-pflichtig (< 20 Personen verarbeiten regelmäßig) |
| Art. 40-43 Verhaltensregeln | | ⬜ | N/A |

## Kapitel V — Übermittlung an Drittländer (Art. 44-50)

| Artikel | Inhalt | Relevanz | Anforderung |
|---|---|---|---|
| Art. 44-50 | Drittland-Transfers | ✅ | Supabase EU-Frankfurt + OFF in FR — kein Drittland-Transfer in Phase 1 |
| | | ⚠️ Phase 2 | **WICHTIG**: Claude/Mistral/Aleph Alpha als KI-Provider — Mistral + Aleph Alpha = EU ✅, Claude = US → AWS Bedrock EU-Region nötig oder SCC |

## Kapitel VI-XI

| Kapitel | Inhalt | Relevanz |
|---|---|---|
| VI Unabhängige Aufsichtsbehörden | | ✅ Bei Anfrage |
| VII Zusammenarbeit | | ⬜ |
| VIII Rechtsbehelfe + Haftung | Schadensersatz | ✅ Risiko verstanden |
| IX Besondere Vorschriften (z.B. Beschäftigte) | | ⬜ |
| X Delegated Acts | | ⬜ |
| XI Schlussbestimmungen | | ⬜ |

---

## Zusammenfassung — 13 Phase-1-Anforderungen für ScanFair

| R-DSGVO-ID | Titel | Artikel | Gate (geplant) | Phase |
|---|---|---|---|---|
| **R-DSGVO-01** | Rechtsgrundlage definiert | Art. 6 | G-DSGVO-LAWFUL-BASIS | 1 |
| **R-DSGVO-02** | Consent-Mechanismus (wo nötig) | Art. 7 | G-DSGVO-CONSENT | 1 |
| **R-DSGVO-03** | Privacy Policy nach Art. 13 | Art. 12, 13 | G-DSGVO-POLICY (= G-AS-PRIVACY-URL erweitert) | 1 |
| **R-DSGVO-04** | Auskunftsrecht erfüllen können | Art. 15 | G-DSGVO-EXPORT (Hybrid Phase 1) | 1 |
| **R-DSGVO-05** | Datenminimierung + Zweckbindung | Art. 5(1)(b,c) | G-DSGVO-MIN-DATA | 1 |
| **R-DSGVO-06** | Aufbewahrungsfristen definiert | Art. 5(1)(e) | G-DSGVO-RETENTION | 1 |
| **R-DSGVO-07** | Löschrecht implementiert | Art. 17 | G-DSGVO-DELETE (= G-AS-ACCOUNT-DELETE erweitert) | 1 |
| **R-DSGVO-08** | Datenübertragbarkeit (Export) | Art. 20 | G-DSGVO-EXPORT | 1 |
| **R-DSGVO-09** | TOMs (Verschlüsselung, RLS, ...) | Art. 32 | G-DSGVO-TOMS (= ADR 0008-Mapping) | 1 |
| **R-DSGVO-10** | Privacy by Design + Default | Art. 25 | G-DSGVO-PRIVACY-DESIGN (Hybrid) | 1 |
| **R-DSGVO-11** | AVV mit Supabase | Art. 28 | G-DSGVO-AVV (Hybrid manuell) | 1 |
| **R-DSGVO-12** | Verzeichnis Verarbeitungstätigkeiten | Art. 30 | G-DSGVO-VVT (Hybrid manuell) | 1 |
| **R-DSGVO-13** | Incident-Response (72h-Meldung) | Art. 33, 34 | G-DSGVO-INCIDENT (Hybrid) | 1 (Prozess) |

## Phase-2-Add-Ons

| R-DSGVO-ID | Titel | Artikel | Trigger |
|---|---|---|---|
| R-DSGVO-14 | Auto-Entscheidung-Recht-auf-Mensch | Art. 22 | KI-Score-Layer |
| R-DSGVO-15 | Drittland-Transfer (Claude/AWS) | Art. 44-49 | Wenn US-Provider |
| R-DSGVO-16 | Datenschutz-Folgenabschätzung | Art. 35 | Wenn hohes Risiko (z.B. Profiling) |
| R-DSGVO-17 | Einwilligungs-Widerruf für KI-Features | Art. 7(3) | Mit ScanFair+ KI-Features |

## Was wir BEWUSST nicht abdecken

- **Art. 37-39 DSB-Pflicht**: Solo-Founder < 20 Personen regelmäßige Verarbeitung — nicht pflichtig. Bei Skalierung neu prüfen.
- **Art. 35 DSFA**: in Phase 1 wahrscheinlich nicht erforderlich (kein hohes Risiko nach Art. 35(3)). Dokumentieren warum nicht.
- **Art. 27 Vertreter (Nicht-EU)**: wir sind in DE ansässig → trifft nicht zu.

## Wartung

- Bei DSGVO-Änderungen (EU AI Act ergänzt indirekt) neu prüfen
- Bei neuem Dienstleister: AVV-Check + ggf. neues R-DSGVO
- Mind. jährlich VVT (R-DSGVO-12) reviewen
