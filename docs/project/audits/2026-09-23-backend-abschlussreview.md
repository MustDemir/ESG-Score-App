# Technischer Abschlussreview – TKT-037-05

Datum: 2026-09-23. Basis: `2225788d811e4ffca5b57a1c052aee49258e850a`
mit den im Arbeitsbaum vorliegenden Kontroll- und Backend-Aenderungen.
Remote-main `42829b0` hat denselben Dateibaum; dessen zusaetzlicher Commit ist
der Merge des bisherigen Dokumentationsbranches.

## Entscheidung

Die Reparatur ist fuer den **lokalen Development-Scope technisch reviewt**.
In diesem getrennten zweiten Pruefdurchgang wurde kein neuer blockierender
Befund in der reparierten Request-Kette festgestellt. Dies ist ein erneuter
Review durch denselben Codex-Assistenten, **keine personell unabhaengige
Pruefung oder externe Sicherheitszertifizierung**. GitHub- und Post-Merge-
Nachweise bleiben offen; die Remote-Aktivierung bleibt gesperrt.

## Kontrollpunkte und Belege

| Befund | Gegenpruefung der Reparatur |
|---|---|
| AR-04: Request-Rollen | Migration 15:115 erteilt Hook-EXECUTE fuer die tatsaechlichen Rollen; direkte Tabellenrechte bleiben entzogen. SQL und HTTP testen beide Lesererollen sowie erfolgreichen service_role-Writer. |
| AR-05: reale Pfade | Migration 15:19–48 behandelt `/rpc/`, mehrdeutige Pfade und direkten Hook-Aufruf. HTTP testet auch vom Gateway normalisierte Varianten bei ausgeschoepfter Quote. |
| AR-06: Transaktion | Migration 15:121 stellt drei Read-RPCs auf VOLATILE. Der Counter wird im echten POST-Pfad persistiert; READ-ONLY-Negativfall ist im Verifier enthalten. |
| AR-09: Header-Spoofing | Migration 15:61 wertet nur den vom letzten vertrauten Ingress gelieferten Peer aus. Manipulierte Praefixe bleiben im selben lokalen Kontingent. Die Hosted-Kette ist ausdruecklich nicht freigegeben. |
| AR-10: Fehlervertrag | Migration 15:27,38,55,77,88,107 liefert das obligatorische Header-Objekt. HTTP prueft 403/405/429 statt versehentlicher 500-Antworten. |
| CI-Durchsetzung | `.github/workflows/quality-gates.yml:293` bindet Replay, SQL und beide HTTP-Suites seriell ein; explizites Bash-pipefail schuetzt die protokollierten Testergebnisse. Kein continue-on-error. |

## Neu ausgefuehrte Pruefungen

- Isoliertes Testprojekt `scanfair-http-review-20260923` aus seiner lokalen
  Sicherung gestartet, ohne vorhandene oder entfernte Datenbanken zu resetten.
- pgTAP: **303/303 PASS**, DB-Lint ohne Schemafehler.
- Echte Gateway-/PostgREST-Suite: **292 Assertions PASS**.
- Echter Deno-Handler mit exakt synthetischer OFF-Antwort: Publication 201,
  Replay 200, anonymer Read 200; Auth-/Schema-Negativfaelle und Cleanup PASS.
- Backend-Gate-Selbsttests: **22 Assertions PASS**.
- PR-Ticket-Bindung: **9 Tests / 27 Assertions PASS**.
- Sieben Tickets schema- und workflow-konsistent.

Der schon dokumentierte 15-Migrationen-Neuaufbau und weitere Grenzen stehen
im [HTTP-Nachweis](2026-09-23-public-read-http-validation.md). Dieser Review
behauptet keinen neuen Hosted-Test oder Live-OFF-Test.

## Gebundener Implementierungsstand

SHA-256 der separat gelesenen und erneut ausgefuehrten Artefakte:

```text
67ed64cce4662a2038a25063fc85925a4ec2b9d3bb5b158dc35656cdd4440e6e  supabase/migrations/20260923000100_public_read_api_integration.sql
d3889ebb441916ef19556ee3d4b1140bf15e6f92ab9dcd407b9f854b536c71fb  scripts/quality/test_public_read_http.mjs
6a5652d4b0db54bf945df10ce41918648890140e28fbd39bd551b68c42943ed6  scripts/quality/test_edge_writer_http.mjs
```

## Verbleibende Grenzen

1. Hosted-Proxy-Kette, Client-Zuordnung und Gateway-Konfiguration muessen vor
   Aktivierung separat nachgewiesen werden; lokales PASS ist nicht uebertragbar.
2. Das ungeschluesselte IP-Pseudonym und tatsaechliche Loeschverzoegerungen
   bleiben Gegenstand der qualifizierten Privacy-Entscheidung.
3. Die Fixtures setzen eine exklusiv genutzte Wegwerf-Testinstanz voraus.
   Die HTTP-Suites sind keine Werkzeuge fuer bestehende Benutzer-Datenbanken.
4. Belastungs-/Mehrinstanztests und externer Alarmversand sind nicht durch
   diese kleinen Funktions- und Grenzwerttests abgedeckt.
5. PR-/Post-Merge-CI und menschliche fachliche Freigaben bleiben unveraendert
   offen. Das Ticket ist deshalb noch nicht done.

Der Skill `security-best-practices` wurde fuer Risikopriorisierung und
Negativpruefungen verwendet. Fuer PostgREST/Deno gibt es im Skill keinen
passenden Spezialleitfaden; die konkreten Belege stammen aus Code und Tests.

## Gezielte CI-Nacharbeit vor dem Backend-Merge

