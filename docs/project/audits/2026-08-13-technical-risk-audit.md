# Technisches Risiko-Audit — Gesamtes Repository (2026-08-13)

**Durchgeführt mit:** Claude Code (automatisiertes Multi-Agent-Audit, anschließend manuell verifizierte P0-Findings).
**Scope:** Flutter-App (`esg_app/`), Supabase-Migrationen + Edge-Function (`supabase/`),
Scripts (`scripts/`), projektbezogene ADRs und Threat-Model.
**Methode:** Drei parallele Deep-Dives (UI/Scanner, Daten-Layer/Netzwerk, Backend/SQL)
mit vollständigem Lesen aller Lib-Dateien, aller 7 Migrationen, beider pgTAP-Suiten,
der Edge-Function, `pubspec.lock`, `coverage/lcov.info` und der gepinnten
`mobile_scanner-7.3.0`-Paketquelle. Die P0-Findings wurden zusätzlich unabhängig
im Code verifiziert.
**Status-Legende:** *Confirmed* = im Code belegte Stelle (file:line). *Hypothese* =
plausibles Risiko, dessen Eintritt von externen Faktoren abhängt.

---

## Executive Summary

Service-Layer-Fehlerklassifikation, der Barcode-Race-Guard im Scanner, die
RLS-/Constraint-Disziplin im Backend und die Accessibility-Arbeit sind
**überdurchschnittlich gut** für ein Projekt in diesem Stadium. Es wurden
**keine SQL-Injection-Pfade, keine fehlenden `search_path`-Pins, kein RLS-Bypass
und keine committeten Credentials** gefunden.

Die konzentrierten Risiken:

1. **Stabilität:** Eine ganze Exception-Klasse (TLS-Fehler, Mapper-Typfehler) wird
   nirgends gefangen und friert die App dauerhaft ein — ohne Fehlermeldung.
2. **Architektur-Arithmetik:** Das Writer-Tagesbudget (500) und die Cache-TTL (24 h)
   wurden unabhängig gewählt; ihr Produkt begrenzt den Server-Cache auf ~500
   gleichzeitig frische Produkte — bei Zielskala 10k/100k wirkungslos.
3. **Score-Integrität:** Neutral-Baselines und Gewichts-Renormalisierung erzeugen
   Scores aus Nicht-Evidenz — im Widerspruch zum eigenen Produktversprechen.
4. **Betrieb:** Kein On-Device-Cache, unsichtbare Cache-Ausfälle in Release-Builds,
   fehlende Retention und FK-Indizes im Backend.

Auffällig: Die lcov-Daten zeigen, dass genau die fehlerhaften Zeilen
(Retry-Closure, Kamera-Lifecycle, DetailScreen) ungetestet sind — die Testlücken
und die bestätigten Bugs sind deckungsgleich.

---

## P0 — Kritisch

### F-01: App friert dauerhaft ein bei unerwarteten Fehlern (Stuck-Spinner)

- **Problem/Risiko:** Jede Exception, die keine `ProductLookupFailure` ist, lässt
  `_isLoading` für immer auf `true` — Scan-Button, Scanner-Öffnen, manuelle Eingabe
  und Recent-Taps sind bis zum App-Neustart tot. Der Nutzer sieht keinerlei Fehler.
- **Betroffene Stellen:** `esg_app/lib/screens/home_screen.dart:49-58` (nur
  `on ProductLookupFailure`, kein `finally`, kein Catch-All);
  `esg_app/lib/services/open_food_facts_service.dart:81-98` (fängt nur
  `ProductLookupFailure`, `TimeoutException`, `http.ClientException` —
  `HandshakeException`/`CertificateException` sind keins davon);
  `esg_app/lib/services/product_repository.dart:106` (fängt nur `ProductCacheFailure`).
  Zusätzlich ungeschützt: der OFF-Pfad ruft den 604-Zeilen-Mapper ohne Guard auf
  (`open_food_facts_service.dart:153-160`), während der Supabase-Pfad denselben
  Mapper korrekt wrappt (`supabase_product_cache_service.dart:228-240`).
- **Ursache:** Zu enge Exception-Filter auf drei Ebenen; keine letzte Verteidigungslinie.
- **Auswirkung:** Captive Portal, Firmen-TLS-Interception, Uhrzeit-Drift, abgelaufenes
  Zertifikat oder ein einziger Mapper-Bug ⇒ Totalausfall der Kernfunktion, als
  unhandled async error unsichtbar verschluckt.
- **Schweregrad:** Kritisch
- **Arbeitsbereich:** Flutter-UI + Daten-Layer
- **Empfehlung:** (a) `_isLoading = false` in ein `finally` verschieben; (b) Catch-All
  `on Object` in `_openBarcode` mit Routing auf `LookupErrorScreen`
  (`invalidResponse`); (c) Mapper-Aufruf im OFF-Service wie im Supabase-Service
  wrappen (Ein-Zeilen-Paritätsfix); (d) Test mit `_ThrowingRepository`
  (plain `Exception`), der die Erholung von `_isLoading` beweist.
- **Status:** Confirmed (zwei unabhängige Analysen + direkte Verifikation).

### F-02: Cache-Budget × TTL macht den Server-Cache bei Zielskala wirkungslos

- **Problem/Risiko:** Steady-State-Maximum von ~500 gleichzeitig frischen Produkten.
- **Betroffene Stellen:**
  `supabase/migrations/20260812000100_trusted_writer_cache_path.sql:209`
  (Tagesbudget `<= 500` Upstream-Requests);
  `supabase/functions/ingest-products/index.ts:89` (`p_expires_at = fetchedAt + 86_400_000`,
  d.h. 24 h TTL); `get_fresh_cached_product` serviert nichts nach `expires_at`
  (`:116` der Migration).
