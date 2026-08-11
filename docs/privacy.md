# Datenschutzerklärung - ScanFair

*Interner Entwurf für die lokale Entwicklung · Stand: 2026-08-11 · Deutsch*

> Dieser Text beschreibt den aktuellen lokalen iOS-MVP. Er ist noch nicht für
> eine externe Beta oder Veröffentlichung freigegeben. Postanschrift,
> Rechtsgrundlagen, Provider-Rollen, App-Privacy-Angaben und die finale Fassung
> müssen vor externer Nutzung qualifiziert geprüft werden.

## Verantwortlicher

Mustafa Demir

[Postanschrift vor externer Beta zu ergänzen]

business.demir@gmail.com

## Aktuell verarbeitete Daten

### Kamera und Barcode-Erkennung

Die Kamera wird nur nach Ihrer iOS-Freigabe für die lokale Barcode-Erkennung
verwendet. ScanFair speichert oder überträgt keine Kamerabilder. Der Scanner
gibt keine Bilddaten an die App zurück und wird nach einem Scan oder beim
Verlassen des Scanner-Bildschirms gestoppt. Alternativ kann ein Barcode manuell
eingegeben werden.

### Produktanfrage bei Open Food Facts

Nach einem Scan oder einer manuellen Eingabe sendet die App den Barcode per
HTTPS direkt an Open Food Facts (`world.openfoodfacts.org`). Dabei können Open
Food Facts und beteiligte Netzbetreiber technisch notwendige Netzwerkdaten wie
die IP-Adresse und den Zeitpunkt der Anfrage verarbeiten. ScanFair fügt der
Anfrage keine Konto-, Werbe- oder Gerätekennung hinzu.

Die genaue datenschutzrechtliche Rollenverteilung, Rechtsgrundlage, Region und
Speicherdauer bei Open Food Facts wird vor einer externen Beta qualifiziert
geprüft. Die Antwort enthält öffentliche Produktinformationen, die ScanFair auf
dem Gerät verarbeitet.

### Laufzeitspeicher und Scan-Verlauf

ScanFair hält höchstens zehn zuletzt geladene Produktobjekte im flüchtigen
Laufzeitspeicher. Sie werden nicht als Scan-Verlauf dauerhaft gespeichert und
mit dem Ende des App-Prozesses gelöscht. Im aktuellen MVP gibt es weder ein
ScanFair-Konto noch einen ScanFair-Cloudspeicher.

### Telemetrie und weitere Funktionen

Im aktuellen MVP sind keine Analytics-, Tracking-, Werbe-, Standort- oder
Crash-Reporting-SDKs aktiviert. Es werden keine nutzergenerierten Inhalte und
keine Gesundheitsdaten angefordert. Ein Supabase-Backend, Accounts und eine
persistente Historie sind technisch geplant, aber nicht verbunden oder aktiv.

## Empfänger und Drittanbieter

- **Open Food Facts:** Empfänger der direkt ausgelösten Produktanfrage;
  Datenbank ODbL 1.0, Inhalte DbCL 1.0, Produktbilder CC BY-SA 3.0.
- **Netzwerk-Infrastruktur:** technisch an der HTTPS-Verbindung beteiligte
  Anbieter können Verbindungsmetadaten verarbeiten.
- **Apple:** verarbeitet Daten im Rahmen von iOS und einer späteren
  App-Store- oder TestFlight-Nutzung nach eigenen Bedingungen.
- **Supabase:** im aktuellen MVP nicht verbunden und kein aktueller Empfänger.

## Rechtsgrundlage und Transparenzstatus

Für die direkte Produktanfrage werden Art. 6 Abs. 1 lit. b oder lit. f DSGVO als
mögliche Rechtsgrundlagen geprüft. Diese Einordnung ist noch nicht rechtlich
freigegeben. Der aktuelle Datenfluss ist im versionierten
`privacy-data-inventory.yaml` dokumentiert. Die App-Privacy-Angaben in App
Store Connect bleiben bis zur qualifizierten Klassifikation offen.

## Speicherdauer

- Kamerabilder: keine Speicherung durch ScanFair.
- Produktobjekte: höchstens zehn Einträge im Laufzeitspeicher bis zum Ende des
  App-Prozesses.
- ScanFair-Serverdaten: keine, da kein Remote-Backend aktiv ist.
- Provider-Protokolle: Speicherdauer noch zu prüfen und vor externer Beta zu
  dokumentieren.

## Ihre Rechte

Soweit ScanFair personenbezogene Daten verarbeitet, können insbesondere Rechte
auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und
Widerspruch bestehen. Anfragen können an `business.demir@gmail.com` gerichtet
werden. Für Daten, die ein externer Anbieter in eigener Verantwortung hält,
muss zusätzlich dessen Verfahren geprüft und transparent benannt werden.

## Aktivierungsgrenze für spätere Funktionen

Backend, Accounts, persistenter Scan-Verlauf, Analytics, Crash-Reporting,
Tracking oder Standort dürfen erst aktiviert werden, wenn Dateninventar,
Zweck, Rechtsgrundlage, Empfänger, Region, Aufbewahrung, Löschung,
Betroffenenrechte, Auftragsverarbeitung, Sicherheitsmaßnahmen und die
DPIA-Erforderlichkeitsentscheidung geprüft und nachweisbar umgesetzt sind.

## Änderungen

Jede Änderung am tatsächlichen Datenfluss löst eine Aktualisierung dieser
Erklärung, des Dateninventars, der Apple App Privacy Details und der
Privacy-Quality-Gates aus.
