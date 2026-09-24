# Privacy-Entscheidung – pseudonymisierte IP-Rate-Limit-Daten

> Vorlage fuer eine qualifizierte menschliche Datenschutzpruefung. Alle
> Auswahlfelder muessen aktiv ausgefuellt werden. Unausgefuellte Felder und
> Bedingungen blockieren die Remote-Aktivierung.

## 1. Review-Metadaten

- Ticket: `TKT-037-01`
- Review-ID: `[EINTRAGEN]`
- Gepruefter Commit: `[VOLLSTAENDIGE GIT-SHA EINTRAGEN]`
- Datum und Uhrzeit mit Zeitzone: `[YYYY-MM-DDThh:mm:ss+hh:mm]`
- Name der pruefenden Person: `[EINTRAGEN]`
- Organisation: `[EINTRAGEN]`
- Rolle: `qualified_data_protection_counsel`
- Qualifikationsnachweis oder kurze Begruendung der Fachkunde: `[EINTRAGEN]`
- Unabhaengigkeit/Interessenkonflikte: `[EINTRAGEN]`
- Verantwortlicher/Decision Owner: `Mustafa Demir`
- Geltungsbereich: `remote_backend_public_read_rate_limit`

## 2. Gebundene Eingangsunterlagen

Die pruefende Person bestaetigt, mindestens folgende finale Staende gelesen zu
haben. Fuer jedes Dokument sind Pfad, Version/Commit und SHA-256 einzutragen.

| Unterlage | Version/Commit | SHA-256 | Geprueft |
| --- | --- | --- | --- |
| Privacy-Dateninventar | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |
| Privacy-Datenfluss | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |
| ADR 0040 | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |
| EU-Supabase-Umgebungsvertrag | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |
| HTTP-/Retention-Nachweis vom 23.09.2026 | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |
| Migration 14 | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |
| Migration 15 | `[EINTRAGEN]` | `[EINTRAGEN]` | `[ja/nein]` |

## 3. Technischer Sachverhalt zur Bestaetigung

Die vorgesehene Funktion schuetzt drei oeffentliche POST-RPCs mit 30 Anfragen
pro IP und Minute. Die finale, durch den vertrauten Ingress angehaengte
X-Forwarded-For-Adresse wird kurzzeitig als `inet` verarbeitet. Die rohe
IP-Adresse wird nicht in der Rate-Limit-Tabelle gespeichert.

Gespeichert werden in `private.public_read_rate_windows`:

- `subject_hash`: 64-stelliges SHA-256-Pseudonym aus dem oeffentlichen
  konstanten Praefix `scanfair-public-read-rate-v1|` und der normalisierten IP;
- `window_started_at`: Beginn des Minutenfensters;
- `request_count`: Anzahl der Anfragen im Minutenfenster;
- `expires_at`: exakt eine Stunde nach Beginn des Minutenfensters.

Die Tabelle ist fuer `public`, `anon`, `authenticated` und `service_role`
gesperrt. Ein `security definer`-Hook schreibt den Zaehler. Ein als `postgres`
laufender Cronjob loescht alle fuenf Minuten hoechstens 10.000 abgelaufene
Zeilen. Bei Scheduler-Ausfall oder Rueckstau existiert keine harte maximale
physische Loeschfrist. Der Hash ist nicht geheim geschluesselt; IP-Kandidaten
koennen offline geprueft und gleiche Adressen ueber Minutenfenster verknuepft
werden. Deshalb ist der Datensatz als pseudonym, nicht anonym, zu behandeln.
Unabhaengig von dieser Tabelle koennen API-Gateway-Logs des Providers rohe
IP-Adressen enthalten; deren Aufbewahrung ist noch nicht vom Provider
bestaetigt. Die maschinenlesbare Beschreibung ist `PRV-008` im
Privacy-Inventar.

Sachverhalt aus Sicht des Reviewers:

- `[ ]` vollstaendig und zutreffend
- `[ ]` nur mit folgenden Korrekturen zutreffend: `[EINTRAGEN]`
- `[ ]` fuer eine Entscheidung nicht ausreichend: `[EINTRAGEN]`

## 4. Rollen, Betroffene und Verarbeitung

