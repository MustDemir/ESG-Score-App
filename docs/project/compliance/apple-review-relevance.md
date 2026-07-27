# Apple App Review Guidelines - Relevanz-Mapping fuer ScanFair

> Historische Vollanalyse: deutsches Apple-PDF vom 6. Februar 2026.
> Aktueller operativer Stand: offizielle Webfassung vom 8. Juni 2026.
> Quellen-SSOT: [`source-register.yaml`](source-register.yaml).
>
> Methodik aus Master-Thesis-Repo (`genaiops-compliance-gates`) übernommen.
> Siehe [ADR 0009](../decisions/0009-methodology-adoption.yaml) (Methodik) und
> [ADR 0012](../decisions/0012-apple-review-compliance.yaml) (Apple-Spezifika).
>
> Letzte Verifikation: 2026-07-19

Die ausfuehrbaren Artefakte sind 19 Requirements, acht gruppierte Apple-Gates
und acht produktive Rego-Namespaces. Einzelne Richtlinienabschnitte werden nicht
automatisch zu eigenen Gates; ein Gate bleibt eine Release-Entscheidungsstelle.
Siehe [`apple-compliance-control-model.md`](apple-compliance-control-model.md).

## Bewertungs-Legende

| Symbol | Bedeutung |
|---|---|
| 🔴 | **Pflicht für ScanFair MVP** — Verstoß = App-Store-Reject |
| ⚠️ | **Phase 2+** oder bedingt relevant (z.B. mit ScanFair+) |
| ✅ | Erfüllt sich von selbst durch unsere Architektur |
| ⬜ | Nicht anwendbar (z.B. wir bauen kein Spiel) |

---

## Sektion 1 — Sicherheit

| Punkt | Inhalt | Relevanz | Begründung / Defense |
|---|---|---|---|
| 1.1 Anstößige Inhalte (.1-.7) | Verleumdung, Gewalt, Religion, Sex, etc. | ⬜ | Wir zeigen ESG-Score, keinen redaktionellen Inhalt |
| 1.2 Nutzergenerierte Inhalte | Filter, Reporting, Sperren und Entwicklerverantwortung | ⚠️ Bedingt | Wird bei `feature_user_generated_content_enabled=true` aktiviert; Juni-2026-Praezisierung beruecksichtigen |
| 1.2.1 Creator-Inhalte | Altersbeschränkung | ⬜ | N/A |
| 1.3 Kategorie „Kinder" | Spezielle Privacy-Anforderungen | ⬜ | Wir wählen NICHT Kategorie „Kinder" |
| **1.4.3** Substanz-Förderung | Tabak/Alkohol/Drogen-Förderung verboten | 🔴 | **Risiko**: ESG-Score für Wein/Bier könnte als Förderung interpretiert werden → siehe FM-AS-01 |
| 1.4.1 Medizinische Apps | Genauigkeit, Disclaimers | ⬜ | Wir sind keine Medizin-App |
| **1.5 Entwicklerinformationen** | Support-URL Pflicht | 🔴 | Support-Email + URL muss in App + App Store Connect → R-AS-08 |
| **1.6 Datensicherheit** | Schutz erfasster Daten | 🔴 | Bereits abgedeckt durch ADR 0008 (RLS, HTTPS, Secrets) |
| 1.7 Meldung Verbrechen | Strafverfolgung einbeziehen | ⬜ | N/A |

## Sektion 2 — Leistung

