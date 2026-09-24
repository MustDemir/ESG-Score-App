# TKT-037-01 – manuelles Privacy-Review-Paket

Dieses Verzeichnis bereitet die qualifizierte menschliche Entscheidung zur
pseudonymisierten IP-Rate-Limit-Verarbeitung vor. Die Vorlagen dokumentieren
den Pruefumfang und erzeugen **keine** automatische Rechtsfreigabe.

## Was Mustafa tun muss

1. Eine fachlich qualifizierte Person fuer Datenschutzrecht beauftragen. Die
   Person muss die Rolle `qualified_data_protection_counsel` fachlich
   ausfuellen koennen; Codex, Vanta und der Engineering-Owner ersetzen diese
   Qualifikation nicht.
2. Der pruefenden Person mindestens diese Unterlagen geben:
   - `privacy-legal-review-template.md`
   - `dpia-screening-template.md`
   - `../../privacy-data-inventory.yaml`
   - `../../privacy-data-flow.md`
   - `../../../decisions/0040-public-read-abuse-protection.yaml`
   - `../../../security/eu-supabase-environment-contract.yaml`
   - `../../../audits/2026-09-23-public-read-http-validation.md`
   - `../../../../../supabase/migrations/20260906000100_public_read_abuse_protection.sql`
   - `../../../../../supabase/migrations/20260923000100_public_read_api_integration.sql`
   - `../../../../../supabase/tests/database/public_read_abuse_protection.test.sql`

   Die Verarbeitung ist im Inventar als `PRV-008` beschrieben; Aufbewahrung
   und Loeschung stehen zusaetzlich unter
   `retention_contract.remote_public_read_rate_windows`.
3. Die pruefende Person fuellt beide Markdown-Vorlagen selbst aus, nennt ihre
   Qualifikation und entscheidet jeweils eindeutig. Offene Felder, bedingte
   Freigaben oder fehlende Informationen bleiben blockierend. Den geprueften
   Commit (`git rev-parse HEAD`) und die Hashes der Eingangsunterlagen traegt
   sie in die Metadaten- bzw. Unterlagen-Abschnitte der Vorlagen ein.
4. Die ausgefuellten Dokumente ohne `-template` speichern.
5. Nur bei einer uneingeschraenkten positiven Entscheidung – Privacy-Review
   `approved` **und** DPIA-Screening `dpia_not_required` – genau diese beiden
   Eintraege im Privacy-Inventar aendern:
   - `reviews.public_read_rate_limit_legal_basis`: `status: approved`,
     `evidence: docs/project/compliance/review/tkt-037-01/privacy-legal-evidence.yaml`
   - `dpia.public_read_rate_limit_scope`: `decision_status: approved`,
     `evidence: docs/project/compliance/review/tkt-037-01/dpia-evidence.yaml`

   `reviews.remote_legal_basis` und `dpia.remote_or_beta_scope` bleiben
   unveraendert: Sie decken das gesamte Remote-Backend inklusive PRV-007 ab
   und brauchen eine eigene Entscheidung. `approved_with_conditions`,
   `rejected`, `more_information_required`, `dpia_required` und
   `prior_consultation_to_assess` duerfen kein Gate entsperren; das Gate lehnt
   jede andere DPIA-Entscheidung als `dpia_not_required` ab.
6. **Erst nach Schritt 5** die SHA-256-Werte bilden (siehe unten) und in Kopien
   der beiden Evidenzvorlagen eintragen. Wer vorher hasht, bekommt einen
   Hash-Mismatch, weil Schritt 5 das Inventar veraendert. Das Gate lehnt
   Evidenz ab, wenn ein Platzhalter (`[...]`, `YYYY`) stehen bleibt,
   `reviewed_commit` kein vollstaendiger Git-SHA ist, Qualifikation oder
   Signaturreferenz fehlen, `conditions` nicht leer ist oder im gehashten
   Dokument nicht genau `[x] approved` bzw. `[x] dpia_not_required`
   angekreuzt ist.
