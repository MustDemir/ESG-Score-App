# DPIA-Screening – pseudonymisierte IP-Rate-Limit-Daten

> Getrennte qualifizierte Entscheidung zur Schwelle des Art. 35 DSGVO. Ein
> Ergebnis `dpia_not_required` muss ebenso begruendet werden wie die Pflicht zur
> Durchfuehrung einer Datenschutz-Folgenabschaetzung.

## 1. Metadaten und Bindung

- Ticket: `TKT-037-01`
- Screening-ID: `[EINTRAGEN]`
- Gepruefter Commit: `[VOLLSTAENDIGE GIT-SHA EINTRAGEN]`
- Datum und Uhrzeit mit Zeitzone: `[YYYY-MM-DDThh:mm:ss+hh:mm]`
- Pruefende Person: `[EINTRAGEN]`
- Rolle: `qualified_data_protection_counsel`
- Qualifikation: `[EINTRAGEN]`
- Scope: `remote_backend_public_read_rate_limit`
- SHA-256 des finalen Privacy-Inventars: `[EINTRAGEN]`
- Verknuepfte Privacy-Entscheidung: `[PFAD/REVIEW-ID EINTRAGEN]`

## 2. Verarbeitung in Kurzform

Kurzzeitige Verarbeitung der vom letzten vertrauten Ingress beobachteten
IP-Adresse, Bildung eines unkeyed SHA-256-Pseudonyms mit oeffentlichem
Praefix, minutenweiser Zaehler fuer maximal 30 Anfragen und geplante Loeschung
ab einer Stunde ueber einen begrenzten Fuenf-Minuten-Cleanup. Keine rohe IP in
der Zaehler-Tabelle, aber Offline-Pruefbarkeit von IP-Kandidaten und
Verknuepfbarkeit gleicher Adressen ueber Fenster. Keine Nutzerkonten,
Standortdaten, besonderen Datenkategorien oder Entscheidungen ueber Personen im
gebundenen Scope.

Korrekturen oder Ergaenzungen des Reviewers: `[EINTRAGEN]`

## 3. Art.-35-Schwelle

1. Ist die Verarbeitung voraussichtlich mit einem hohen Risiko fuer Rechte und
   Freiheiten natuerlicher Personen verbunden? `[ja/nein/unklar + Begruendung]`
2. Trifft einer der ausdruecklichen Faelle des Art. 35 Abs. 3 zu?
   `[EINTRAGEN]`
3. Welche nationale Positiv-/Negativliste der zustaendigen Aufsichtsbehoerde
   wurde geprueft, in welcher Fassung und mit welchem Ergebnis? `[EINTRAGEN]`

## 4. Strukturierte Kriterienpruefung

| Kriterium | trifft zu? | Begruendung und Nachweis |
| --- | --- | --- |
| systematische Bewertung oder Scoring von Personen | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| automatisierte Entscheidung mit rechtlicher/aehnlich erheblicher Wirkung | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| systematische Ueberwachung | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| besondere oder hoechstpersoenliche Daten | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| Verarbeitung in grossem Umfang | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| Abgleich oder Zusammenfuehrung von Datensaetzen | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| schutzbeduerftige Betroffene, insbesondere Kinder | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| innovative Technologie/organisatorische Loesung | `[ja/nein/unklar]` | `[EINTRAGEN]` |
| Verhinderung der Rechts- oder Dienstnutzung | `[ja/nein/unklar]` | `[EINTRAGEN]` |

Bewertung der Anzahl und Kombination zutreffender Kriterien: `[EINTRAGEN]`

## 5. Risikobetrachtung

Mindestens zu bewerten:

- Offline-Pruefung moeglicher IP-Adressen gegen den unkeyed Hash;
- Verkettung gleicher IPs ueber Minutenfenster;
- gemeinsame IPs/NAT und fehlerhafte Zuordnung mehrerer Personen;
- Umgehung oder Fehlklassifikation durch die Hosted-Proxy-Kette;
- Blockierung legitimer Anfragen durch 403/429;
- verlaengerte Speicherung bei Cleanup-Ausfall oder Rueckstau;
- rohe IP-Adressen in API-Gateway-Logs des Providers (Aufbewahrung unbestaetigt);
- unbefugter Datenbankzugriff oder privilegierter Missbrauch;
- moegliche Nutzung durch Kinder und andere schutzbeduerftige Personen.

| Risiko | Eintritt | Schwere | bestehende Massnahmen | Restrisiko |
| --- | --- | --- | --- | --- |
| `[EINTRAGEN]` | `[EINTRAGEN]` | `[EINTRAGEN]` | `[EINTRAGEN]` | `[EINTRAGEN]` |

## 6. Entscheidung

Genau eine Option markieren:

- `[ ] dpia_not_required` – kein voraussichtlich hohes Risiko; Begruendung unten
- `[ ] dpia_required` – vollstaendige DPIA vor jeder Aktivierung erforderlich
- `[ ] prior_consultation_to_assess` – Art.-36-/Aufsichtsbehoerdenpfad pruefen
- `[ ] more_information_required` – Schwelle noch nicht entscheidbar

Begruendung: `[EINTRAGEN]`

Falls `dpia_not_required`: Welche Aenderungen oder Schwellen loesen ein neues
Screening aus? `[EINTRAGEN]`

Falls `dpia_required`: Owner, Umfang, offene Nachweise und Aktivierungsblocker:
`[EINTRAGEN]`

## 7. Bestaetigung

- Name: `[EINTRAGEN]`
- Datum: `[EINTRAGEN]`
- Signatur oder nachvollziehbarer Freigabemechanismus: `[EINTRAGEN]`
- Referenz auf signierte/externe Originalfassung: `[EINTRAGEN]`