- **Ursache:** Budget (Kostenkontrolle, THR-007) und TTL wurden unabhängig gewählt;
  das Produkt beider Werte wurde nie ausgerechnet. Tests publizieren 1 Produkt und
  können das nicht zeigen.
- **Auswirkung:** Bei 10k Produkten dauert Cold-Fill 20 Tage — während die ersten
  500 längst abgelaufen sind. Cache-Hit-Rate ≈ 0 % bei Zielskala; Open Food Facts
  trägt die volle Scan-Last — exakt das OFF-Rate-Limit-Risiko, zu dessen Lösung der
  Cache gebaut wurde (ADR 0022).
- **Schweregrad:** Kritisch (Architektur; heute unsichtbar, bricht bei Launch)
- **Arbeitsbereich:** Backend
- **Empfehlung:** Beide Regler gemeinsam dimensionieren. Optionen: (a) Budget ~2
  Größenordnungen anheben; (b) TTL von Refresh-Rate entkoppeln — langes `expires_at`
  plus separate `stale_after`-Spalte, Client zeigt „stale, but labeled" (das
  UI-Modell `ProductCacheOutcome.stale` existiert bereits,
  `product_repository.dart:80`); (c) Ingestion demand-driven aus Scan-Telemetrie
  statt Blanket-Refresh. Entscheidung als ADR festhalten.
- **Status:** Confirmed (Arithmetik direkt verifiziert).

### F-03: Score-Integrität — fabrizierte Werte und Ein-Säulen-„fullScore"

- **Problem/Risiko:** (a) Ein Produkt mit *nur* einem Eco-Score von 80 erhält
  `total = 80`, `state = fullScore` und eine **grüne Ampel** bei
  `dataCompleteness = 1/3`. (b) Social bekommt eine Neutral-Baseline von 50, sobald
  überhaupt eine Zutatenliste existiert (`hasSocialSignal`), Governance 50, sobald
  eine Marke bekannt ist — diese fabrizierten 50er gehen mit 30 %/20 % Gewicht in
  den Gesamtscore ein.