| Punkt | Inhalt | Relevanz | Begründung / Defense |
|---|---|---|---|
| **2.1(a) Vollständigkeit** | Voll funktionsfähig, Review-Zugang | 🔴 | Reviewer erhalten bekannte Barcodes und nur bei aktivem Login einen Account -> R-AS-09 |
| 2.1(b) IAP vollständig sichtbar | für Reviewer | ⚠️ Phase 2 | Mit ScanFair+ |
| 2.2 Betatests | TestFlight statt App Store | ✅ | Plan steht (S21) |
| **2.3.1(a) Keine versteckten Features** | Funktionen sichtbar dokumentiert | 🔴 | Code-Review-Prinzip — keine Easter-Eggs |
| **2.3.3 Screenshots zeigen App in Use** | Nicht nur Splash/Login | 🔴 | R-AS-10 (Hybrid) |
| 2.3.5 App Store Kategorie | Richtig wählen | ⚠️ | Bei App-Submission: „Food & Drink" oder „Lifestyle" |
| **2.3.6 Altersfreigabe ehrlich** | Antworten in App Store Connect | 🔴 | Voraussichtlich 4+ — R-AS-11 |
| **2.3.7 App-Name ≤ 30 Zeichen** | + keine Marken-Verletzung | 🔴 | Automatische Laengenpruefung plus hybrider Markenreview in G-AS-METADATA |
| 2.3.8 Metadaten altersgerecht | Für alle Zielgruppen | 🔴 | Screenshots/Texte angemessen — R-AS-12 |
| **2.3.10 Keine fremden Plattform-Namen** | „Android", „Google Play" verboten in iOS | 🔴 | Deterministischer Metadatencheck in G-AS-METADATA |
| 2.3.11 Vorbestellung | Konsistent zur Endversion | ⬜ | Keine Vorbestellung geplant |
| 2.3.12 Update-Texte präzise | Wichtige Änderungen benennen | 🔴 | Release-Notes-Disziplin (quality-strategy.md §7) |
| **2.4.2 Energie-Effizienz** | Keine übermäßige Wärme/Batterie, kein Background-Mining | 🔴 | Wir machen kein Mining ✅ — R-AS-13 |
| 2.4.3 Apple TV unabhängig | Ohne extra Hardware | ⬜ | Wir bauen kein tvOS |
| 2.4.4 Keine Geräte-Neustart-Anforderung | | ✅ | Trifft uns nicht |
| **2.5.1 Nur öffentliche APIs** | Keine Private APIs | 🔴 | Flutter nutzt öffentliche APIs ✅ |
| 2.5.2 Code-Ladung außerhalb Bundle | Verboten (außer Bildung) | ✅ | Wir laden keinen externen Code |
| 2.5.3 Kein Malware-Verhalten | | ✅ | Selbstverständlich |
| 2.5.4 Multitasking nur für definierte Zwecke | | ✅ | Wir nutzen keine Hintergrund-Dienste |
| **2.5.5 IPv6-Support** | Reine IPv6-Netze funktionsfähig | 🔴 | Bei API-Calls Hostnames nutzen (nicht IPv4) → G-AS-IPV6 |
| 2.5.6 WebKit für Browser | | ⬜ | Keine eigene Browser-Engine |
| 2.5.13 LocalAuthentication für Face-ID | Nicht ARKit | ⚠️ | Falls Biometric-Login in Phase 2 |
| **2.5.14 Kamera-Aufnahme mit Consent** | Visuell + akustisch hinweisen | 🔴 | Wir nutzen Kamera (Scanner) — Purpose String Pflicht → R-AS-03 |
| 2.5.16 Widgets-Bezug zur App | | ⚠️ Phase 3 | Keine Widgets im MVP |
| 2.5.18 Display-Werbung auf Hauptbinärdatei beschränkt | Nicht in Widgets/Watch | ✅ | Wir haben keine Werbung (ADR 0006) |

## Sektion 3 — Geschäfte

