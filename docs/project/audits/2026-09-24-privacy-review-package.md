# Privacy-Review-Paket fuer pseudonymisierte IP-Rate-Limit-Daten (TKT-037-01)

- Audit-Datum: 2026-09-24
- Branch: `codex/tkt-037-01-privacy-evidence`, Basis `d9cb5ee`
- Ticket: `TKT-037-01`, parent `TODO-037`
- Scope: technische Vorbereitung der qualifizierten Privacy- und
  DPIA-Entscheidung zur PostgREST-Rate-Limit-Verarbeitung (Migrationen 14/15)
- Ausgeschlossen: Rechtsbewertung (AC-02), Remote-Anwendung von Migrationen 14
  und 15, Aktivierung der Remote-Runtime, Verarbeitung echter Nutzerdaten

Dieser Bericht ist keine Rechtsfreigabe. Er belegt, dass die Unterlagen fuer
die pruefende Person vollstaendig, widerspruchsfrei und fail-closed an die
Gates gebunden sind.

## Methode

1. Vorbereitetes Paket `docs/project/compliance/review/tkt-037-01/` gegen
   Migrationen 14 und 15, ADR 0040, Umgebungsvertrag, Privacy-Inventar und
   `validate_claims_privacy_boundaries.rb` abgeglichen.
2. Technische Aussagen der Vorlagen zeilenweise gegen den SQL-Code geprueft.
3. Befunde behoben und durch neue positive und negative Gate-Selbsttests
   abgesichert.

## Verifizierte technische Aussagen

| Aussage im Paket | Quelle im Code | Ergebnis |
| --- | --- | --- |
| Nur letzter `X-Forwarded-For`-Eintrag | Migration 15, `split_part(..., ',', -1)` | bestaetigt |
| Transiente Verarbeitung als `inet` | Migration 15, `v_client_ip inet` | bestaetigt |
| Unkeyed SHA-256 mit Praefix `scanfair-public-read-rate-v1\|` | Migration 15, `extensions.digest(...)` | bestaetigt |
| Gespeicherte Felder `subject_hash`, `window_started_at`, `request_count`, `expires_at` | Migration 14/15 | bestaetigt |
| 30 Anfragen pro Minute, danach 429 | Migration 15, `v_request_count > 30` | bestaetigt |
| Ablauf eine Stunde nach Fensterbeginn | Migration 14 Check-Constraint, Migration 15 Insert | bestaetigt |
| Cleanup alle fuenf Minuten, maximal 10.000 Zeilen | Migration 14, `cron.schedule('*/5 * * * *')`, `limit 10000` | bestaetigt |
| Tabelle fuer `public`, `anon`, `authenticated`, `service_role` gesperrt | Migration 14 und 15, `revoke all` | bestaetigt |
| Nur POST auf drei RPC-Pfade | Migration 15, Pfadliste und 405 | bestaetigt |
| Fehlende/ungueltige IP fuehrt zu 403 | Migration 15, `public_read_identity_unavailable` | bestaetigt |
| 53 pgTAP- und 292 HTTP-Assertions | [2026-09-23-public-read-http-validation.md](2026-09-23-public-read-http-validation.md) | bestaetigt |

## Befunde und Disposition

| ID | Schwere | Befund | Disposition |
| --- | --- | --- | --- |
| PRP-01 | hoch | Das Privacy-Inventar (Stand 17.08.) und der Datenfluss beschrieben die Rate-Limit-Verarbeitung nicht, obwohl der Reviewer genau dieses Inventar prueft und hasht. | `PRV-008` mit transienten, gespeicherten und nie gespeicherten Feldern, Restrisiken und Implementierungsreferenzen ergaenzt; `retention_contract.remote_public_read_rate_windows` trennt logischen Ablauf, physische Loeschung und unbegrenzte Verzoegerung bei Ausfall; Datenfluss um eigenes Diagramm erweitert. |
| PRP-02 | hoch | Das DPIA-Gate pruefte nur `decision_status: approved`. Eine Evidenz mit `decision: dpia_required` haette das Gate entsperrt (fail-open). | Vertrag `dpia_screening` verlangt `decision: dpia_not_required` und `assessed_by_role: qualified_data_protection_counsel`; Negativtest ergaenzt. |
| PRP-03 | mittel | Eine nur auf den Rate-Limiter begrenzte Freigabe haette `reviews.remote_legal_basis` bzw. `dpia.remote_or_beta_scope` auf `approved` setzen muessen, die das ganze Remote-Backend inklusive PRV-007 abdecken. | Eigene Eintraege `reviews.public_read_rate_limit_legal_basis` und `dpia.public_read_rate_limit_scope` mit `required_scope: remote_backend_public_read_rate_limit`; das Gate prueft den Scope der Evidenz und verlangt beide Eintraege im `remote_backend`-Profil; Negativtest fuer falschen Scope. |
| PRP-04 | mittel | README liess Hashes vor der Inventar-Aenderung bilden; die Evidenz waere danach nie hash-gleich gewesen. | Reihenfolge korrigiert und Abgrenzung zwischen dem vom Reviewer gesehenen und dem finalen Inventar-Hash per `git diff` dokumentiert. |
| PRP-05 | niedrig | Zwei Migrationspfade in der README zeigten eine Verzeichnisebene zu hoch ins Leere. | Pfade korrigiert, pgTAP-Datei ergaenzt. |
| PRP-06 | niedrig | `reviewed_commit` und Reviewer-Identitaet standen in den Vorlagen, wurden vom Gate aber nicht verlangt. | Als Pflichtfelder in `legal_review` und `dpia_screening` aufgenommen. |
| PRP-08 | hoch | PR-Review (Codex): Evidenz mit Platzhaltern, Null-Commit, fehlender Qualifikation/Signatur, offenen `conditions` oder einem im Dokument angekreuzten `approved_with_conditions` haette das `remote_backend`-Profil passiert. | Vertraege verlangen Qualifikation und Signaturreferenz, echte 40-stellige Commit-SHA, leere `conditions` und genau die geforderte angekreuzte Entscheidung im gehashten Dokument; Platzhalter werden abgelehnt; acht neue Assertions. |
| PRP-07 | niedrig | Moegliche rohe IP-Adressen in API-Gateway-Logs des Providers waren nicht als Restrisiko genannt. | In `PRV-008.residual_risks`, Datenfluss sowie Review- und DPIA-Vorlage aufgenommen. |