1. Wer ist fuer Zweck und Mittel dieser Verarbeitung Verantwortlicher?
   `[EINTRAGEN]`
2. Welche Rolle hat Supabase fuer den konkreten Scope? Muss der DPA-/AVV-Scope
   vor Aktivierung ergaenzt oder anders bewertet werden? `[EINTRAGEN]`
3. Welche weiteren Empfaenger, Unterauftragsverarbeiter oder Drittlandbezuege
   sind tatsaechlich betroffen? `[EINTRAGEN]`
4. Welche Kategorien betroffener Personen sind umfasst, insbesondere Kinder
   oder andere schutzbeduerftige Personen? `[EINTRAGEN]`
5. Bestaetigte Datenkategorie und Personenbezug: `[EINTRAGEN]`

## 5. Zweck, Rechtsgrundlage und Interessenabwaegung

Vorgesehener Zweck: Schutz der oeffentlichen Produkt-RPCs vor Missbrauch,
Enumeration und Erschoepfung gemeinsamer Ressourcen.

1. Ist der Zweck spezifisch, legitim und hinreichend dokumentiert?
   `[ja/nein + Begruendung]`
2. Gewaehlte Rechtsgrundlage nach Art. 6 DSGVO: `[EINTRAGEN]`
3. Falls Art. 6 Abs. 1 lit. f herangezogen wird:
   - berechtigtes Interesse: `[EINTRAGEN]`
   - Erforderlichkeit fuer dieses Interesse: `[EINTRAGEN]`
   - Interessen, Rechte und Freiheiten der Betroffenen: `[EINTRAGEN]`
   - besondere Bewertung fuer Kinder: `[EINTRAGEN]`
   - Ergebnis der Abwaegung: `[EINTRAGEN]`
4. Ist eine andere Rechtsgrundlage einschlaegig oder vorzugswuerdig?
   `[EINTRAGEN]`
5. Ist der Zweck mit einer spaeteren Weiterverarbeitung oder Korrelation
   vereinbar? Welche Nutzungen sind ausdruecklich zu verbieten? `[EINTRAGEN]`

## 6. Erforderlichkeit und Verhaeltnismaessigkeit

Fuer jede Alternative ist zu begruenden, warum sie ausreicht oder nicht
ausreicht:

| Variante | Bewertung | Begruendung/Nachweis |
| --- | --- | --- |
| Kein serverseitiges Rate Limit | `[EINTRAGEN]` | `[EINTRAGEN]` |
| Nur fluechtiger/In-Memory-Zaehler | `[EINTRAGEN]` | `[EINTRAGEN]` |
| Kuerzere Speicher-/Ablauffrist | `[EINTRAGEN]` | `[EINTRAGEN]` |
| Geheimnisgebundener HMAC statt unkeyed SHA-256 | `[EINTRAGEN]` | `[EINTRAGEN]` |
| Regelmaessig rotierender geheimer Schluessel | `[EINTRAGEN]` | `[EINTRAGEN]` |
| Provider-/Gateway-Limiter ohne eigene Persistenz | `[EINTRAGEN]` | `[EINTRAGEN]` |
| Aktuelle Architektur | `[EINTRAGEN]` | `[EINTRAGEN]` |

Abschliessende Bewertung von Datenminimierung, Zugriff, Verkettbarkeit,
Missbrauchsrisiko und Verhaeltnismaessigkeit: `[EINTRAGEN]`

## 7. Speicherbegrenzung und Loeschung

1. Ist die fachliche Ablaufzeit von einer Stunde erforderlich und
   verhaeltnismaessig? `[EINTRAGEN]`
2. Ist die physische Loeschung bei gesundem Betrieb spaetestens im naechsten
   Fuenf-Minuten-Lauf ausreichend? `[EINTRAGEN]`
3. Welche maximale Loeschverzoegerung ist bei Rueckstau oder Ausfall zulaessig?
   `[EINTRAGEN]`
4. Sind zusaetzliche Alarme, Backlog-Grenzen, Notfall-Loeschung oder eine harte
   Loesch-SLA vor Aktivierung erforderlich? `[EINTRAGEN]`