| Punkt | Inhalt | Relevanz | Begründung / Defense |
|---|---|---|---|
| **3.1.1 IAP-Pflicht** für digitale Inhalte/Features | | ⚠️ Phase 2 | ScanFair+ KI-Erklärung = digitale Inhalte → IAP Pflicht (kein Stripe etc.) |
| 3.1.1(a) Externe Kauflinks | Mit Berechtigung | ⬜ | Wir nutzen Standard-IAP |
| **3.1.2 Abonnements** | Auto-Renewal-Regeln | ⚠️ Phase 2 | ScanFair+ Monatlich/Jährlich |
| **3.1.2(a) Mindest-Laufzeit 7 Tage** | | ⚠️ Phase 2 | G-AS-SUB-DURATION |
| **3.1.2(c) Subscription-Info transparent** | Preis, Verlängerung, Inhalt | ⚠️ Phase 2 | G-AS-SUB-INFO + Hybrid-Review |
| 3.1.3(b) Plattform-übergreifend | Inhalte aus Web nutzbar | ⬜ | Wir haben kein Web-Pendant in Phase 2 |
| 3.1.5 Kryptowährungen | | ⬜ | N/A |
| 3.2.1(v) Versicherungs-Apps kostenlos | | ⬜ | N/A |
| 3.2.1(vi) Spenden via Apple Pay | | ⚠️ Phase 3+ | Falls Charity-Komponente (Bäume pflanzen pro Score) |
| **3.2.2(x) Keine erzwungene Bewertung** | Nur Standard-API für Rezensions-Prompt | 🔴 | Wenn wir `SKStoreReviewController` nutzen — kein Custom-Modal → R-AS-14 |

## Sektion 4 — Design

| Punkt | Inhalt | Relevanz | Begründung / Defense |
|---|---|---|---|
| 4.1 Nachahmer und Marken | | 🔴 | Marken-, Icon- und Namensrechte werden in G-AS-METADATA hybrid geprueft; 4.1(c) beachten |
| 4.2 Mindestfunktionalität | Mehr als Web-Wrapper | 🔴 | Release-Evidenz fuer nutzbaren Scanner- und Ergebnis-Flow in G-AS-REVIEW-READINESS |
| 4.3 Spam und Mindestqualitaet | | 🔴 | Juni-2026-Praezisierung wird vor Submission manuell geprueft |
| 4.5 Apple Websites/Dienste | Keine Apple-Spam | ✅ | Wir kontaktieren keine Apple-User außerhalb |
| **4.5.3 Push für Spam verboten** | | ⚠️ Phase 2 | Wenn Push-Notifications → kein Marketing-Spam |
| **4.5.4 Push nur mit Consent** | Nicht für sensitive Daten | ⚠️ Phase 2 | G-AS-PUSH-CONSENT |
| 4.6 — | (Absichtlich ausgelassen von Apple) | — | |
| **4.7 Mini-Apps/Chatbots** | Software, die nicht im Binary enthalten ist | ⚠️ Bedingt | Vor Aktivierung eines serverseitig bereitgestellten Chatbots ist die konkrete Architektur erneut gegen 4.7 zu klassifizieren |
| 4.7.5 Alters-Mechanismus für Chatbot | | ⚠️ Phase 2 | KI-Chat: User-Alter prüfen |
| **4.8 Gleichwertige Login-Option** bei Drittanbieter-/Social-Login | | ⚠️ Bedingt | Apple verlangt eine gleichwertige datenschutzfreundliche Login-Option, soweit keine Ausnahme greift; nicht pauschal nur einen bestimmten Button |
| 4.9 Apple Pay | | ⬜ | Wir nutzen kein Apple Pay |
| 4.10 Apple-Funktionen nicht monetarisieren | Kamera/Push-Mitteilungen | ✅ | Wir monetarisieren KI-Features, nicht Hardware |

## Sektion 5 — Rechtliche Hinweise (kritisch!)

