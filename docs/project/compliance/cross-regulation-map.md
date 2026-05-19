# Cross-Regulation-Map — eine Implementation, mehrere Regulierungen

> Zeigt welche ScanFair-Implementation welche regulatorische Anforderung
> aus WELCHER Regulierung erfüllt. Ziel: Duplikat-Implementations vermeiden.
>
> Methodisch basiert auf Master-Thesis-Framework (siehe
> [ADR 0009](../decisions/0009-methodology-adoption.yaml)), erweitert um
> Multi-Regulation-Stacking (siehe [ADR 0013](../decisions/0013-multi-regulation-strategy.yaml)).
>
> Letztes Update: 2026-05-19

## Konzept: „Eine Anforderung, mehrere Quellen"

Wenn Apple-Guideline 5.1.1(v) (Account-Löschung) und DSGVO Art. 17 (Recht auf
Löschung) **die gleiche technische Implementation** verlangen, dann zählen wir
das als **eine Anforderung** mit zwei Regulation-Refs.

Vorteile:
- Eine Implementation, zwei (oder mehr) Compliance-Punkte erfüllt
- Klar dokumentiert was gerichtsfest abgedeckt ist
- Bei Reviewer-Anfrage (Apple oder Aufsichtsbehörde) eine Spur

## Mapping-Matrix — Phase 1 MVP

| Implementation / Feature | Apple Guideline | DSGVO Artikel | OFF-Lizenz | Erfasst durch |
|---|---|---|---|---|
| **Privacy Policy URL in App + Connect** | 5.1.1(i) | Art. 12, 13 | (Attribution) | R-AS-01 ⇄ R-DSGVO-03 |
| **Account-Löschung in App** | 5.1.1(v) | Art. 17 | – | R-AS-05 ⇄ R-DSGVO-07 |
| **Datenminimierung / nur Pflicht-Perms** | 5.1.1(iii) | Art. 5(1)(c), 25 | – | R-AS-04 ⇄ R-DSGVO-05 ⇄ R-DSGVO-10 |
| **Camera Purpose String präzise** | 2.5.14 | Art. 13 | – | R-AS-03 (⊆ R-DSGVO-03 Info-Pflicht) |
| **OFF-Quelle offenlegen** | 5.1.1(viii), 5.2.2 | Art. 13(1)(e), 14 | CC BY-SA Attribution | R-AS-06 ⇄ R-DSGVO-03 ⇄ R-OFF-01 (TBD) |
| **HTTPS-only / TLS** | 1.6 (impliziert) | Art. 32(1)(a) | – | R-DSGVO-09 (⊆ ADR 0008 SEC-4) |
| **Supabase RLS für alle Tabellen** | 1.6 | Art. 32(1)(b) | – | R-DSGVO-09 (⊆ ADR 0008 SEC-3) |
| **Supabase EU-Frankfurt** | – | Art. 44-50 (kein Transfer) | – | R-DSGVO-15 (Phase 2 wenn US-Provider) |
| **Supabase AVV unterzeichnet** | – | Art. 28 | – | R-DSGVO-11 |
| **Consent für Tracking (ATT)** | 5.1.2(i) | Art. 6(1)(a), 7 | – | R-AS-07 ⇄ R-DSGVO-02 |
| **Support-URL + Impressum** | 1.5 | (TMG §5 DE-Recht) | – | R-AS-08 (+ R-TMG-01 TBD) |
| **Sign in with Apple (wenn Social-Login)** | 4.8 | Art. 25 (Privacy-Auth) | – | R-AS-25 (Phase 2) |
| **Standard-Review-API (kein erzwungener Prompt)** | 3.2.2(x), 5.6.1 | – | – | R-AS-14 |

## Übersicht — wie viele Doppel-Treffer haben wir

