# TKT-038-01 – Cache-Frische und Ablaufgrenzen

Datum: 2026-09-23. Basis: `f33f758`, Branch
`codex/tkt-038-01-cache-freshness`, mit den dokumentierten lokalen Aenderungen.
Scope: zwei Dart-Services, ihre Tests und zugehoerige Ticket-/Evidenzpflege.
Keine Remote-Aktivierung, keine neue Abhaengigkeit, keine Methodikaenderung.

## Befunde und reproduzierbarer Vorher-/Nachher-Nachweis

**AR-07 / P2:** Fehlende oder ungueltige Frischemetadaten konnten als frischer
Cache gelten. Sieben erste Negativtests lieferten auf der alten Fassung
statt `invalidResponse` einen Cache-Treffer. Die Reparatur verlangt
String-Zeitstempel mit expliziter Zeitzone und
`fetched_at < stale_after <= expires_at`.

Beim separaten Nachreview des Parsers wurden vier weitere ungueltige
Varianten nachgewiesen: Kalenderueberlauf (44. Juli), Stundenueberlauf,
fehlende Zeitzone und Datum ohne Uhrzeit. Ein blosses `DateTime.tryParse`
akzeptierte sie; der gezielte Zwischenlauf hatte **8 PASS / 4 FAIL**.
Der finale Parser weist sie ab und akzeptiert gueltige UTC-/Offset-Zeiten
einschliesslich PostgreSQL-Mikrosekunden. Es wird keine Geraetezeitzone geraten.

**AR-08 / P2:** Der Cache konnte waehrend des wartenden OFF-Fallbacks ablaufen
und danach dennoch ausgegeben werden. Fake-Uhr-Tests mit kontrolliertem
Future wiesen den Fehler **genau bei und nach `expires_at`** nach. Eine
Mikrosekunde davor bleibt die gekennzeichnete Stale-Antwort erlaubt. Die
ersten beiden Fehlergruppen ergaben zusammen **21 PASS / 9 FAIL** auf der
alten Produktivlogik (nach Korrektur eines Future-Matchers im Test selbst).

`ProductCacheLookup` traegt nun zwingend `expiresAt`. Das Repository prueft
die Grenze direkt nach dem Cache-Lookup und erneut nach fehlgeschlagenem
Fallback. Bei Ablauf wird derselbe urspruengliche `ProductLookupFailure`
weitergegeben; kein `staleServed` und kein abgelaufenes neues Recent-Produkt.

## Final ausgefuehrte Ergebnisse

- Beide Service-/Repository-Testdateien: **42/42 PASS**, vorherige Baseline 20.
- Gesamte Flutter-Suite: **144/144 PASS**.
- Line Coverage: **1538/1815 = 84,74 %**; Mindestgrenze 60 %.
- Format: PASS; `flutter analyze --fatal-infos`: keine Findings.
- Vollstaendige lokale Development-Pruefkette: **33/33 PASS**.
- Ticket-Selbsttests: **22 Tests / 58 Assertions PASS**.
- PR-Bindung: **9 Tests / 27 Assertions PASS**.

Reproduktion:

```text
cd esg_app
flutter test test/services/supabase_product_cache_service_test.dart test/services/product_repository_test.dart
flutter analyze --fatal-infos
```

Der vollstaendige Runner ist `bash scripts/quality/run_quality_gates.sh`
vom Repository-Stamm. Die neu erzeugten lokalen Berichte stehen unter
`.quality/`; GitHub-Ausfuehrung ist ein gesonderter Nachweis.

## Abschliessender technischer Diff-Review

Pruefer: Codex, separater Nachpruefdurchgang durch denselben Assistenten;
keine personell unabhaengige Zertifizierung. Kein weiterer blockierender
Befund im vereinbarten lokalen Scope nach der Parser-Nacharbeit.

- `supabase_product_cache_service.dart:220`: Pflichtfelder und Reihenfolge
  werden vor dem Mapping geprueft; fehlerhafte Angaben gelten nie als frisch.
- `supabase_product_cache_service.dart:278`: begrenztes Zeitformat, reale
  Kalenderkomponenten und explizite Zeitzone; UTC-Normalisierung getestet.
- `product_repository.dart:130`: abgelaufene Lookups gelten auch bei falschem
  `isStale`-Flag als Miss.
- `product_repository.dart:159`: erneute harte Fristpruefung nach asynchronem
  Fallback, Fehleridentitaet bleibt erhalten.
- Bestehende Fresh-/Stale-Pfade, Circuit Breaker, OFF-Fallback und Mapper-
  Fehlerpfad bleiben getestet. Die Mapper-Fehler-Fixture besitzt jetzt die
  erforderlichen Frischefelder, damit sie weiterhin tatsaechlich den Mapper testet.
- Keine Aenderung an Backend-Flags, Schluesseln, Speicherfristen, Quellen,
  Score- oder Privacy-Entscheidungen; keine neue Paketabhaengigkeit.

Die Tests sichern die Frist pro Lookup. Sie sind kein Live-OFF-, Hosted-
Backend-, Device- oder kontinuierlicher Aktualisierungstest bereits
angezeigter Produktansichten. PR-/Post-Merge-Nachweis bleibt offen;
TKT-038-01 steht deshalb auf **review**, nicht done.