Im aufbauenden Cache-Branch scheiterte Lauf
[35829050967](https://github.com/MustDemir/ESG-Score-App/actions/runs/35829050967)
an der bereits hier vorhandenen SQL-Fixture `stale_serving_window.test.sql`:
Zwei `clock_timestamp()`-Aufrufe ergaben sieben Tage plus eine Mikrosekunde.
Der Constraint `cached_products_ttl_bound_check` reagierte korrekt.

Die freigegebene Testkorrektur aus `b4ba6f9` wird deshalb vor einem Merge
auch im Backend-PR bereitgestellt. Die SQL-Datei ist bytegleich mit der
lokal geprueften Fassung: stabiler Transaktionszeitpunkt, explizite Annahme
von genau sieben Tagen und Ablehnung von sieben Tagen plus einer Mikrosekunde
mit SQLSTATE `23514` und namentlich geprueftem Constraint. Migrationen und
Produktionslogik bleiben unveraendert.

Die identische SQL-Suite bestand auf der isolierten Instanz
`scanfair-http-review-20260923` mit **305/305 Tests**, gezielt **7/7** und
zehn weiteren erfolgreichen Wiederholungen. Strikter DB-Lint war fehlerfrei;
keine Fixture-Zeile blieb zurueck. Die Testinstanz wurde mit Backup gestoppt.
Die regulaere lokale und die entfernte Datenbank wurden nicht veraendert.

Das ist eine begrenzte CI-Nacharbeit unter TKT-037-05, kein neuer Gesamtreview.
Die frueheren gruenen PR-Ergebnisse gelten fuer `f33f758`; der neue Backend-
Commit benoetigt seinen eigenen GitHub-Nachweis. Merge-Freigabe und
Post-Merge-Pruefung bleiben ausstehend.

## Nacharbeit aus dem blockierenden PR-Review

Nach der Umstellung von PR #35 auf „ready for review“ meldeten Codex Review
und Copilot sieben offene Threads. Die Repository-Regel verlangt deren
Aufloesung; ein Admin-Bypass wurde nicht verwendet.

| Thread | Korrektur und lokaler Nachweis |
| --- | --- |
| Quellenreview gegen frischen Lauf | Die Signatur bindet weiterhin den konkreten beobachteten Zustand. Die Zeitreihenfolge wird nun gegen `observation_generated_at` des zugehoerigen Review-Eintrags geprueft, nicht gegen die Erzeugungszeit jedes spaeteren identischen CI-Laufs. Ein spaeter identischer Lauf bleibt akzeptiert; Review vor Beobachtung scheitert. |
| Self-Test-Fehler wurde verschluckt | Der Horizon-Runner kehrt nach jedem fehlgeschlagenen Selbsttest sofort mit Fehler zurueck. Ein kontrollierter Negativlauf bestaetigte, dass der Profilvalidator danach nicht mehr ausgefuehrt wird. |
| Terminales Ticket `done` war PR-faehig | `done` wurde aus den reviewbaren Zustaenden entfernt. Ein neuer Negativtest blockiert die PR-Bindung an ein abgeschlossenes Ticket. |
| Umbenannter Canonical-Zaehler | Die GitHub-Zusammenfassung liest jetzt `canonical_v2` und `canonical_v1_compatible`. Der Selbsttest prueft beide Konsumenten und verbietet den entfernten Schluessel. |
| README Englisch | Aktuelle Baseline: 15 Migrationen und 305/305 pgTAP. |
| README Deutsch | Aktuelle Baseline: 15 Migrationen und 305/305 pgTAP. |
| Engineering-Handbuch | PostgreSQL-Baseline auf 305/305 samt Frischegrenztest aktualisiert. |

Gezielte lokale Ergebnisse: Horizon **30 Assertions PASS**,
Quellenbeobachtung **12 Assertions PASS**, PR-Ticketbindung
**10 Tests / 29 Assertions PASS**, Ticketkontrolle **22 Tests / 58 Assertions
PASS**, Gate-Definitionen **17 Assertions PASS**. Projektkontrolle,
Dokumentationsverweise, Bash-Syntax und 150 YAML-Dateien bestanden. Der
vollstaendige Development-Runner bestand danach mit **33/33 Gates**. Ein
erster Sandbox-Lauf war wegen fehlender Schreibrechte am installierten
Flutter-SDK-Cache und gesperrter OSV-Netzwerkauflösung technisch unvollstaendig;
derselbe Runner lief mit den benoetigten lokalen Zugriffsrechten vollstaendig
gruen. Der neue Commit bestand anschliessend den frischen GitHub-PR-Lauf;
alle sieben Threads wurden mit den konkreten Nachweisen beantwortet.

## PR- und Post-Merge-Abschluss

PR #35 wurde nach erfolgreichem Lauf
[35837738124](https://github.com/MustDemir/ESG-Score-App/actions/runs/35837738124),
beantworteten sieben Review-Threads und ohne Admin-Bypass als Merge-Commit
`65b9463cef4657153ae4fbc4b78a99f96497fb0c` in `main` uebernommen.

Der erste Versuch des Post-Merge-Laufs
[35838485511](https://github.com/MustDemir/ESG-Score-App/actions/runs/35838485511)
traf vor den pgTAP-Tests einen belegten Portkonflikt beim ungenutzten lokalen
Mail-Testdienst (`54324`). Migrationen waren angewandt, aber die Supabase-
Testcontainer konnten deshalb nicht vollstaendig starten. Die anderen fuenf
anwendbaren Jobs bestanden. Der gezielte zweite Versuch auf einem frischen
Runner bestand Datenbank-Neuaufbau, **305/305 pgTAP**, DB-Lint, Writer- und
beide realen HTTP-Suites. Damit sind alle sechs anwendbaren Post-Merge-Jobs
erfolgreich. Keine Remote-Datenbank wurde dabei angesprochen oder veraendert.
