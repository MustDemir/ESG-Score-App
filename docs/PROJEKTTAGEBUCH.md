# 📖 Projekttagebuch – ESG-Score App

> Wöchentliche Dokumentation von Fortschritten, Entscheidungen und Learnings.
> Dieses Tagebuch dient der Nachvollziehbarkeit und als Reflexions-Tool.

---

## Woche 0 – Planung & Requirements (KW 8/2026)

**Datum:** 22. Februar 2026

### Was wurde erreicht
- ✅ ESG-Scoring-Modell v1.0 fertiggestellt (3 Dimensionen, 13 Sub-Scores, Gewichtungen definiert)
- ✅ MVP Requirements Document erstellt (11 Kapitel, 5 Screens, API-Mapping, Datenmodell)
- ✅ GitHub Repository aufgesetzt mit Dokumentationsstruktur
- ✅ Technologie-Entscheidungen getroffen (Flutter, Supabase, Open Food Facts)

### Entscheidungen
| Entscheidung | Begründung |
|-------------|------------|
| Flutter statt Swift (nativ) | Cross-platform Potenzial, Claude Code kann Flutter generieren |
| Supabase statt Firebase | EU-gehostet → DSGVO-konform, PostgreSQL als Basis |
| MVP nur E-Score vollständig | Beste Datenverfügbarkeit, S-Score und G-Score in Phase 2 |
| Regelbasiertes Scoring statt KI | Weniger Komplexität, transparenter, validierbar |

### Learnings
- Die Planung vor dem Coden ist entscheidend – ohne klare Requirements wäre der Scope explodiert
- Open Food Facts API muss vorab getestet werden (Risiko: fehlende Daten bei DE-Produkten)
- GitHub als Portfolio-Tool ist wertvoll für die Cloud-Architektur Weiterbildung

### Nächste Woche (W1)
- [ ] Flutter SDK + Xcode installieren
- [ ] Hello World Flutter App im Simulator starten
- [ ] Projektstruktur in Flutter anlegen
- [ ] Open Food Facts API mit 5 Test-Barcodes manuell testen

---

<!-- Template für neue Wochen:

## Woche X – [Titel] (KW XX/2026)

**Datum:** TT. Monat 2026

### Was wurde erreicht
- 

### Entscheidungen
| Entscheidung | Begründung |
|-------------|------------|

### Learnings
- 

### Probleme / Blocker
- 

### Nächste Woche
- [ ] 

-->