5. Welche Nachweise muessen fuer laufende Wirksamkeit aufbewahrt werden, ohne
   neue personenbezogene Telemetrie zu erzeugen? `[EINTRAGEN]`

## 8. Transparenz und Betroffenenrechte

1. Muss der oeffentliche Datenschutzhinweis die kurzfristige Verarbeitung der
   rohen IP, das Pseudonym, Zweck, Rechtsgrundlage, Empfaenger, Region,
   Speicherkriterien und Widerspruchsrecht ausdruecklich nennen?
   `[EINTRAGEN]`
2. Zu welchem Zeitpunkt und an welcher Stelle muss die Information bereitstehen?
   `[EINTRAGEN]`
3. Wie werden Auskunft, Loeschung, Einschraenkung und Widerspruch praktisch
   bearbeitet, wenn ScanFair den Nutzer nicht direkt identifiziert?
   `[EINTRAGEN]`
4. Darf oder muss der Verantwortliche fuer eine Anfrage zusaetzliche
   Identifikationsdaten verlangen? Welche Datenminimierung gilt dabei?
   `[EINTRAGEN]`
5. Welche Korrekturen an `docs/privacy.md`, App Store Privacy Details und dem
   Verzeichnis der Verarbeitungstaetigkeiten sind vor Aktivierung erforderlich?
   `[EINTRAGEN]`

## 9. Technische und organisatorische Massnahmen

Bewertung der bestehenden Massnahmen nach Art. 25 und 32 DSGVO:

- keine Speicherung der rohen IP: `[EINTRAGEN]`
- private Tabelle und entzogene Rollenrechte: `[EINTRAGEN]`
- fail-closed bei fehlender/ungueltiger Identitaet: `[EINTRAGEN]`
- Bindung an drei explizite RPC-Pfade und POST: `[EINTRAGEN]`
- Pseudonymisierung ohne geheimen Schluessel: `[EINTRAGEN]`
- Cleanup, Monitoring und Stoerungsbehandlung: `[EINTRAGEN]`
- Hosted-Ingress-Vertrauensgrenze: `[EINTRAGEN]`
- verbleibendes Reidentifikations-/Kollusionsrisiko: `[EINTRAGEN]`

Vor Aktivierung zwingend nachzubessernde TOMs: `[EINTRAGEN]`

## 10. Gesamtentscheidung

Genau eine Option markieren:

- `[ ] approved` – fuer den gebundenen Scope ohne offene Aktivierungsbedingung
- `[ ] approved_with_conditions` – Bedingungen sind vor Aktivierung zu schliessen
- `[ ] rejected` – Verarbeitung in dieser Form nicht aktivieren
- `[ ] more_information_required` – Entscheidung noch nicht moeglich

Begruendung der Entscheidung: `[EINTRAGEN]`

Verbindliche Bedingungen oder fehlende Informationen mit Owner und
Abnahmekriterium:

| ID | Bedingung/Information | Owner | Abnahmekriterium | Status |
| --- | --- | --- | --- | --- |
| `[EINTRAGEN]` | `[EINTRAGEN]` | `[EINTRAGEN]` | `[EINTRAGEN]` | `open` |

Naechstes Review-Datum oder Review-Trigger: `[EINTRAGEN]`

## 11. Bestaetigung

Ich bestaetige, dass die Entscheidung den oben hash- und commitgebundenen Scope
betrifft, dass offene Bedingungen nicht als Freigabe gelten und dass
wesentliche Aenderungen an Zweck, Daten, Hashverfahren, Aufbewahrung,
Empfaengern, Regionen, Ingress-Kette oder Betroffenenkategorien ein neues
Review ausloesen.

- Name: `[EINTRAGEN]`
- Datum: `[EINTRAGEN]`
- Signatur oder nachvollziehbarer Freigabemechanismus: `[EINTRAGEN]`
- Referenz auf signierte/externe Originalfassung, falls vorhanden: `[EINTRAGEN]`

Kenntnisnahme durch Decision Owner (keine Ersetzung des Fachreviews):

- Name: `Mustafa Demir`
- Datum: `[EINTRAGEN]`
- Bestaetigung der Umsetzung von Bedingungen: `[EINTRAGEN]`