Zusaetzlich gilt: Ist das Remote-Backend aktiviert, muss `PRV-008` ebenfalls
aktiviert und ohne offene Marker beschrieben sein; `PRV-008` muss den Verzicht
auf Raw-IP-Speicherung und die Einstufung als pseudonym dokumentieren.

## Ergebnisse

| Pruefung | Ergebnis |
| --- | --- |
| `test_claims_privacy_gate.rb` | 34 Assertions PASS (vorher 18; 16 neue Assertions inklusive PRP-08) |
| G-PRIVACY-BOUNDARY `development` | PASS |
| G-PRIVACY-BOUNDARY `external_beta` | EXPECTED FAIL, fehlende qualifizierte Reviews |
| G-PRIVACY-BOUNDARY `remote_backend` | EXPECTED FAIL, u.a. `PRV-008 must be enabled`, `public_read_rate_limit_legal_basis status must be approved`, `DPIA screening decision for public_read_rate_limit_scope is not approved` |
| G-BACKEND-BOUNDARY `development` | PASS |
| G-BACKEND-BOUNDARY `remote_backend` | EXPECTED FAIL, u.a. `public read rate limit must be remotely verified and privacy-approved` |
| Ticket-Gate-Selbsttests | 22 Tests, 58 Assertions PASS |
| PR-Ticket-Bindung-Selbsttests | 10 Tests, 29 Assertions PASS |
| Development Quality Pipeline | 33/33 PASS |

## Pipeline

`LC_ALL=en_US.UTF-8 bash scripts/quality/run_quality_gates.sh` am 2026-09-24:
33/33 Gates PASS, 144/144 Flutter-Tests, Line-Coverage 84,74 Prozent.

Der erste Lauf scheiterte an G-PROJECT-CONTROL: Der Selbsttest
`test_done_without_completion_and_evidence_fails` setzte TKT-037-01 auf `done`
und erwartete zusaetzlich fehlende Ticket-Evidenz. Da das Ticket nun echte
Evidenz besitzt, leert der Test die Evidenz in seiner Mutation selbst und
prueft damit weiterhin beide Negativbedingungen.

Nicht ausgefuehrt: Datenbank-Replay und HTTP-Suite, weil weder SQL noch
Runtime-Code geaendert wurden (Docker lief nicht). Die Werte 53/53 pgTAP und
292 HTTP-Assertions stammen aus dem Nachweis vom 23.09.2026 auf dem
unveraenderten Migrationsstand.

## Akzeptanzkriterien TKT-037-01

- AC-01 erfuellt: `PRV-008`, `retention_contract.remote_public_read_rate_windows`
  und Datenfluss stimmen mit Migrationen 14/15 und dem Umgebungsvertrag ueberein.
- AC-02 offen: qualifizierte menschliche Entscheidung steht aus.
- AC-03 erfuellt: Raw-IP-Verbot, Pseudonym, Minutenfenster, Zaehler und
  einstuendiger Ablauf sind dokumentiert; Loeschfrist, Cron-Verzoegerung und
  Batch-/Ausfallrisiko sind getrennt ausgewiesen.
- AC-04 erfuellt: fehlende Freigaben blockieren `remote_backend` in
  G-PRIVACY-BOUNDARY und G-BACKEND-BOUNDARY; jede Entscheidung ausser
  `approved` bzw. `dpia_not_required` wird abgelehnt.

## Nachtrag 2026-09-24: geschluesseltes Pseudonym

Nach diesem Bericht wurde das unkeyed SHA-256-Pseudonym als praktisch umkehrbar
eingestuft (PRP-08, hoch) und in TKT-037-06 durch ein HMAC mit stuendlich
rotierendem, danach geloeschtem Zufallsschluessel ersetzt. Die oben genannten
Restrisiken zum unkeyed Hash gelten fuer Migration 16 nicht mehr; Inventar,
Datenfluss und Review-Paket wurden nachgezogen. Details:
[2026-09-24-keyed-rate-pseudonym-validation.md](2026-09-24-keyed-rate-pseudonym-validation.md).
TKT-037-01 ist bis zum Abschluss von TKT-037-06 geparkt.
