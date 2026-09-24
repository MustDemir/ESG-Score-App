# Geschluesseltes, rotierendes IP-Pseudonym – Validierung (TKT-037-06)

- Audit-Datum: 2026-09-24
- Branch: `codex/tkt-037-06-keyed-rate-pseudonym`, Basis `ac511cb`
- Ticket: `TKT-037-06`, parent `TODO-037`
- Scope: Migration 16, Tests, Remote-Verifier, Vertrags- und Privacy-Artefakte
- Ausgeschlossen: Remote-Anwendung, Runtime-Aktivierung, Rechtsbewertung
  (bleibt in TKT-037-01)

## Ausgangslage

Migrationen 14 und 15 speicherten `SHA-256('scanfair-public-read-rate-v1|' || ip)`.
Praefix und Verfahren sind oeffentlich im Repository. Der IPv4-Raum umfasst
rund 4,3 Milliarden Adressen und laesst sich mit handelsueblicher Hardware in
Sekunden vollstaendig durchrechnen. Das Pseudonym war daher praktisch
umkehrbar und ueber beliebige Zeitraeume verknuepfbar.

## Entscheidung

ADR 0040, `amendment_2026_09_24`: HMAC-SHA-256 mit einem zufaelligen
32-Byte-Schluessel je UTC-Stunde, erzeugt in der Datenbank
(`extensions.gen_random_bytes(32)`), gespeichert in
`private.public_read_rate_keys`. Verworfen: statisches Vault- oder
Deployment-Secret (lebenslang umkehrbar, zusaetzlicher Secret-Lebenszyklus)
und taeglich abgeleiteter Schluessel aus statischem Master (Master-Leck
verknuepft alle Tage).

## Umsetzung

| Baustein | Inhalt |
| --- | --- |
| Migration `20260924000100_public_read_keyed_pseudonym.sql` | Schluesseltabelle mit RLS und Revoke; `private.public_read_rate_subject(inet, timestamptz)`; Hook nutzt einen gemeinsamen Zeitstempel fuer Minutenfenster und Schluesselstunde; Cleanup loescht vergangene Schluessel; bestehende v1-Zaehler werden entfernt |
| Schluessel-Loeschung | beim ersten Request einer neuen Stunde und in jedem Fuenf-Minuten-Cleanup |
| Uhrschutz | Ableitung mit einem Zeitpunkt mehr als fuenf Minuten in der Zukunft wird abgewiesen, damit kein aktueller Schluessel vorzeitig geloescht wird |
| Tests | `public_read_keyed_pseudonym.test.sql` (25 Assertions, feste Zeitpunkte); bestehender Spoofing-Test loest den Wert ueber den Schluessel der Fensterstunde auf |
| Remote-Verifier | `verify_public_read_abuse_protection.sql` leitet den Wert ueber die private Funktion ab und prueft Rechte auf Schluesseltabelle und Funktion |
| Gate | G-BACKEND-BOUNDARY verlangt `key_rotation` im Umgebungsvertrag und Marker in Migration 16 und neuer Testdatei; Negativtest fuer nicht rotierenden Schluessel |

## Ergebnisse (isolierte Instanz `scanfair-http-review-20260924`)

Die bestehende lokale Instanz `scanfair-local` wurde weder zurueckgesetzt noch
migriert. Die Testinstanz lief auf eigenen Ports (API 55321, DB 55322).

| Pruefung | Ergebnis |
| --- | --- |
| Forward-only-Replay aller Migrationen | 16/16 PASS |
| pgTAP, zehn Testdateien | 330/330 PASS (vorher 305) |
| davon neue Pseudonym-Tests | 25/25 PASS |
| davon Public-Read-Tests | 53/53 PASS |
| Datenbank-Lint, Stufe warning | PASS, keine Schemafehler |
| Gateway-/PostgREST-HTTP-Suite | 292 Assertions PASS |
| Rollback-only Remote-Verifier gegen die Testinstanz | PASS, keine Zaehler-Fixtures verblieben |
| Backend-Gate-Selbsttests | 24 Assertions PASS (vorher 22) |
| Development Quality Pipeline | 33/33 PASS, 144/144 Flutter-Tests, Coverage 84,74 % |

## Was die Tests belegen

- Der gespeicherte Wert entspricht dem HMAC unter dem Schluessel der Stunde und
  nicht mehr dem v1-Digest.
- Dieselbe IP behaelt innerhalb einer Stunde ihr Pseudonym (die Quote
  funktioniert) und erhaelt in der naechsten Stunde ein anderes.
- Der erste Request einer neuen Stunde loescht den alten Schluessel; ein
  geloeschter Schluessel laesst sich fuer seine Stunde nicht rekonstruieren.
- Der Cleanup loescht vergangene Schluessel auch ohne oeffentlichen Traffic.
- `anon`, `authenticated` und `service_role` haben keinen Zugriff auf
  Schluesseltabelle und Ableitungsfunktion.

## Verbleibende Grenzen

- Wer waehrend der laufenden Stunde privilegierten Datenbankzugriff hat, kann
  IP-Kandidaten gegen aktuelle Zeilen pruefen. Die Daten bleiben pseudonym.
- Faellt der Cleanup aus und gibt es keinen Traffic, bleibt ein alter
  Schluessel laenger bestehen; eine harte Obergrenze gibt es wie bei den
  Zaehlerzeilen noch nicht.
- Stundengrenzen-Randfaelle: Ein Request genau beim Stundenwechsel kann einen
  Zaehler in zwei Fenster teilen; das entspricht dem bestehenden
  Minutenfenster-Verhalten.
- Keine Aussage zur Rechtmaessigkeit; diese trifft die qualifizierte Person in
  TKT-037-01.
