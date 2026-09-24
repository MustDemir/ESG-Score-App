# Vorfall: Migrationen 14 bis 16 per Auto-Deploy vor Privacy-Freigabe remote angewandt

- Datum der Feststellung: 2026-09-24
- Betroffenes Projekt: `scanfair-dev` (Supabase, eu-central-1, Development)
- Tickets: TKT-037-01 (Privacy-Entscheidung), TKT-037-02 (Remote-Anwendung),
  TKT-037-03 (Remote-Verifier)
- Schwere: mittel fuer Governance, gering fuer Betroffene (kein App-Traffic)

## Was passiert ist

Die Projektsteuerung trennt „in `main` gemergt“ von „remote angewandt“: Die
Migrationen 14 bis 16 sollten erst nach der qualifizierten Privacy-Entscheidung
kontrolliert in TKT-037-02 angewandt werden. Das Repository ist jedoch mit der
**Supabase-GitHub-Integration** verbunden (Check „Supabase Preview“, App
`supabase`). Sie wendet bei jedem Push auf `main` neue Dateien aus
`supabase/migrations/` auf das verknuepfte Projekt an.

| Zeitpunkt (UTC) | Merge | Remote angewandt |
| --- | --- | --- |
| 2026-09-23 08:41 | PR 35, `65b9463` | Migrationen 14 (`20260906000100`) und 15 (`20260923000100`) |
| 2026-09-24 06:16 | PR 38, `f7073cb` | Migration 16 (`20260924000100`) |

Der Merge von PR 38 erfolgte in dieser Session, ohne vorher zu pruefen, ob ein
Merge remote deployt. Die Projektdokumentation fuehrte die Migrationen
bis zu dieser Feststellung als „remote nicht angewandt“.

## Feststellung

`supabase migration list --linked` am 2026-09-24 zeigt 16/16 Migrationen lokal
und remote. Eine rein lesende Abfrage (`supabase db query --linked`, nur
`SELECT`, nur Anzahlen) ergab:

| Pruefpunkt | Ergebnis |
| --- | --- |
| `pgrst.db_pre_request` fuer `authenticator` | `public.enforce_public_read_rate_limit` (aktiv) |
| `private.public_read_rate_windows` | vorhanden, 0 Zeilen |
| `private.public_read_rate_keys` | vorhanden, 0 Zeilen |
| Cron `scanfair-public-read-rate-cleanup` | aktiv, `*/5 * * * *`, 264 Laeufe, 0 Fehlschlaege |
| `public.cached_products` | 0 Zeilen |
| `private.writer_audit_log` | 0 Zeilen |

## Bewertung

- **Betroffene:** Die App ist nicht veroeffentlicht (kein App Store, keine
  TestFlight-Beta) und ruft Supabase nur auf, wenn sie mit
  `SCANFAIR_SUPABASE_URL` gebaut wird; standardmaessig fragt sie Open Food Facts
  direkt. Der Cache ist leer, die geschuetzten RPCs liefern daher nichts. Echte
  Nutzerdaten wurden sehr wahrscheinlich nicht verarbeitet.
- **Grenze der Aussage:** Zaehlerzeilen und Schluessel werden nach etwa einer
  Stunde geloescht. Anfragen vor der Abfrage lassen sich aus der Datenbank nicht
  ausschliessen, nur ueber die API-Logs im Supabase-Dashboard, deren
  Aufbewahrung planabhaengig kurz ist.
- **Governance:** Die Verarbeitung ist technisch aktiv, bevor die
  Privacy-Entscheidung vorliegt. Das widerspricht dem vorgesehenen Ablauf und
  wird der pruefenden Person im Review-Paket offengelegt.
- **Positiv:** Remote laeuft bereits das geschluesselte, stuendlich rotierende
  Pseudonym aus Migration 16, nicht mehr der umkehrbare unkeyed Hash.

## Entscheidungen und Massnahmen

1. Mustafa Demir behaelt das Auto-Deploy bei (2026-09-24). Jeder Merge, der
   eine Migration enthaelt, wird kuenftig vorab ausdruecklich als
   Remote-Deployment bestaetigt.
2. Umgebungsvertrag, Threat Model, ADR 0040, Privacy-Inventar, Datenfluss,
   Review-Paket, TKT-037-02, `progress.yaml` und STATUS fuehren den echten
   Remote-Stand. G-BACKEND-BOUNDARY kennt dafuer den Zustand
   `remote_applied_by_auto_deploy_privacy_pending` / `APPLIED_NOT_VERIFIED`;
   das `remote_backend`-Profil verlangt unveraendert Verifikation und Freigabe.
3. Der Hook bleibt vorerst aktiv. Eine Abschaltung waere ebenfalls nur ueber
   eine Migration und damit einen weiteren Merge moeglich.
4. Offen: Remote-Verifikation (TKT-037-03) inklusive Hosted-Proxy-Kette sowie
   die qualifizierte Privacy-Entscheidung (TKT-037-01).