7. Danach die Development- und strengen Privacy-/Backend-Gates ausfuehren. Die
   Migrationen 14 und 15 sowie die Remote-Runtime bleiben bis zu einem
   vollstaendigen positiven Ergebnis unveraendert blockiert. Das
   `remote_backend`-Profil verlangt zusaetzlich, dass `PRV-008` aktiviert und
   ohne offene Marker (`pending`, `release_blocker`, …) beschrieben ist.

## Empfohlene finale Dateinamen

- `privacy-legal-review.md`
- `privacy-legal-evidence.yaml`
- `dpia-screening.md`
- `dpia-evidence.yaml`

Die finalen Evidenzdateien sollen nicht aus einer Vorlage mit bereits gesetztem
`approved`-Status erzeugt werden. Der Status wird erst nach der tatsaechlichen
Unterschrift beziehungsweise einer gleichwertig nachvollziehbaren Freigabe
eingetragen.

## Hash-Bindung

Die beiden Evidenzdateien muessen auf den **finalen** Stand des
Privacy-Inventars und des jeweils ausgefuellten Review-Dokuments zeigen:

```sh
shasum -a 256 docs/project/compliance/privacy-data-inventory.yaml
shasum -a 256 docs/project/compliance/review/tkt-037-01/privacy-legal-review.md
shasum -a 256 docs/project/compliance/review/tkt-037-01/dpia-screening.md
```

Nach jeder inhaltlichen Aenderung am Inventar oder Review-Dokument sind die
Hashes neu zu bilden und die Entscheidung gegebenenfalls erneut zu bestaetigen.

Der Inventar-Hash, den die pruefende Person in Abschnitt 2 festhaelt, gehoert
zum Stand **vor** Schritt 5. Der finale Hash in der Evidenzdatei weicht davon
ab. Zulaessig ist das nur, wenn sich das Inventar zwischen `reviewed_commit`
und dem finalen Stand ausschliesslich in den vier Feldern aus Schritt 5
unterscheidet:

```sh
git diff <reviewed_commit> -- docs/project/compliance/privacy-data-inventory.yaml
```

Jede weitere Abweichung erfordert eine erneute Bestaetigung.

## Bekannte Vorbedingungen und Blocker

- Die gespeicherte Kennung ist ein unkeyed SHA-256-Pseudonym mit oeffentlichem
  konstantem Praefix; sie ist nicht anonym und erlaubt Offline-Pruefungen von
  IP-Kandidaten sowie Verknuepfung ueber Minutenfenster.
- `expires_at` liegt eine Stunde nach Fensterbeginn. Physische Loeschung erfolgt
  durch einen Fuenf-Minuten-Cronjob mit maximal 10.000 Zeilen je Lauf. Bei
  Rueckstau oder Ausfall besteht derzeit keine garantierte maximale
  Verweildauer.
- Die Hosted-Proxy-Kette und die Zuordnung unterschiedlicher Clients sind noch
  nicht remote verifiziert.
- Die vollstaendige Postanschrift des Verantwortlichen ist im Privacy-Inventar
  weiterhin als Release-Blocker markiert.
- DPA, Unterauftragsverarbeiter, Betroffenenrechte und produktive
  Transparenztexte bleiben eigenstaendige Aktivierungsvoraussetzungen.

## Normative Ausgangspunkte

- DSGVO Art. 5, 6, 13, 25, 32 und 35:
  <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- EDPB/WP29-Leitlinien zur Datenschutz-Folgenabschaetzung, WP248 rev.01:
  <https://www.edpb.europa.eu/endorsed-wp29-guidelines_en>
- BfDI, Datenschutz-Folgenabschaetzung:
  <https://www.bfdi.bund.de/DE/Fachthemen/Inhalte/Technik/Datenschutz-Folgenabschaetzungen.html>

Die Quellen sind Ausgangspunkte fuer die qualifizierte Pruefung und keine durch
das Projekt vorweggenommene Rechtsauslegung.
