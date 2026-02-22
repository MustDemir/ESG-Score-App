# ESG-Score App – Projektübersicht für Claude Code

## Was ist dieses Projekt?
Eine mobile App (iOS + Android) die Supermarkt-Produkte per Barcode scannt und einen ESG-Score (Environmental, Social, Governance) anzeigt. Die App hilft Konsumenten, nachhaltigere Kaufentscheidungen zu treffen.

## Tech-Stack
- **Frontend:** Flutter (Dart)
- **Backend/Datenbank:** Supabase (PostgreSQL, Auth, Storage) – EU Region Frankfurt
- **Produktdaten:** Open Food Facts API
- **Barcode-Scanner:** Flutter Plugin `mobile_scanner`
- **State Management:** Provider oder Riverpod (entscheiden wir noch)
- **Architektur:** Clean Architecture mit klarer Trennung von UI, Business Logic, Data Layer

## Projektstruktur
```
/Users/mustafademir/ESG-Score-App/
├── esg_app/              # Flutter-Projekt
│   ├── lib/
│   │   ├── main.dart     # App-Einstiegspunkt
│   │   ├── screens/      # Bildschirme (Scanner, Dashboard, Profil)
│   │   ├── widgets/      # Wiederverwendbare UI-Bausteine
│   │   ├── models/       # Datenmodelle (Produkt, ESG-Score, User)
│   │   ├── services/     # API-Aufrufe (Supabase, Open Food Facts)
│   │   └── utils/        # Hilfsfunktionen
│   ├── assets/           # Bilder, Fonts
│   ├── test/             # Tests
│   └── pubspec.yaml      # Abhängigkeiten
├── CLAUDE.md             # Diese Datei
└── README.md
```

## MVP-Scope (Phase 1)
1. Barcode scannen → Produkt aus Datenbank laden
2. ESG-Score anzeigen (Ampelsystem: grün/gelb/rot)
3. Detailansicht E/S/G aufklappen
4. Nachhaltigere Alternative vorschlagen
5. Einfaches Nutzerprofil (Login, Präferenzen)

## Was NICHT in Phase 1 gehört
- AR-Overlay
- Kassenbonscan
- Impact-Tracker / Gamification
- Community-Features
- On-Device ML
- Meal-Prep Funktion

## Code-Regeln
- Schreibe sauberen, gut kommentierten Dart-Code
- Kommentare auf Deutsch oder Englisch (konsistent bleiben)
- Nutze aussagekräftige Variablen- und Funktionsnamen
- Erstelle kleine, fokussierte Widgets statt riesiger Dateien
- Fehlerbehandlung (try/catch) bei allen API-Aufrufen
- Keine hardcodierten API-Keys im Code – nutze Environment Variables

## Supabase-Konfiguration
- Region: EU Central (Frankfurt)
- Auth: Email + Apple Sign-In
- Tabellen werden im Laufe des Projekts definiert

## Wichtige Hinweise
- Der Entwickler (Mustafa) ist Programmier-Anfänger mit Python-Grundkenntnissen
- Erkläre Code-Änderungen kurz und verständlich
- Bevorzuge einfache, lesbare Lösungen gegenüber cleveren Abkürzungen
- Bei Fehlern: erkläre was schief gelaufen ist und warum die Lösung funktioniert
