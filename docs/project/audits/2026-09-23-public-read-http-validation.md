# TKT-037-05 – lokaler HTTP-Wirksamkeitsnachweis

Datum: 2026-09-23. Basis: `2225788d811e4ffca5b57a1c052aee49258e850a`
plus uncommitted Working Tree. Kein Remote-Deployment, keine Privacy-Freigabe.

## Befunde und Korrektur

Der Agent-Review vom 22.09. fand AR-04 (Hook-Rechte), AR-05 (Pfadvergleich)
und AR-06 (READ ONLY trotz schreibendem Zaehler). Der reale lokale HTTP-Aufruf
gegen Migration 14 bestaetigte HTTP 401 / SQLSTATE 42501 beim Hook.
Migration 15 korrigiert Request-Rollen, `/rpc/`-Pfade und VOLATILE fuer die
drei geschuetzten POST-RPCs, ohne historische Migration 14 zu veraendern.

Zwei weitere dynamische Befunde wurden in demselben Ticket behoben:

- **AR-09 / P1:** Auswertung des ersten X-Forwarded-For-Eintrags erlaubte auf
  lokalem Kong verschiedene Zaehler durch vom Aufrufer gesetzte Praefixe.
  Nach der ersten Integrationskorrektur ergaben drei HTTP-Anfragen mit
  veraenderten Praefixen drei Buckets. Jetzt wird der vom letzten vertrauten
  Ingress angehaengte Peer ausgewertet. HTTP-Regressionspruefungen erzwingen
  dieselbe Quote trotz Praefixwechsel. Dies gilt nur fuer die gepruefte
  lokale Ingress-Kette; Hosted-Verifikation bleibt blockierende Voraussetzung.
- **AR-10 / P2:** PGRST-Fehlerdetails ohne obligatorisches `headers`-Objekt
  ergaben HTTP 500/PGRST121 statt 403/405. Migration 15 liefert gueltige
  Fehlerdetails; GET und direkter Hook-Aufruf werden jetzt korrekt abgewiesen.

Kong normalisiert kodierte Zeichen und doppelte Slashes teilweise vor
PostgREST. Deshalb prueft der HTTP-Test nicht pauschal Ablehnung: Ein
normalisierter erlaubter Aufruf muss den gleichen Zaehler erhoehen und bei
erschoepfter Quote ebenfalls scheitern. Im Hook sichtbare mehrdeutige Pfade
werden abgewiesen. SQL-Tests decken beide Pfadzustaende getrennt ab.

## Isolierte Laufzeit

- Testprojekt: `scanfair-http-review-20260923`; API-Port 55321, DB-Port 55322.
- CLI 2.110.0; Kong 2.8.1; PostgREST v14.15; PostgreSQL-Image 17.6.1.143.
- Bestehendes Projekt `scanfair-local` wurde weder zurueckgesetzt noch migriert.
- Vollstaendiger Neuaufbau erfolgte ausschliesslich in der neu angelegten
  temporaeren Testinstanz; danach wurden beide HTTP-Suites erneut ausgefuehrt.
- Keine echten Produkte oder Nutzer-Fixtures. Barcodes `99999999999991` und
  `99999999999992`; Tests verweigern vorbestehende Produkt-Fixtures.
- Schluessel werden nur lokal eingelesen und nicht in Testberichten ausgegeben.

## Ausgefuehrte Ergebnisse

| Pruefung | Ergebnis |
|---|---|
| Forward-only Replay aller Migrationen | 15/15 PASS |
| pgTAP, neun Testdateien | 303/303 PASS |
| Public-Read-pgTAP darin enthalten | 53/53 PASS |
| Datenbank-Lint, Stufe warning | PASS, keine Schemafehler |
| Rollback-Verifier unter echten SQL-Rollen | PASS; READ ONLY negativ, READ WRITE positiv |
| Gateway-/PostgREST-HTTP-Suite | 292 Assertions PASS |
| Vollstaendiger Edge-Handler mit synthetischer OFF-Antwort | PASS |
| Backend-Kontrollselbsttests | 22 Assertions PASS |
| Vollstaendige lokale Development-Pruefkette | 33/33 Gates PASS |

Die HTTP-Suite testet anon/authenticated, alle drei RPCs, 30 erlaubte und
den 31. abgewiesenen Aufruf, HTTP 429/Retry-After, persistierten Zaehler 30,
gemeinsame Quote ueber Rollen und Routen, Pfadvarianten, gefaelschte
Weiterleitungs-Praefixe, Tabellenzugriffsverbot sowie service_role-Publikation
und anschliessenden anonymen Read. Fehlende/ungueltige Identitaet wird im
SQL-Hook getestet: Der lokale Gateway selbst ergaenzt bei HTTP seinen Peer.

