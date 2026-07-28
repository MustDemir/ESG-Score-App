# Datenschutzerklärung — ScanFair

*Entwurf · Stand: 2026-07-27 · Sprache: Deutsch*

> ⚠️ Dieser Text ist ein **Stub für TestFlight / App Store Submission** und juristisch noch nicht final.
> Vor Veröffentlichung von einem Datenschutzbeauftragten / Rechtsbeistand prüfen lassen.

## Verantwortlicher

Mustafa Demir
[Adresse]
business.demir@gmail.com

## Welche Daten verarbeiten wir?

### 1. Produktanfragen (Open Food Facts)
Beim Scannen eines Barcodes wird die EAN an die Open Food Facts API (`world.openfoodfacts.org`)
übertragen, um Produktinformationen abzurufen. Es werden keine personenbezogenen Daten mitgesendet.

### 2. Konto (optional)
Im aktuellen lokalen MVP ist kein Konto aktiviert. Eine spaetere Konto-Funktion
mit Supabase und Apple Sign-In erfordert vor Aktivierung eine aktualisierte
Datenschutzerklaerung, AVV-/Regionsnachweis und In-App-Kontoloeschung.

### 3. Scan-Verlauf
Der aktuelle MVP haelt zuletzt gescannte Produkte nur waehrend der App-Laufzeit
im Speicher. Es findet noch keine Cloud-Speicherung des Scan-Verlaufs statt.

### 4. Telemetrie
Aktuell keine Tracking-SDKs. Crashlogs nur bei expliziter Opt-In-Zustimmung.

## Drittanbieter
- **Open Food Facts** — Datenbank: ODbL; Produktbilder: CC BY-SA; Frankreich
- **Supabase** — technisch vorbereitet, im aktuellen MVP nicht verbunden
- **Apple** — Bei iOS-Nutzung (App Store, TestFlight, Sign-In)

## Ihre Rechte (DSGVO Art. 15–22)
Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit, Widerspruch.
Anfragen an: business.demir@gmail.com

## Speicherdauer
Konto- und Scan-Daten bis zur Löschung des Kontos.

## Änderungen
Diese Erklärung kann angepasst werden; aktuelle Fassung jederzeit unter
https://mustdemir.github.io/ESG-Score-App/privacy.html abrufbar.
