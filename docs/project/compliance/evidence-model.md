# Evidence-Modell — welche Artefakte die Gates brauchen

> Erklärt WIE die Compliance-Gates in CI an ihre Prüf-Daten kommen und WAS
> du als Entwickler nach jedem Dev-Step bereitstellen musst.
> Bezug: [ADR 0012](../decisions/0012-apple-review-compliance.yaml),
> [ADR 0013](../decisions/0013-multi-regulation-strategy.yaml),
> [ADR 0009](../decisions/0009-methodology-adoption.yaml) (GCG-3 Evidence-Log).
> Letztes Update: 2026-05-19

---

## Grundprinzip

Conftest (das Gate-Tool) prüft **nicht direkt** deine `Info.plist` oder
`pubspec.yaml`. Es prüft eine **Input-Datei** (`compliance_input.json`), die
deinen App-Zustand abbildet. Diese Input-Datei entsteht automatisch aus zwei
Quellen.

```
Echte App-Files                      Hand-gepflegte Deklaration
(Info.plist, pubspec.yaml,           (compliance-manifest.json)
 AndroidManifest.xml,                       │
 PrivacyInfo.xcprivacy)                     │
        │                                   │
        │ extract_app_metadata.sh           │
        ▼                                   ▼
  app_extracted.json  ───── jq merge ─────  compliance-manifest.json
                            │
                            ▼
                  evidence-store/compliance_input.json   ◄── DAS prüft Conftest
                            │
                            │ conftest test --policy policies/apple
                            ▼
                  Pass/Fail + evidence-store/evidence-log.jsonl (SHA-256)
```

---

## Die 3 Artefakt-Kategorien

| Kategorie | Was | Quelle | Dein Aufwand |
|---|---|---|---|
| **A — Auto-extrahiert** | App-Name, Camera-String, Cleartext-Config, Privacy-Manifest | echte App-Files | **Null** (Script liest sie) |
| **B — Deklariert** | Privacy-URL, Support-URL, OFF-Disclose, Aufbewahrungsfristen | `compliance-manifest.json` | einmalig + bei Änderung |
| **C — Manueller Nachweis** | „Review von X am Datum", Demo-Account bereit, Screenshots geprüft | du trägst ein (HYBRID-Gates) | pro Release |

### Kategorie A — Auto-extrahiert (Null Aufwand)

Das Script `scripts/compliance/extract_app_metadata.sh` liest:

| Feld | Aus Datei | Methode |
|---|---|---|
| `app_name_ios` | `ios/Runner/Info.plist` → CFBundleDisplayName | plutil |
| `app_name_android` | `android/.../AndroidManifest.xml` → android:label | grep/sed |
| `app_name_pubspec_package` | `pubspec.yaml` → name | grep/sed |
| `camera_purpose_string` | `Info.plist` → NSCameraUsageDescription | plutil |
| `ios_allows_arbitrary_loads` | `Info.plist` → NSAppTransportSecurity | plutil |
| `privacy_manifest_present` | Existenz `PrivacyInfo.xcprivacy` | file-check |

Du musst **nichts** tun außer die App korrekt zu konfigurieren (was du eh tust).

### Kategorie B — Deklariert (einmalig pflegen)

In `compliance-manifest.json` deklarierst du was nicht aus Code lesbar ist:

| Feld | Beispiel |
|---|---|
| `app_name_pubspec` (kanonischer Markenname) | "ScanFair" |
| `subtitle` | "ESG-Score beim Einkauf" |
| `privacy_policy_url` | "https://scanfair.de/privacy" |
| `support_url` | "https://scanfair.de/support" |
| `off_data_source_disclosed` | true |
| `data_retention_days` | 365 |

Pflegst du **einmal** wenn der Wert feststeht, danach nur bei Änderung.

### Kategorie C — Manueller Nachweis (pro Release, HYBRID-Gates)

Manche Gates sind HYBRID — Conftest prüft die Struktur, ein Mensch die
Substanz. Der menschliche Teil wird als Evidence eingetragen:

```json
"manual_review": {
  "reviewed_by": "Mustafa Demir",
  "review_date": "2026-06-15",
  "scope": "Privacy Policy inhaltlich geprüft, OFF + Supabase erwähnt"
}
```

Das machst du als Teil des `post-feature`- bzw. Release-Workflows.

---

## Was du nach JEDEM Dev-Step tun musst (Kurzfassung)

| Dev-Step betrifft… | Aktion | Häufigkeit |
|---|---|---|
| Code / App-Config (Kategorie A) | **Nichts** — CI extrahiert automatisch | — |
| Neue feststehende Info (Kategorie B) | `compliance-manifest.json` ergänzen | selten |
| HYBRID-Gate-Schritt (Kategorie C) | Evidence-Eintrag im manual_review | pro Release |

**Faustregel:** Solange du nur Code schreibst, ist dein Compliance-Aufwand
**null**. Das Gate liest den Zustand selbst. Nur Deklarationen + manuelle
Reviews erfordern aktives Eintragen.

---

## Lokaler Test-Lauf (so prüfst du selbst)

```bash
# 1. App-Metadaten extrahieren
bash scripts/compliance/extract_app_metadata.sh

# 2. Mit Deklarationen mergen
bash scripts/compliance/build_compliance_input.sh

# 3. Gates laufen lassen (braucht conftest)
bash scripts/compliance/run_gates.sh
```

Output: Pass/Fail pro Gate + Eintrag in `evidence-store/evidence-log.jsonl`.

---

## Aktivierungs-Stand (was JETZT prüfbar ist)

| Gate | Input-Felder vorhanden? | Status |
|---|---|---|
| G-AS-NAME-LENGTH | ja (ios/android Name) | ✅ läuft — meldet aktuell Finding (Display-Name noch "Esg App" statt "ScanFair") |
| G-AS-CAMERA-PURPOSE | nein (Scanner-Code fehlt) | ⏳ wartet auf Scanner-Feature |
| G-AS-PRIVACY-URL | Deklaration TBD | ⏳ wartet auf Privacy-Policy-URL |
| G-AS-SUPPORT-URL | Deklaration TBD | ⏳ wartet auf Domain |

**Das ist gewollt:** Die Gates melden ehrlich was noch nicht fertig ist. Ein
Finding heißt nicht „kaputt", sondern „dieser Schritt steht noch aus".

---

## Technische Notiz — warum JSON statt YAML für das Manifest

Unsere Projekt-Konvention ist YAML. Das `compliance-manifest` ist aber
bewusst **JSON**:
- conftest liest JSON nativ
- `jq` (cross-platform, installiert) merged JSON trivial
- Python-YAML-Tooling ist auf dem aktuellen Setup defekt (Python 3.14
  pyexpat-Bug auf macOS) — JSON ist dependency-frei robust

Sobald ein zuverlässiger YAML→JSON-Konverter verfügbar ist, kann das Manifest
auf YAML umgestellt werden ohne die Gate-Logik zu ändern.

---

## Wartung

- Bei neuem Gate: prüfen welche Kategorie der Input ist (A/B/C) + hier eintragen
- Bei neuer Kategorie-B-Info: `compliance-manifest.json` ergänzen
- Extraction-Script erweitern wenn neue Kategorie-A-Felder gebraucht werden