| Punkt | Inhalt | Relevanz | Begründung / Defense |
|---|---|---|---|
| **5.1.1(i) Privacy Policy Link** | In App + App Store Connect | 🔴 | R-AS-01 + G-AS-PRIVACY |
| **5.1.1(ii) Consent für Erfassung** | DSGVO + Apple | 🔴 | Bei jedem Tracking-Pixel/SDK → R-AS-02 |
| **5.1.1(iii) Datensparsamkeit** | Nur was nötig | 🔴 | Kein Standort, kein Adressbuch — wir brauchen nur Kamera → R-AS-04 |
| 5.1.1(iv) Permissions respektieren | Keine Manipulation | ✅ | Selbstverständlich |
| **5.1.1(v) Account-Löschung** | Wenn Account-Anmeldung | 🔴 | Mit Supabase Auth → Implementierung in Phase 1 → R-AS-05 |
| 5.1.1(vi) Verdeckte Daten-Erfassung verboten | | ✅ | Selbstverständlich |
| 5.1.1(vii) SafariViewController nicht zur Nachverfolgung | | ✅ | Wir nutzen das nicht |
| **5.1.1(viii) Personeninformationen aus Quellen zusammenstellen** | | ⬜ aktuell | OFF-Produktdaten sind nicht allein wegen ihrer Oeffentlichkeit personenbezogen; OFF-Rechte laufen ueber 5.2.2 und Lizenzrecht |
| 5.1.1(ix) Stark regulierte Bereiche | Bank, Gesundheit, Glücksspiel | ⬜ | ESG-Bewertung ist nicht stark reguliert |
| 5.1.1(x) Kontaktdaten optional | | ✅ | Wir fragen nichts ab |
| **5.1.2(i) ATT (App Tracking Transparency)** | Bei jedem Tracking | 🔴 | Falls Analytics-SDK → ATT-Prompt → R-AS-07 |
| 5.1.2(ii) Datennutzung nur für ursprünglichen Zweck | | ✅ | Wir nutzen Scans nicht für Marketing |
| 5.1.2(iii) Keine Profil-Rekonstruktion aus „anonymen" Daten | | ✅ | Wir sammeln keine Pseudo-Anonymisierten |
| **5.1.2(vi) Health/ARKit/ClassKit-Daten nicht für Marketing** | | ✅ | Wir nutzen nichts davon |
| 5.1.3 Gesundheits-Apps | Spezielle Regeln | ⬜ | Wir sind keine Health-App |
| 5.1.4 Kinder-Apps | Spezielle Regeln | ⬜ | Wir sind keine Kinder-App |
| **5.1.5 Ortungsdienste** | Zweck + Consent | ⚠️ Phase 2+ | Wenn wir „regionaler Score" einbauen → R-AS-15 |
| **5.2 Geistiges Eigentum** | OFF-Lizenz CC BY-SA | 🔴 | Erlaubnis dokumentieren (Apple kann fragen) → R-AS-16 |
| **5.2.2 Drittanbieter-Nutzungsbedingungen** | OFF-Lizenz-Doku | 🔴 | CC BY-SA Attribution-Pflicht in App → siehe R-AS-16 |
| 5.2.5 Apple-Produkte nicht imitieren | | ✅ | Wir bauen keine Apple-Klon-UI |
| 5.4 VPN-Apps | | ⬜ | N/A |
| 5.5 Mobile Geräteverwaltung | | ⬜ | N/A |
| 5.6.1 Rezensionen | API für Bewertungs-Prompt | 🔴 | Verbindet sich mit 3.2.2(x) — R-AS-14 |
| 5.6.4 App-Qualität | | ✅ | Quality-Strategy + Coverage-Gates |

---

## Zusammenfassung - Requirements fuer ScanFair MVP

Die 16 urspruenglichen Anforderungen R-AS-01 bis R-AS-16 sind als YAML
materialisiert. R-AS-27 ergaenzt die fuer ScanFair besonders relevante
Wahrheits- und Nachvollziehbarkeitskontrolle der ESG-Aussagen. R-AS-28 stellt
sicher, dass spaetere Hochrisiko-Features ihre bedingten Regeln aktivieren.
R-AS-29 fuehrt Apple HIG und Accessibility bewusst als SHOULD-Evidenz.

