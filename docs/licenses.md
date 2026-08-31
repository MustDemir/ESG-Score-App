# Lizenzen & Attribution — ScanFair

## Produktdaten

### Open Food Facts
Produktdatenbank: **Open Database License (ODbL) v1.0**
Einzelne Datenbankinhalte: **Database Contents License (DbCL) v1.0**
Produktbilder: **Creative Commons Attribution-ShareAlike 3.0 (CC BY-SA 3.0)**

Pflicht-Attribution in der App:
> Enthaelt Informationen aus Open Food Facts, die unter der Open Database
> License (ODbL) v1.0 verfuegbar sind. Open Food Facts contributors.

Lizenztexte:

- ODbL 1.0: https://opendatacommons.org/licenses/odbl/1-0/
- DbCL 1.0: https://opendatacommons.org/licenses/dbcl/1-0/
- CC BY-SA 3.0: https://creativecommons.org/licenses/by-sa/3.0/

ScanFair behandelt die Ergebnisansicht konservativ als **Produced Work** und
einen OFF-Roh- oder Normalisierungscache als **Derivative Database**. Der
quellengetrennte Evidenzindex ist ein **Collective Database**-Kandidat. Diese
Engineering-Klassifikation ersetzt kein qualifiziertes Rechtsreview.

Der generische Produktcache akzeptiert ausschliesslich OFF-Daten. Weitere
Rohdatensaetze brauchen getrennte Speicher. Ein Remote-Backend bleibt durch
`G-DATA-LICENSE` blockiert, bis Share-Alike-Export, Korrektur/Loeschung und
qualifiziertes Rechtsreview nachgewiesen sind. Produktbilder werden nicht
dauerhaft in einem Remote-Cache gespeichert, solange deren Wiederverwendung
nicht separat freigegeben ist.

### AGRIBALYSE

Umwelt-LCA-Daten: **Etalab Open Licence 2.0**

Attribution:
> Source ADEME, AGRIBALYSE v3.2

Die Lizenz erlaubt Anpassung, abgeleitete Informationen und kommerzielle
Nutzung mit Quellen- und Aktualitaetsangabe. ScanFair fuehrt AGRIBALYSE
in einem eigenen Lizenzspeicher getrennt von der ODbL-Produktdatenbank und
kennzeichnet Open Food Facts
als Retrieval-Channel. Die Werte sind Kategorieproxies und keine gemessenen
Markenprodukt-Fussabdruecke.

## Eingeschraenkte Quellen

GEPA-Produktpublikationen werden nicht als Datenbank oder Dokumentkopie
weitergegeben. ScanFair speichert fuer den Kaffee-Referenzfall nur extrahierte
Tatsachenbehauptungen, URL, Hash, Abrufzeit und die Kennzeichnung als
Herstellerangabe. Bilder und Publikationsinhalte duerfen ohne gesonderte
Erlaubnis nicht in einen oeffentlichen Cache uebernommen werden.

## Schriften

Die App liefert alle verwendeten Schnitte lokal aus und deaktiviert
Runtime-Fetching. Dadurch entsteht beim App-Start kein zusaetzlicher Abruf bei
Google Fonts.

| Schrift | Lizenz | Lokaler Nachweis |
| --- | --- | --- |
| Inter Regular, SemiBold, Bold | SIL Open Font License 1.1 | `esg_app/assets/fonts/licenses/Inter-OFL.txt` |
| Instrument Serif Regular | SIL Open Font License 1.1 | `esg_app/assets/fonts/licenses/InstrumentSerif-OFL.txt` |

Quell-URLs und SHA-256-Prüfsummen stehen im versionierten
[`font-assets.yaml`](project/compliance/font-assets.yaml).

## Code-Abhängigkeiten
Wird bei `flutter pub deps` automatisch in `esg_app/pubspec.lock` festgehalten.
Volle Liste mit Lizenzen via `flutter pub deps --style=compact`.

## Design-System
Eigenentwicklung (Tokens in `design_handoff_scanfair/tokens.css`). Keine fremden Lizenzen.