- **Betroffene Stellen:** `esg_app/lib/services/esg_score_calculator.dart:281-303`
  (Renormalisierung über nur vorhandene Gewichte), `:88-91` + `:181-190` (Social-
  Baseline „Neutraler Startwert"), `:200-203` (Governance-Baseline);
  `esg_app/lib/models/product.dart:53-62` (`hasSocialSignal`/`hasGovernanceSignal`);
  Verhalten per Test fixiert (`esg_score_calculator_test.dart:27-36`).
- **Ursache:** Methodik-v1-Heuristik; Renormalisierung + Baselines als bewusste,
  aber nie gegen das Produktversprechen geprüfte Entscheidungen.
- **Auswirkung:** Direkter Widerspruch zur App-eigenen Aussage „Wir zeigen nur
  belegte Signale und verzichten auf Schätzung" (`esg_score.dart:62`) —
  Greenwashing-/Reputations-/Rechtsrisiko im Kernprodukt (verschärft RISK-003,
  RISK-007, RISK-012). Beispiel: Eco 80 + bloße Zutatenliste ⇒ 68.75 gelb, aus
  einem einzigen echten Datum.
- **Schweregrad:** Kritisch (Produkt-Integrität; kein Crash)
- **Arbeitsbereich:** Scoring/Methodik
- **Empfehlung:** ADR analog 0027: (a) Baselines entfernen oder als
  „nicht bewertet" statt 50 ausweisen; (b) Ein-Säulen-Ergebnis nie als `fullScore`
  mit grüner Ampel zeigen (z. B. eigener State `partialScore` mit sichtbarer
  Kennzeichnung); (c) Magic Numbers (Gewichte, Grade-Map, Deltas, Ampelgrenzen) an
  `formulaVersion` binden und aus versioniertem Artefakt referenzieren.
- **Status:** Confirmed.

### F-04: Kein On-Device-Cache — App offline unbrauchbar

- **Problem/Risiko:** Vollständig offline endet jeder Lookup im `LookupErrorScreen`,
  auch für ein 10 Sekunden zuvor gescanntes Produkt. Doppelt gescannte Barcodes
  kosten jedes Mal volle Supabase- + OFF-Roundtrips. „Zuletzt gescannt" ist nach
  jedem Kaltstart leer; ein Tap darauf löst offline einen fehlschlagenden
  Netzwerk-Lookup aus.
- **Betroffene Stellen:** `esg_app/pubspec.yaml:30-45` (kein `shared_preferences`,
  `sqflite`, `hive`, `drift`, `path_provider`);
  `esg_app/lib/services/product_repository.dart:61-69, 99-116, 156-174`
  (`findByBarcode` konsultiert `_recentProducts` nie; Liste nur In-Memory).
- **Ursache:** Persistenz wurde auf den Server-Cache verlagert; der ist read-only
  und remote (Cache-Misses werden nie durch User-Traffic repariert, Writes nur via
  Ingestion-Job).
- **Auswirkung:** Der Kern-Use-Case — Scannen im Supermarktgang mit schlechtem
  Empfang — scheitert. Unnötige Last auf OFF (Rate-Limit-Exposure) und Supabase
  (Egress-Kosten).
- **Schweregrad:** Kritisch (Produkt-Fit) / Hoch (technisch)
- **Arbeitsbereich:** Daten-Layer
- **Empfehlung:** Kleiner lokaler LRU-Cache (z. B. `hive` oder `sqflite`) mit
  TTL-Kennzeichnung („Stand: vor 2 Tagen") vor der Netzwerk-Kette; Recent-Liste
  persistieren; Negative-Caching für 404-Barcodes erwägen. DSGVO-seitig unkritisch
  (Produktdaten, keine Personendaten), aber im Privacy-Inventar nachziehen.
- **Status:** Confirmed.

---

## P1 — Hoch

### F-05: Doppel-Tap pusht zwei ScannerScreens — Kamera-Session-Konflikt

- **Betroffene Stellen:** `home_screen.dart:115-126` (`_openScanner`, nur
  `_isLoading`-Guard, der beim Idle-Button `false` ist); gleiches Muster beim
  „Details"-Button (`result_screen.dart:40-44` → `home_screen.dart:107-113`).
- **Ursache:** Kein Navigations-Guard/Debounce; `mobile_scanner` dokumentiert
  explizit, dass nur eine Kamera-Session aktiv sein kann.
- **Auswirkung:** Zweiter Controller übernimmt die Session; nach Pop des oberen
  Scanners bleibt der untere mit toter Preview zurück — eingefrorener/schwarzer
  Scanner, der nie erkennt.
- **Schweregrad:** Hoch | **Bereich:** Flutter-UI
- **Empfehlung:** Navigations-Flag (`_isNavigating`) oder Route-Guard
  (`ModalRoute.isCurrent`) in `_openScanner`/`_openDetails`; Widget-Test mit
  Doppel-Tap.
- **Status:** Confirmed.

### F-06: Cache-Ausfälle in Release-Builds vollständig unsichtbar

- **Betroffene Stellen:** `esg_app/lib/main.dart:18-21` (Produktion konstruiert
  `ReadThroughProductRepository` ohne `onCacheOutcome` — Observer existiert nur in
  Tests); `main.dart:40` (Config-Fehler nur `debugPrint`, in Release gestrippt);
  leere/partielle dart-defines degradieren stumm (`:30-43`).
- **Ursache:** Observability wurde als Test-Hook gebaut, nie produktiv verdrahtet.
- **Auswirkung:** Totes Supabase-Projekt, falscher dart-define im CI oder
  abgelaufener Key bliebe seit Launch unbemerkt — die App fällt still auf direkten
  OFF-Traffic zurück (Latenz + Rate-Limit-Exposure). Kollidiert mit RISK-009
  (Monitoring/SLO offen).
- **Schweregrad:** Hoch (operativ) | **Bereich:** Daten-Layer/Ops
- **Empfehlung:** Minimal-Logging der Cache-Outcomes produktiv verdrahten (bis
  Sentry kommt: strukturiertes `log` via `dart:developer` + Zähler); Config-Fehler
  hart sichtbar machen (z. B. assert im Debug + einmaliger Hinweis im UI-Footer der
  Provenance-Karte).
- **Status:** Confirmed.

### F-07: Fremde Exception aus dem Cache killt den OFF-Fallback

- **Betroffene Stellen:** `product_repository.dart:106` (fängt nur
  `ProductCacheFailure`); z. B. `ArgumentError` aus `Uri.replace` in
  `supabase_product_cache_service.dart:137-139` oder TLS-Fehler propagieren durch.
- **Ursache:** Catch zu eng — der *optionale* Cache kann die *Pflicht-Quelle* mit
  abreißen (invertierte Resilienz).
- **Auswirkung:** Cache-Bug = Totalausfall statt Degradation; mündet in F-01.
- **Schweregrad:** Hoch | **Bereich:** Daten-Layer
- **Empfehlung:** Im Read-Through-Repository `on Object` fangen, als
  Cache-Outcome „error" melden, Fallback immer ausführen.
- **Status:** Confirmed.

### F-08: Kamera-Permission-Recovery dauerhaft kaputt

- **Betroffene Stellen:** `scanner_screen.dart:60` (der
  `hasCameraPermission`-Guard blockiert auch den `resumed`-Zweig: Wer in den
  iOS-Settings Kamera erlaubt und zurückkehrt, bekommt keinen Neustart);
  `scanner_screen.dart:322-326` („Erneut prüfen" — `start()` kann nach Denial auf
  iOS nicht re-prompten, dokumentiert im Paket); `pubspec.yaml` (kein
  `permission_handler`/`app_settings` ⇒ die eigene UI-Anweisung „Einstellungen >
  ScanFair > Kamera" ist ohne Settings-Deeplink nicht unterstützt).
- **Auswirkung:** Einmal abgelehnt = Scanner de facto dauerhaft unbenutzbar, obwohl
  der Nutzer die App-Anweisung korrekt befolgt.
- **Schweregrad:** Hoch | **Bereich:** Flutter-UI
- **Empfehlung:** Guard so umbauen, dass `resumed` immer einen Restart-Versuch
  macht; `app_settings` (oder `permission_handler`) für „Einstellungen öffnen";
  In-Flight-Guard für `_restartScanner` (`:104-107`, wiederholte Taps werfen still
  `controllerInitializing`).
- **Status:** Confirmed.

### F-09: `onRetry`-Closure — fragilster Code der App, komplett ungetestet

- **Betroffene Stellen:** `home_screen.dart:60-73`: unguarded `context` in
  Closure, verworfene Future (`_openBarcode` fire-and-forget), `pop()` sofort
  gefolgt von neuem Push während laufender Transition, pro Retry bleibt der vorige
  `_openBarcode`-Frame suspendiert (unbegrenztes Wachstum bei wiederholtem Retry —
  genau das Verhalten, für das der Screen gebaut ist). lcov: Zeilen 65-67
  uncovered. Insgesamt 4 Fire-and-forget-Aufrufe von `_openBarcode`
  (`:67, :160, :191, :259`); die Lints `unawaited_futures`/`discarded_futures`
  sind nicht aktiv (`analysis_options.yaml` = unverändertes Boilerplate).
- **Schweregrad:** Hoch | **Bereich:** Flutter-UI
- **Empfehlung:** Retry als Rückgabewert des Error-Screens modellieren
  (`await push` liefert `retry: true`, Loop im aufrufenden `_openBarcode` statt
  Rekursion im Callback); Lints aktivieren; Widget-Test „fail once, then succeed".
- **Status:** Confirmed.

### F-10: `service_role` kann Audit-Trail und Idempotenz umgehen

- **Betroffene Stellen:** Migrationen revoken nur `anon, authenticated`
  (`20260727000100:128-132`), nie `service_role`. Die Edge-Function hält den
  Service-Role-Key (`index.ts:22`) und könnte `cached_products` direkt schreiben —
  vorbei an `publish_off_product` und damit an Idempotency-Key,
  Out-of-order-Schutz, 1-MiB-Bound und **Audit-Insert**
  (`20260812000100:329-471`). Nur der Lizenz-Trigger feuert unconditional.
- **Auswirkung:** Stilles, unauditiertes Cache-Poisoning durch alles, was den Key
  hält — THR-006 („Writer action cannot be reconstructed") ist nur prozedural,
  nicht strukturell erfüllt.
- **Schweregrad:** Hoch | **Bereich:** Backend/Security
- **Empfehlung:** `revoke insert, update, delete on public.cached_products from
  service_role;` — Schreibpfad ausschließlich über die Definer-RPC. Vorher
  Plattform-Defaults am verknüpften Projekt verifizieren (`\dp public.cached_products`).
- **Status:** Confirmed gap; Plattform-Default-Zustand: Hypothese.

### F-11: Keine Retention/GC — fünf Tabellen wachsen unbegrenzt

- **Betroffene Stellen:** `20260812000100:27-85`: `writer_rate_windows`
  (~1M Zeilen/Jahr, nach 60 s wertlos), `writer_audit_log` (append-only-Trigger
  verhindert jede Löschung — der von THR-006 geforderte Retention-Job ist gegen
  dieses Schema **nicht schreibbar** — und die Tabelle hat außer der PK keinen
  Index), `writer_idempotency_keys`, abgelaufene `cached_products`,
  `score_snapshots` (ohne Dedup, siehe F-24). Kein `pg_cron`, kein `DELETE`, keine
  Partitionierung in irgendeiner Migration.
- **Auswirkung:** Unbegrenzte Storage-Kosten, degradierender Writer-Hot-Path
  (Index-Bloat unter globalem Advisory-Lock), Forensik wird Seq-Scan.
- **Schweregrad:** Hoch | **Bereich:** Backend
- **Empfehlung:** `writer_audit_log` zeit-partitionieren (`DETACH PARTITION` +
  `DROP` statt `DELETE` — umgeht den Append-Only-Trigger sauber); Indizes auf
  `request_id`/`correlation_id`/Zeit; pg_cron-Sweep für `writer_rate_windows` und
  abgelaufene `cached_products`.
- **Status:** Confirmed.

### F-12: Sechs FK-Spalten ohne Index

- **Betroffene Stellen:** `scans.score_snapshot_id` (`20260727000100:99-100`),
  `traceability_relationships.source_id` (`20260727000400:84`),
  `source_mappings.data_source_id` (`20260727000200:131-132`),
  `profile_parameters (mvid, parameter_id)`, `category_profiles`-Self-FK,
  `private.writer_idempotency_keys.source_id`. Zusätzlich 2 redundante Indizes
  (`20260727000200:157-158` = Präfix der PK; `20260727000400:126-127` = Duplikat
  des Unique).
- **Auswirkung:** Jedes Parent-`DELETE`/Key-`UPDATE` (z. B. `data_sources`-Pflege,
  Snapshot-Löschung) = Full-Seq-Scan der Kindtabelle unter FK-Check-Lock; bei 1M
  `scans`-Zeilen mehrsekündige Statements mit `ROW SHARE` auf `scans`.
- **Schweregrad:** Hoch (strukturell, wächst mit Datenmenge) | **Bereich:** Backend
- **Empfehlung:** Covering-Indizes für alle sechs FKs; redundante Indizes droppen;
  Partial-Indizes `where published_at is not null` für die drei
  Publication-gefilterten Tabellen.
- **Status:** Confirmed.

### F-13: Systematisch verzerrte Scores — Substring-Matching + fehlende Lokalisierung

- **Betroffene Stellen:** `esg_score_calculator.dart:337-339` (unverankertes
  `contains`): „bio" ⊂ „**antibio**tics" ⇒ ein OFF-Label `en:no-antibiotics`
  vergibt **+20 „Bio-Siegel"**; ebenso `en:biodegradable-packaging`. „palm" ⊂
  „palmitate/palmitic acid" ⇒ **−15 Palmöl-Penalty** fälschlich. `:330-335`:
  Labels und Origins in einem Topf (Label-Needles matchen Origin-Tags); `en:`-Strip
  via `replaceAll` lässt `de:`/`fr:`-Präfixe stehen. `open_food_facts_service.dart:107-109`:
  kein `lc`/`cc`-Parameter und keine `*_de`-Felder ⇒ Produktnamen/Zutaten kommen in
  der Hauptsprache des Produkts (oft FR/EN), die DE/EN-Keyword-Heuristik greift
  systematisch nicht.
- **Auswirkung:** Falsche Einzel-Scores in beide Richtungen; deutsche Nutzer sehen
  fremdsprachige Produktnamen (verwandt: TODO-033).
- **Schweregrad:** Hoch (Score-Korrektheit) | **Bereich:** Scoring + Daten-Layer
- **Empfehlung:** Tag-Matching auf exakte, präfix-normalisierte Tags umstellen
  (OFF-Tags sind kanonisch — `en:organic` etc. exakt vergleichen statt Substring);
  Labels/Origins getrennt matchen; `lc=de`-Parameter + `product_name_de` anfragen;
  Testfälle für die False-Positive-Klasse.
- **Status:** Confirmed.

### F-14: Evidence-`sourceField` falsch bei v2/v3-Mischpayloads

- **Betroffene Stellen:** `open_food_facts_product_mapper.dart:21-32` (Feldname
  per `containsKey`) vs. `:34-39` (Wert per `??`). Liefert OFF
  `environmental_score_grade: null` neben befülltem `ecoscore_grade` (typisch
  während der v2→v3-Migration), behauptet die Evidenz Provenienz
  `environmental_score_grade`, der Wert stammt aber aus `ecoscore_grade`. Gleiches
  Muster für Score- und Data-Feld. `_mapFromPaths` (`:40-43`) macht es korrekt.
  Zusatz: `ESGDataSource.openFoodFacts.apiVersion = 'v3'` ist hartkodiert
  (`esg_evidence.dart:45`), nicht aus der Response abgeleitet.
- **Auswirkung:** Korrektheits-Bug im Audit-Trail — dem Kernversprechen belegbarer
  Provenienz (ADR 0022).
- **Schweregrad:** Hoch (für dieses Produkt) | **Bereich:** Daten-Layer
- **Empfehlung:** Feldnamen-Auswahl wertgetrieben machen (welches Feld lieferte den
  Wert, dessen Name wird gespeichert); Mapper-Testfile mit genau diesem Fixture.
- **Status:** Confirmed.

---

## P2 — Mittel

### F-15: Latenz-Profil — bis ~29 s Worst-Case ohne Feedback, Retry-Verstärkung

- **Stellen:** `open_food_facts_service.dart:15-17` (8 s × 3 Versuche + Backoff
  250/500 ms) + `supabase_product_cache_service.dart:110` (4 s Cache davor) ⇒
  ~29 s mit statisch ausgegrautem Button, ohne Spinner, ohne Cancel. 429 wird mit
  250 ms Backoff retried, `Retry-After` ignoriert (`:118-124`) — verstärkt das
  Rate-Limit. Kein Circuit-Breaker: Bei Supabase-Ausfall zahlt jeder Scan +4 s.
  `.timeout()` bricht den Request nicht ab — Retries erzeugen bis zu 3 parallele
  In-Flight-Requests pro Barcode.
- **Auswirkung:** Gefühlter Hänger; OFF-seitige Block-Gefahr.
- **Bereich:** Daten-Layer | **Empfehlung:** Gesamtdeadline pro Lookup (~10 s),
  `Retry-After` respektieren, 429 nicht aggressiv retrien, simpler
  Failure-Counter/Cooldown für den Cache, sichtbarer Progress + Cancel.
- **Status:** Confirmed.

### F-16: Scanner-Lifecycle — Pop-Race und `stop()` statt `pause()`

- **Stellen:** `scanner_screen.dart:80-82` (zwischen `await _stopScanner()` und
  `pop(barcode)` kann der Close-Button den Screen bereits poppen; `mounted` bleibt
  während der Transition true ⇒ zweiter Pop trifft HomeScreen ⇒ leerer Navigator);
  `:62-70` (`inactive` — Control Center, Notification, Anruf — macht vollen
  Session-Teardown via `stop()` statt `pause()`: schwarzer Flash + mehrere hundert
  ms Stall bei Resume).
- **Bereich:** Flutter-UI | **Empfehlung:** `ModalRoute.isCurrent`-Check vor dem
  Pop bzw. `_hasCompleted` auch im Close-Handler setzen; `pause()` für
  `inactive`. Positiv: Der `_hasCompleted`-Guard selbst ist korrekt (synchron vor
  erstem `await` gesetzt) — die Detection-Race ist sauber gelöst.
- **Status:** Confirmed.

### F-17: Pilot-Fallback maskiert Netzwerkausfall als „dünne Daten"

- **Stellen:** `product_repository.dart:159-163` (für die 3 Pilot-GTINs wird eine
  `ProductLookupFailure` verschluckt und `_fallbackProduct` synthetisiert),
  `coffee_pilot_catalog.dart:126-142` (`ecoscoreGrade: 'unknown'` ⇒
  `LowDataScreen` sagt „Eco-Score fehlt", obwohl das Netz ausfiel). Die Markierung
  `dataQualityWarnings: ['pilot-source-fallback']` wird von keinem Screen gerendert.
- **Auswirkung:** Irreführende UX ausgerechnet bei den 3 Produkten, an denen der
  Pilot evaluiert wird.
- **Bereich:** Daten-Layer/UX | **Empfehlung:** Fallback-Fall visuell als
  „Live-Daten nicht erreichbar (Basisdaten angezeigt)" kennzeichnen oder
  Failure durchreichen.
- **Status:** Confirmed.

### F-18: Backend-Härtungslücken (latent)

- **Stellen/Punkte:**
  - Verwaiste RLS-Policy „Fresh product cache is readable"
    (`20260727000100:146-150`): Grant wurde revoked (`20260812000100:87-89`), die
    Policy nie gedroppt — jeder künftige `grant select` re-armiert sofort den
    enumerierbaren Listen-Endpoint ohne Policy-Review.
  - 6 Tabellen (u. a. `product_evidence`, `score_snapshots`,
    `traceability_*`) behalten direkte `select`-Grants für `anon` — paginierbare
    Listen-Endpoints (1000er-Seiten via `max_rows`), obwohl die
    `cached_products`-Begründung („enumerable list endpoint") wörtlich auch für
    sie gilt; ODbL-Share-Alike-Aspekt für OFF-derivierte Evidenz.
  - Kein Read-Rate-Limit trotz ABUSE-002 („bounded **or rate_limited**") — der
    „bounded"-Teil ist umgesetzt, der Rate-Limit-Teil nicht; anon-Key steckt im Binary.
  - Kein Cap auf `expires_at - fetched_at` (`20260812000100:334-338`): Ein
    fehlerhafter/feindlicher Writer kann `expires_at = 3000-01-01` setzen — ewig
    „frischer" vergifteter Eintrag (Client-Guards prüfen nur `fetched_at`-Skew).
  - `private.*`-Tabellen ohne RLS-Layer und ohne
    `alter default privileges` — Schutz hängt allein am Schema-REVOKE + PostgREST-Config.
- **Bereich:** Backend/Security | **Empfehlung:** Policy droppen; Evidenz-Reads auf
  Bounded-RPCs umstellen (Muster existiert); TTL-Obergrenze im RPC (`<= 7 days`);
  Edge-Rate-Limit im Umgebungsvertrag verankern; `alter default privileges` +
  RLS-enable für `private`.
- **Status:** Alle Punkte Confirmed; Exploit-Pfade teils Hypothese (erfordern
  Folge-Fehler).

### F-19: Migrations-/Trigger-Hygiene — bricht genau beim Härten und Skalieren

- **Stellen/Punkte:**
  - 15 `create policy` ohne `drop policy if exists` (Migrationen 1/2/4) —
    Replay auf bestehender DB bricht mit `42710`; CI merkt es nie
    (immer frischer `db reset`). Migration 5 zeigt das korrekte Muster.
  - Migration 7 (`20260812000100:7-15`): Full-Table-`UPDATE` + `SET NOT NULL` auf
    `cached_products` = blockierender Rewrite unter `ACCESS EXCLUSIVE` — heute
    leer und gratis, nach Launch ein Outage-Muster.
  - Invoker-Rights-Trigger (`20260810000100:36-55`,
    `20260811000100:145-157`) lesen RLS-gefilterte Tabellen (`published_at`,
    `active`) — funktionieren heute nur, weil der Writer BYPASSRLS hat. Sobald der
    in ADR 0032 angestrebte Least-Privilege-Writer kommt, schlagen valide Inserts
    mit irreführenden Fehlern fehl. Fix: Trigger-Funktionen `SECURITY DEFINER`
    (search_path ist bereits gepinnt).
  - Keine `updated_at`-Trigger; Migration 6 ließ bei ihrem Bulk-Update auf
    `data_sources` `updated_at` selbst stale — das Feld ist als
    Change-Detection-Key unbrauchbar.
  - Applied Migration wurde in-place editiert (Commit 480a843) — gegen die eigene
    Regel in `supabase/README.md:100-102` (praktisch folgenlos, aber die
    Gewohnheit ist das Risiko).
- **Bereich:** Backend | **Empfehlung:** Policies idempotent nachrüsten;
  Rewrite-Muster künftig als `NOT VALID` + `VALIDATE`; Trigger auf DEFINER;
  generischer `updated_at`-Trigger.
- **Status:** Confirmed.

### F-20: Google Fonts zur Laufzeit von fonts.gstatic.com

- **Stellen:** `pubspec.yaml:41` (`google_fonts`), `:80-98` (fonts-Sektion
  komplett auskommentiert — nichts gebündelt); `allowRuntimeFetching` nirgends
  konfiguriert.
- **Auswirkung:** (a) Unangekündigter Google-Request beim Start — Inkonsistenz für
  eine Datenminimierungs-App (Privacy-Inventar/DSGVO, berührt RISK-005 und das
  Privacy-Manifest); (b) offline First-Launch rendert im Fallback-Font mit
  falschen Letterspacing-Metriken; (c) CI-Flakiness.
- **Bereich:** Flutter/Compliance | **Empfehlung:** Inter + Instrument Serif als
  Assets bündeln, `google_fonts` entfernen oder `allowRuntimeFetching = false`.
- **Status:** Confirmed.

### F-21: Fehlende Rückmeldung + Overflow auf dem Fehlerpfad

- **Stellen:** `_ManualBarcodeCard` (`home_screen.dart:237-273`) und
  Recent-Taps (`:187-193`) bleiben während eines Lookups aktiv, `_openBarcode`
  returnt still (`:47`) — Tap ohne jede sichtbare Reaktion; nirgends ein
  `CircularProgressIndicator`. `LookupErrorScreen` ist der einzige Screen ohne
  ScrollView (`lookup_error_screen.dart:24` Column + `:42` Spacer) — bei 200 %
  Textskalierung RenderFlex-Overflow genau auf dem Fehler-Screen (das Projekt
  testet 200 % sonst explizit).
- **Bereich:** Flutter-UI/Accessibility | **Empfehlung:** `isLoading` an
  ManualCard/Recents durchreichen; Screen scrollbar machen (Muster
  `ScannerErrorView` existiert); 200 %-Test ergänzen.
- **Status:** Confirmed.

### F-22: Response-Barcode nie verifiziert; Bild verworfen

- **Stellen:** `open_food_facts_service.dart:30-57` fragt `code` und
  `image_front_small_url` an; der Mapper liest beides nie.
  `ScanFairProduct.barcode` und Entity-Id `gtin:$barcode` stammen aus dem
  *Request* (`open_food_facts_product_mapper.dart:258, 265`); ein OFF-Redirect/
  Duplikat-GTIN liefert stillschweigend ein Produkt unter falschem Barcode.
  `imageEmoji: '□'` ist hartkodiert (`:363`) — Bild wird geladen und verworfen.
- **Bereich:** Daten-Layer | **Empfehlung:** `code`-Mismatch als
  `invalidResponse` behandeln (oder gezielt als Redirect kennzeichnen);
  Bildfeld entweder nutzen oder nicht mehr anfragen.
- **Status:** Confirmed.

### F-23: Testlücken decken sich mit den bestätigten Bugs

- **Befund (lcov + Struktur):** `detail_screen.dart` 0/18 Zeilen;
  Retry-Closure (home 65-67), Recent-Tap (191), Keyboard-Submit (259) uncovered;
  `scanner_screen.dart` 63 % — Lifecycle (58-69), `_restartScanner`/Torch
  (104-128), echter `MobileScanner`-Pfad (146-157) alle uncovered;
  `lookup_error_screen.dart`: 4 von 6 Failure-Typen nie gerendert. **Kein
  Testfile für den 604-Zeilen-Mapper** (nur indirekte Mini-Fixtures). Keine
  Concurrency-/Doppel-Tap-Tests, kein Test für Nicht-`ProductLookupFailure`-Escape,
  kein Contract-/Golden-Test gegen ein echtes OFF-v3-Payload (Schema-Drift — genau
  das Szenario des v2/v3-Dualpfads — würde unbemerkt bleiben), `main.dart`-Wiring
  (dart-define-Matrix, produktive Repository-Kette) nie im Test zusammengebaut.
  Der Streaming-Size-Guard des Cache-Service wird nur im Content-Length-Zweig
  getestet.
- **Bereich:** Qualität/CI | **Empfehlung:** Priorität nach Bugnähe: (1)
  Throwing-Repository-Test für F-01, (2) Retry-Flow-Test, (3) Doppel-Tap-Tests,
  (4) Mapper-Testfile inkl. F-14-Fixture, (5) OFF-Golden-Payload als Fixture,
  (6) Lints `unawaited_futures`/`discarded_futures` aktivieren.
- **Status:** Confirmed (via lcov).

### F-24: Snapshot-Duplikate und Array-as-FK schwächen die Evidenzkette

- **Stellen:** `score_snapshots` ohne `unique (barcode, formula_version,
  input_fingerprint)` (`20260727000100:74-93`) — identische Recomputes erzeugen
  unbegrenzt Duplikate, „welchen Snapshot sah der Nutzer" wird mehrdeutig.
  `evidence_ids text[]`/`relationship_ids uuid[]` (`:88`,
  `20260727000400:86, 121-122`) referenzieren nur per Konvention — dangling IDs
  möglich, `product_evidence.subject_id` ist freier Text ohne FK. Der
  Score-Eligibility-Check prüft nur `cardinality > 0`.
- **Bereich:** Backend | **Empfehlung:** Unique-Constraint auf den natürlichen
  Schlüssel; für Evidenz-Referenzen mittelfristig Junction-Table oder zumindest
  einen Validierungs-Trigger.
- **Status:** Confirmed.

---

## P3 — Niedrig / Wartung

| Finding | Stelle | Empfehlung | Status |
|---|---|---|---|
| 3 parallele Fehler-Taxonomien (`ProductLookupFailureType`/`ProductCacheFailureType`/`ProductCacheOutcome`) mit Hand-Switch | `product_lookup_failure.dart`, `supabase_product_cache_service.dart:14-22`, `product_repository.dart:131-142` | Auf eine Taxonomie + Quelle konsolidieren | Confirmed |
| Dreifache `_recentProducts`-Buchführung; nur die äußerste wird angezeigt | `product_repository.dart:58, 96, 153` | Nur im äußersten Repository führen | Confirmed |
| `close()`-API tot/unerreichbar; HTTP-Clients leben ewig (leakt über Hot-Restarts) | `product_repository.dart:79` u. a. | Entweder verdrahten oder entfernen | Confirmed |
| Mutable State im Repository, synchron in `build()` gelesen; `recentProducts()` re-enricht pro HomeScreen-Build 3 Produkte neu | `home_screen.dart:131`, `product_repository.dart:177-193` | Ergebnis cachen; Änderungs-Notification einführen | Confirmed |
| Typography/Theme als Getter — `GoogleFonts`-Allokation pro Zugriff (14 Stellen in `build()`), blockiert `const` | `scanfair_typography.dart:149-187`, `scanfair_theme.dart:16` | `static final` | Confirmed |
| `ValueListenableBuilder` um den ganzen Scanner-Scaffold — Pinch-Zoom rebuildet alles | `scanner_screen.dart:161-168` | Builder auf Torch-Button verengen (Viewport ist bereits korrekt stabil) | Confirmed |
| `annotate()`-Regex über jeden Accessibility-String pro Build | `semantic_terminology.dart:91-100` | AttributedStrings cachen | Confirmed |
| `_stringList` ohne Trim/Null-Filter (JSON-`null` wird String `"null"`); `_slug` kollabiert Nicht-ASCII (`Café Röstfein` → `caf-r-stfein`, Kollisionsgefahr); `brands` ist CSV, wird als eine Marke behandelt (Workaround im Calculator belegt Problembewusstsein); `'unknown'`-Grade erzeugt Evidenzrecord über einen Nicht-Wert | `open_food_facts_product_mapper.dart:392-403, 546-551, 63, 117-124` | Im Mapper-Testfile mit abdecken | Confirmed |
| Edge-Function-Wall-Clock: 25er-Batch × 1 s Sleep × Retries ≈ bis 10 min > Plattform-Limit; Budget bereits verbraucht | `index.ts:43`, `writer_contract.mjs:2` | Batchgröße/Limit im Umgebungsvertrag verankern | Hypothese |
| `payload_sha256` über jsonb-Reserialisierung — PG-Major-Upgrade könnte alle Idempotency-Keys kippen (Re-Publish-Sturm) | `20260812000100:340-343` vs. `writer_contract.mjs:337-348` | Hash über kanonische Quell-Bytes, Notiz in ADR 0022 | Hypothese |
| Tote UI: 3 `_OptionTile`s mit Chevron ohne `onTap`; „Erneut"-Button mit Scanner-Icon macht nur `pop()` | `not_found_screen.dart:44-60, 91`, `result_screen.dart:49-52` | Deaktiviert stylen bzw. Icon/Aktion angleichen | Confirmed |
| Hartkodierter UA weicht von dokumentierter Env-Config ab; persönliche E-Mail als Default-UA in 2 toten Spike-Skripten (committete PII an Dritt-API) | `open_food_facts_service.dart:26-27`, `scripts/spikes/off_api_esg_spike.sh:17`, `scripts/test_off_api.sh:11` | Spikes archivieren/löschen, UA aus Env | Confirmed |
| `supabase/README.md:23` nennt 119 pgTAP-Tests, real sind es 123 (Root-README korrekt) | `supabase/README.md:23` | Zahl korrigieren | Confirmed |
| 2 redundante Indizes (Präfix der PK bzw. Duplikat eines Unique) | `20260727000200:157-158`, `20260727000400:126-127` | Droppen | Confirmed |
| Unbenannte CHECK-Constraints in Migrationen 1–3 (positionsabhängige Auto-Namen) | `20260727000100` | Bei nächster Gelegenheit benennen | Confirmed |
| Keine l10n/ARB-Infrastruktur trotz vollständig hartkodiertem Deutsch | alle Screens | Vor Phase 2 entscheiden | Confirmed |
| Kein Retraction-Audit: `published_at = null` ist reversibel und spurlos — THR-006 deckt Writer, nicht Publikationsstatus | Migrationen | Publikations-Statuswechsel auditieren | Confirmed |

---

## Stärken (bewusst erhalten)

- **Backend:** Kein dynamisches SQL; alle `SECURITY DEFINER` mit `search_path = ''`
  gepinnt und vollqualifiziert; forced RLS auf allen 13 Public-Tabellen (pgTAP-
  verifiziert); fail-closed Rate-Limits mit korrekter `ON CONFLICT`-NULL-Semantik;
  deadlockfreie Advisory-Lock-Ordnung in `publish_off_product`; Score-Eligibility
  als DB-Constraint (nicht per App-Code umgehbar); Idempotenz + Out-of-order-Schutz
  getestet; Barcode-Format an 4 Stellen erzwungen; 123 pgTAP-Tests mit ehrlichen
  Plans; Edge-Writer mit constant-time Secret-Vergleich und getrennten
  Actor-Secrets (CI beweist Cross-Actor-Replay-Schutz).
- **Client:** Supabase-Config-Validator (HTTPS-only, JWT-Rollen-Check, lehnt
  `sb_secret_*` ab) — der bestgehärtete Teil des Daten-Layers; Response-Size- und
  Single-Row-Bounds; client-seitige TTL-Revalidierung + Clock-Skew-Guard;
  `_hasCompleted`-Race-Guard synchron vor erstem `await`; Controller/Observer-
  Disposal korrekt; saubere Widget-Dekomposition; Fehlerklassifikation
  404/429/5xx/Parse mit deutschen Texten und `canRetry`-Flag; keine Secrets im
  Repo, `--dart-define`-Konvention eingehalten.

---

## Empfohlene Umsetzungsreihenfolge

1. **F-01 + F-07** (ein PR): `finally` + Catch-All in `_openBarcode`, `on Object`
   im Read-Through, Mapper-Guard-Parität, Throwing-Repository-Test. Kleinster
   Eingriff, größte Stabilitätswirkung.
2. **F-05 + F-09**: Navigations-Guards + Retry-Flow-Umbau + Lints
   `unawaited_futures`/`discarded_futures` + Doppel-Tap-Tests.
3. **F-02**: Budget/TTL-Entscheidung als ADR (blockiert M2-Skalierung; reine
   Konfig-/Designentscheidung, kein großer Code).
4. **F-03 + F-13**: Scoring-ADR (Baselines, partialScore-State, exaktes
   Tag-Matching, `lc=de`) — vor Kalibrierung (M5) entscheiden, sonst wird auf
   falscher Grundlage kalibriert.
5. **F-08, F-06, F-04**: Permission-Recovery, Cache-Observability, lokaler Cache.
6. **F-10–F-12, F-18, F-19**: Backend-Härtung + Retention + Indizes — vor dem
   Remote-Deploy (passt in die offenen TODO-004-Restpunkte).
7. P2/P3 opportunistisch entlang der betroffenen Dateien.