Die zweite Suite importiert den unveraenderten produktiven Deno-Handler.
Nur die exakte externe OFF-Produktantwort wird durch eine kuenstliche Antwort
ersetzt; unerwartete externe Netzwerkziele werden blockiert. SQL/RPC-Aufrufe
laufen real. Nachgewiesen: falsches Secret 401, falscher Actor 401, falsches
Schema 400, HTTP-Envelope 200 mit Publication 201, identischer Replay 200 /
`duplicate_existing`, anonymer Read 200 sowie zwei passende Audit-Eintraege.
Das ist kein Nachweis der Live-Verfuegbarkeit von Open Food Facts.

Alle produktbezogenen Test-Fixtures wurden entfernt und mit Nullzaehlung
geprueft. Der SQL-Verifier rollt zurueck. Die HTTP-Suites entfernen ihre
Rate-Fixtures bzw. stellen die erfassten Testzaehler typgerecht wieder her.
Die abschliessende Nachkontrolle ergab jeweils null synthetische Produkt-
und Audit-Zeilen sowie null Public-/Writer-Rate- und Tageszaehler. Danach
wurde ausschliesslich die isolierte Testinstanz gestoppt; ihre lokale
Volumesicherung blieb erhalten. Das bestehende Projekt blieb unberuehrt.
Ein erster Edge-Test scheiterte noch an der Timestamp-Formatierung seiner
Bereinigung; dies wurde im Test behoben und anschliessend der gesamte
disposable Datenbankstand neu aufgebaut und beide Suites erfolgreich wiederholt.

## Retention und Privacy: konkrete Grenzen

`expires_at` liegt eine Stunde nach Fensterbeginn. Das beendet nicht von
selbst die physische Speicherung. Der Cleanup laeuft alle fuenf Minuten und
entfernt maximal 10.000 abgelaufene Zeilen je Lauf. SQL-Grenztests zeigen:
vor Ablauf keine Loeschung; am Ablauf maximal 10.000 von 10.001 Zeilen;
Restzeile erst im Folgelauf. Zukunftsuhr ausserhalb der Toleranz wird abgewiesen.

Bei gesundem Scheduler ohne Rueckstau erfolgt die Loeschung beim naechsten
Lauf. Bei Rueckstau oder ausgefallenem Cron existiert derzeit keine garantierte
maximale physische Verweildauer. Es wird weder eine Ein-Stunden-Loeschgarantie
noch eine bereits vorhandene besondere Backlog-Alarmierung behauptet.

Das gespeicherte SHA-256-Pseudonym ist ungesalzen bzw. nicht geheim geschluesselt;
der konstante Praefix verhindert keine Offline-Pruefung von IP-Kandidaten oder
Verknuepfung ueber Zeitfenster. Die Privacy-Entscheidung muss diese Eigenschaften,
den Zweck, Zugriff, Loeschverzoegerungen und moegliche Verbesserungen bewerten.
Die technische Dokumentation erteilt keine rechtliche Freigabe.

## Reproduktion und CI

Auf einer neu angelegten, isolierten lokalen Supabase-Instanz mit kopierten
Repository-Migrationen, Tests und Functions:

```text
supabase db reset --local --workdir <isolierte-testinstanz>
supabase test db --local --workdir <isolierte-testinstanz>
supabase db lint --local --level warning --workdir <isolierte-testinstanz>
node scripts/quality/test_public_read_http.mjs --workdir <isolierte-testinstanz>
node scripts/quality/test_edge_writer_http.mjs --workdir <isolierte-testinstanz>
```

`scripts/quality/verify_public_read_abuse_protection.sql` wurde ueber psql
mit `ON_ERROR_STOP=1` gegen genau diese Instanz ausgefuehrt. Die neuen HTTP-Tests
sind im bestehenden CI-Datenbankjob nach Replay/pgTAP und dem bisherigen
Edge-Negativtest eingebunden. Explizites Bash-pipefail verhindert, dass die
Protokollierung einen Testfehler verschluckt. GitHub-Ausfuehrung und Post-Merge
sind noch **nicht** nachgewiesen.

Nach Synchronisierung der Evidenzstaende wurden Ticket-, Projekt-, Dokumentations-,
Backend- und Retention-Kontrollen nochmals erfolgreich ausgefuehrt. Das lokale
Remote-Backend-Profil bleibt erwartungsgemaess FAIL (keine Remote-Verbindung):
Aktivierung, Hosted-/Privacy-Nachweise und qualifizierte Reviews fehlen.

## Abschlussgrenze

Lokale Akzeptanzkriterien sind erfuellt; TKT-037-05 steht auf Review, nicht done.
Separater Abschlussreview und PR-/Post-Merge-Nachweis fehlen noch. TKT-037-01
bleibt bis zum Ticketabschluss nicht ready. Migrationen 14 und 15, Hosted-
Gateway-Verifikation sowie externer Alarmkanal bleiben eigene Folgetickets.
TKT-038-01 fuer die zwei Client-Cache-Frischefehler ist als naechstes vorbereitet.

Der Security-Best-Practices-Skill beeinflusste die risikobasierte Priorisierung,
die negativen Kontrolltests und die ausdrueckliche Trennung von lokaler
Funktion, Hosted-Vertrauen und qualifizierter Freigabe.
