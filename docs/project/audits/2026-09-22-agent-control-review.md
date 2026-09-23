# Agent- und Kontrollreview

- Datum / Normalisierung: 2026-09-22
- Ticket der Workflow-Nacharbeit: TKT-040-01 / TODO-040
- Basis: Branch `docs/project-status-2026-08-31`, HEAD `2225788`, einschliesslich uncommitted Working-Tree-Aenderungen.
- Methode: drei getrennte lesende Agent-Reviews (Ticket/CI, PostgREST/Writer, Flutter-Cache), Gegenpruefung und Regressionstests durch den Hauptagent.
- Grenzen: kein vollstaendiger Systemaudit, keine externe Fachpruefung, kein Pentest, keine Remote-Mutation. SQL-/HTTP-Laufzeittest in dieser Session nicht ausgefuehrt: Docker-Daemon nicht aktiv.
- Skill: Security Best Practices beeinflusst Priorisierung, Belegpflicht und sicheren Scope. Fuer Dart, Ruby und PostgREST/Deno enthaelt dessen Referenzbestand keine unmittelbar passenden Framework-Anleitungen; diese Befunde beruhen auf Repository- und Upstream-Code.

## Ergebnis

Nachtrag 23.09.: [Lokaler HTTP-Nachweis und Reparatur](2026-09-23-public-read-http-validation.md)
schliessen AR-04 bis AR-06 technisch lokal und ergaenzen AR-09/10 zu
Header-Spoofing und Fehlerformat. Separater Review, echte PR-/Post-Merge-CI
und Hosted-Pruefung bleiben offen. Die folgenden Ausgangsbefunde und die
damalige Docker-Einschraenkung dokumentieren den Stand vom 22.09.

Die vorhandenen Gates decken viele bekannte Regeln ab, beweisen aber keine
Fehlerfreiheit der Regeln oder der gesamten Laufzeitintegration. Der Review
fand drei Fehler in der Ticket-/CI-Kontrolle, drei zusammenhaengende
PostgREST-Integrationsprobleme und zwei Cache-Frischefehler. Die
Workflow-Korrekturen werden in TKT-040-01 bearbeitet. Die Produktkorrekturen
besitzen eigene Tickets mit DoR, Akzeptanzkriterien und DoD.

## Befunde

| ID | Prioritaet | Befund | Beleg / Ausgangszeilen | Behandlung |
|---|---|---|---|---|
| AR-01 | P1 | `not_applicable` ohne Begruendung/Evidenz und beliebige Abschlussnachweise konnten Privacy-Ticket auf done setzen | `scripts/quality/validate_tickets.rb`, urspruenglich 186–206, 229–232; Katalogmutation im Speicher ergab PASS | TKT-040-01: N/A-Begruendung, Owner und Evidenz sowie nicht ausnehmbare Kriterien; lokale Abschlussdateien pruefen |
| AR-02 | P1 | Selbsttest pruefte aktuelle Ticketdateien gegen festes Datum 2026-09-11; regulaeres Update vom 22.09. scheiterte | `scripts/quality/test_ticket_gate.rb`, urspruenglich 14 und 109 | TKT-040-01: heutiges Datum fuer Live-Katalog, eigener Zukunftsdatums-Negativtest |
| AR-03 | P2 | PR-Body-Aenderungen starteten keine erneute Ticket-Bindung; Pfadfilter schlossen manche PRs aus | `.github/workflows/quality-gates.yml`, urspruenglich 16–26; `validate_pr_ticket_binding.rb:27` liest Event-Body | TKT-040-01: edited-Trigger und alle PR-Pfade; statischer Regressionstest; echter GitHub-Nachweis bleibt offen |
| AR-04 | P1 | Pre-request-Hook entzieht den tatsaechlichen Request-Rollen EXECUTE, wodurch Data-API-Aufrufe scheitern koennen | `supabase/migrations/20260906000100_public_read_abuse_protection.sql:175`; pgTAP bestaetigt die falschen Grants bei Zeile 42 | Offen: TKT-037-05; dynamischer Rollentest erforderlich |
| AR-05 | P1 | Hook vergleicht `rpc/...`; PostgREST setzt einen HTTP-Pfad mit fuehrendem Slash. Nach Grant-Korrektur wird der Schutz uebersprungen | gleiche Migration:73; `scripts/quality/verify_public_read_abuse_protection.sql:39` simuliert denselben falschen Pfad | Offen: TKT-037-05; alle realen HTTP-Routen und Pfadvarianten testen |
| AR-06 | P1 | Hook schreibt Zaehler, Ziel-RPCs sind STABLE und laufen bei PostgREST auch per POST in READ ONLY | Migration:145; `20260813000200_stale_serving_window.sql:74`; `20260817000100_backend_remote_readiness.sql:54,115` | Offen: TKT-037-05; Transaktionsmodus und Schreibbedarf gemeinsam reparieren |
| AR-07 | P2 | Fehlendes/ungueltiges stale_after wird als frischer Cache gewertet | `esg_app/lib/services/supabase_product_cache_service.dart:220,248` | Offen: TKT-038-01; Client-Vertragsbruch-Negativtests |
| AR-08 | P2 | Waehrend OFF-Fallback abgelaufenes Cacheprodukt wird trotzdem staleServed | `esg_app/lib/services/product_repository.dart:154`; Lookup verliert expires_at | Offen: TKT-038-01; Fake-Uhr-Test an der harten Ablaufgrenze |