| Implementation | # Regulierungen abgedeckt |
|---|---|
| Privacy Policy (mit OFF-Erwähnung) | **3** (Apple, DSGVO, OFF-Lizenz) |
| Account-Löschung | **2** (Apple, DSGVO) |
| Datenminimierung | **3** (Apple, DSGVO Art. 5, DSGVO Art. 25) |
| HTTPS-only | **2** (Apple, DSGVO) |
| Camera Purpose String | **2** (Apple, DSGVO Info-Pflicht) |
| OFF-Quelle offenlegen | **3** (Apple, DSGVO, OFF-Lizenz) |
| Tracking-Consent | **2** (Apple ATT, DSGVO Consent) |

**Effekt:** ~30-40% Compliance-Implementation-Aufwand gespart durch
Konsolidierung — die meisten Apple-Pflichten überlappen mit DSGVO.

## Was NICHT überlappt — eindeutige Anforderungen

### Nur Apple (kein DSGVO-Pendant)
- App-Name ≤ 30 Zeichen (R-AS-12)
- Keine fremden Plattform-Namen (R-AS-12)
- Screenshots zeigen App in Use (R-AS-10)
- Altersfreigabe ehrlich (R-AS-11)
- Demo-Account für Reviewer (R-AS-09)
- IAP-Pflicht für digitale Inhalte (R-AS-17, Phase 2)
- Subscription-Mindestlaufzeit (R-AS-18, Phase 2)
- Chatbot-Inhaltsfilter (R-AS-20, Phase 2)

### Nur DSGVO (kein Apple-Pendant)
- Rechtsgrundlage pro Verarbeitungszweck (R-DSGVO-01)
- VVT — Verzeichnis Verarbeitungstätigkeiten (R-DSGVO-12)
- AVV mit Auftragsverarbeitern (R-DSGVO-11)
- Datenübertragbarkeit / Export (R-DSGVO-08)
- Aufbewahrungsfristen (R-DSGVO-06)
- Incident-Response 72h (R-DSGVO-13)
- DSFA bei hohem Risiko (R-DSGVO-16, ggf. Phase 2)

### Nur OFF-Lizenz (CC BY-SA)
- Attribution-Pflicht „Powered by Open Food Facts" (wird via R-AS-06 + R-DSGVO-03 mit erfüllt)
- ShareAlike-Pflicht falls eigene OFF-Derivate veröffentlicht (Phase 3+ relevant)

## Konflikt-Detection — wo könnten Regulierungen sich widersprechen?

Theoretisch denkbar, in der Praxis selten:

| Mögliche Konflikt-Konstellation | Bewertung |
|---|---|
| Apple verlangt IAP, EU-Recht verlangt Wahlfreiheit (Digital Markets Act) | EU-Region: Apple muss zulassen, USA: strikter — wir nutzen Apple-IAP, das ist EU-konform |
| DSGVO: Datenminimierung — AML/KYC: mehr Daten speichern | N/A für uns (keine Finanz-App) |
| DSGVO: Recht auf Löschung — Steuerrecht: Aufbewahrungsfristen | Bei Abrechnungen relevant — Membership-Rechnungen 10 Jahre aufbewahren (Soft-Delete von App-Konto, Hard-Delete erst nach Frist) |

**Konfliktbeispiel das uns betrifft:** wenn ein User Premium kauft, dann sein
Account löschen will → DSGVO sagt löschen, deutsches Steuerrecht (AO §147) sagt
Rechnungs-Daten 10 Jahre aufbewahren. Lösung: User-Profil-Daten löschen,
Rechnungs-Daten anonymisiert/pseudonymisiert in separater Tabelle 10 Jahre.

Dokumentation dieser Konflikt-Auflösung gehört in den TOM-Katalog + Privacy
Policy.

## Wartung dieser Map

- Bei neuer R-AS oder R-DSGVO: hier prüfen ob Overlap mit anderem Reg
- Bei neuer Implementation: in der Mapping-Matrix eintragen
- Bei Regulierungs-Update: betroffene Spalte neu prüfen