| R-AS-ID | Titel | Apple-Ref | Gate-ID (geplant) | Phase |
|---|---|---|---|---|
| **R-AS-01/02/04/05/07/15** | Privacy, Consent und bedingte Datenkontrollen | 5.1 | G-AS-PRIVACY | 1/bedingt |
| **R-AS-03** | Kamera-Purpose und Laufzeitverhalten | 2.5.14 | G-AS-CAMERA | 1 |
| **R-AS-06/16** | OFF- und Drittanbieter-Rechte | 5.2.2 | G-AS-THIRD-PARTY-RIGHTS | 1 |
| **R-AS-08** | Support und Anbieteridentitaet | 1.5 | G-AS-SUPPORT-IDENTITY | 1 |
| **R-AS-09/13/14** | Review-, Device- und Netzwerkbereitschaft | 2.1, 2.5.5 | G-AS-REVIEW-READINESS | 1/bedingt |
| **R-AS-10/11/12** | Store-Metadaten, Screenshots und Altersrating | 2.3 | G-AS-METADATA | 1 |
| **R-AS-27** | Nachweisbare ESG-Aussagen | 1.1.6, 2.3.1 | G-AS-CLAIMS-TRANSPARENCY | 1 |
| **R-AS-28** | Re-Klassifikation bei IAP, Login, AI, Chatbot, UGC oder Push | 1.2, 3.1, 4.5, 4.7, 4.8, 5.1.2(i) | G-AS-PRIVACY, G-AS-REVIEW-READINESS | bedingt |
| **R-AS-29** | HIG- und Accessibility-Review | Apple HIG | G-AS-REVIEW-READINESS | 1 (SHOULD) |

## Phase-2-Add-Ons (mit ScanFair+ Membership + KI-Chat)

| R-AS-ID | Titel | Apple-Ref |
|---|---|---|
| R-AS-17 | IAP-Pflicht für KI-Features | 3.1.1 |
| R-AS-18 | Subscription ≥ 7 Tage Laufzeit | 3.1.2(a) |
| R-AS-19 | Subscription-Info-Transparenz | 3.1.2(c) |
| R-AS-20 bis R-AS-24 | Architekturabhaengige Chatbot-/4.7-Kontrollen | 4.7.1-4.7.5 |
| R-AS-25 | Gleichwertige datenschutzfreundliche Login-Option | 4.8 |
| R-AS-26 | Push-Notifications nur mit Consent | 4.5.3, 4.5.4 |
| R-AS-28 | Aktivierungs-Guard inkl. Drittanbieter-AI-Datenweitergabe | 1.2, 3.1, 4.5, 4.7, 4.8, 5.1.2(i) |

## Methodisch — wie die Anforderungen in unser System fließen

```
Apple App Review Guideline (PDF)
        │
        ▼
docs/project/compliance/apple-review-relevance.md  ◄── DIESE DATEI
        │ extrahiert
        ▼
docs/project/requirements/R-AS-NN.yaml             ◄── eine pro Anforderung
        │ verlinkt sich mit
        ▼
docs/project/gate-definitions/apple/G-AS-NAME.yaml ◄── 7-Attribute-Template
        │ implementiert durch
        ▼
docs/project/policies/apple/policy_NAME.rego       ◄── deny-Rules
        │ + Tests in
        ▼
docs/project/policies/apple/policy_NAME_test.rego  ◄── Unit-Tests
        │ executiert via
        ▼
.github/workflows/quality-gates.yml (Conftest)     ◄── CI/CT-Pipeline
        │ schreibt
        ▼
evidence-store/evidence-log.jsonl                  ◄── Audit-Trail
```

## Wartung

- `source-register.yaml` mindestens zum dort gesetzten Faelligkeitsdatum und vor jeder Submission pruefen
- Bei Apple-Aenderungsmitteilung Delta-Analyse sofort durchfuehren
- Bei neuer Phase: deferred R-AS aktivieren
- Bei Reject im App Review: failure-mode dokumentieren + ggf. neue R-AS