AR-01 beschreibt eine Umgehung der Ticketkontrolle; ein Bypass aller separaten
Privacy-/Backend-Gates wurde damit nicht bewiesen. Pfad-/Existenzpruefungen
beweisen weder Inhalt noch menschliche Qualifikation. HTTPS-Evidenzlinks werden
syntaktisch geprueft, nicht abgerufen oder als authentische Freigabe attestiert.

AR-04 bis AR-06 sind statisch gegen PostgREST v14.15 geprueft. Die lokal
zwischengespeicherte Versionsdatei nennt diese Version; eine laufende Instanz
wurde nicht verifiziert. Die Fehler maskieren einander: erst Rechte, dann
Pfadvergleich, dann Transaktionsmodus. Der neue Test muss alle drei zusammen
und ueber HTTP pruefen. Quellen:

- [Request-Pfad, PostgREST v14.15](https://github.com/PostgREST/postgrest/blob/v14.15/src/PostgREST/ApiRequest.hs)
- [Rollenwechsel vor Pre-request](https://github.com/PostgREST/postgrest/blob/v14.15/src/PostgREST/Query/PreQuery.hs)
- [POST/STABLE-Transaktionsmodus](https://github.com/PostgREST/postgrest/blob/v14.15/src/PostgREST/Plan.hs)

AR-07 tritt bei Vertrags-/Schemaabweichungen auf; das regulaere DB-Schema
verlangt stale_after bereits. AR-08 betrifft das zeitliche Fenster waehrend
eines fehlgeschlagenen Fallbacks. Beide sind codebasierte Befunde; neue
dynamische Reproduktionen gehoeren zur DoD des Reparaturtickets.

## Korrektur bisheriger Aussagen

- Die historische Aussage 277/277 pgTAP PASS ist SQL-Testevidenz. Sie beweist
  nicht, dass Migration 14 unter echten PostgREST-Rollen, Pfaden und
  Transaktionsbedingungen funktioniert.
- Ein Ablaufzeitpunkt nach einer Stunde garantiert keine physische Loeschung
  binnen einer Stunde. Der Fuenf-Minuten-Cron, das Batchlimit von 10.000 Zeilen
  und Jobausfaelle beeinflussen die tatsaechliche Verweildauer.
- Der SHA-256-Hash mit oeffentlichem konstantem Praefix erlaubt Offline-Pruefung
  von IP-Kandidaten und Verknuepfung ueber Zeitfenster. Diese Eigenschaft und
  das bisher nicht dynamisch gepruefte Vertrauen in X-Forwarded-For muessen
  Bestandteil der technischen Privacy-Unterlagen sein.
- Die fruehere Einschaetzung, es fehlten hauptsaechlich Freigaben und zwei
  Remote-Schritte, ist durch AR-04 bis AR-08 ueberholt. Die bestehenden
  Prozentwerte sind historische Planungsschaetzungen, kein Abstandsmass zur
  Backend-Aktivierung.

## Technisch noch nachzuweisen

1. Reparatur und echter HTTP-Integrationstest des Read-Abuse-Schutzes (TKT-037-05).
2. Cache-Frische-Negativtests und Reparatur (TKT-038-01).
3. Aktueller DB-Replay, RLS/pgTAP, Lint und erfolgreicher Writer-Read-Pfad auf einer gesicherten oder isolierten lokalen Instanz.
4. Reale GitHub-PR-Bindung inklusive Body-Edit sowie Post-Merge-Lauf (TKT-040-01).
5. Nach Privacy-Entscheidung kontrollierte Remote-Migration und Remote-Verifier (TKT-037-02/03).
6. Externer Failure-, Recovery- und Zustellfehler-Drill (TKT-037-04).
7. Flutter-End-to-End gegen freigegebenes Development-Backend, Secret-Rotation/Incident-Drill sowie benoetigte Provider-/Lizenz-/Security-Nachweise vor Aktivierung.

## Pruefstand dieser Session

Die lokalen Remote-Profil-Validatoren wurden ohne Remote-Verbindung erneut
ausgefuehrt: Backend, Privacy und Datenlizenz bleiben erwartungsgemaess FAIL.
Unter anderem fehlen Review-Evidenz, Privacy-Angaben, Share-Alike-Export und
Korrektur-/Loeschprozess. Kein Status wurde zur Umgehung dieser Grenzen geaendert.

Die konkreten Abschlussresultate der Workflow-Regressionssuite und des lokalen
Development-Runners werden im Session-Handoff dokumentiert. Ein gruenes
Development-Ergebnis schliesst die offenen AR-04 bis AR-08 nicht.
