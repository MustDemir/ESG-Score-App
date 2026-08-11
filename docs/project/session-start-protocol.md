# Session-Start-Protokoll

> Dieses Protokoll stellt sicher, dass jede neue Claude-Code-Session (egal in
> welchem Chat) den vollen Projektkontext hat und keine Phase / kein Check
> übersprungen wird.

---

## Für Claude Code (auto-getriggert via CLAUDE.md)

Bei JEDER neuen Session in diesem Repo, BEVOR du auf User-Input reagierst:

1. Lies `docs/project/progress.yaml` → ermittle `current_phase`,
   `session_handoff.next_session_plan`, letzten `weekly_log` und `next_week`
2. Lies `docs/project/gap-register.yaml` und
   `docs/project/improvement-register.yaml` → ermittle P0-/P1-Gaps,
   Aktivierungstrigger und Abhängigkeiten
3. Lies `docs/project/roadmap.yaml` → check `out_of_scope` der aktuellen Phase
4. Lies `docs/project/backlog.yaml` → priorisierte offene TODOs
5. Identifiziere Blocker (Items mit `status: in_progress` oder `priority: P0`)
6. **Bevor du Code-Vorschläge machst:** lies `docs/project/quality-strategy.md`
   und `docs/project/definition-of-done.yaml`
7. Begrüße den User mit einem 3-Zeilen-Status-Update:
   > „Wir sind in Phase X (Sprint Y). Zuletzt erledigt: A. Offen / P0: B, C.
   > Soll ich mit B weitermachen oder hast du was anderes im Kopf?"

---

## Für Mustafa (User-Ritual am Session-Start)

Wenn du in einer neuen Session loslegst — auch wenn Claude dir den Status
liefert — empfehle ich folgendes Mini-Ritual (30 Sekunden):

1. **Schau auf `progress.yaml`** — welche Woche ist's, was war zuletzt los?
2. **Frage Claude nach Status** — er sollte dir das automatisch geben, wenn
   nicht: tippe „Status?"
3. **Wenn du was Neues anfangen willst:** sage explizit „neue Idee" damit
   Claude weiß dass er sie als IDEA-NNN ins Backlog tut, statt sofort zu
   coden

---

## Definition of Ready — bevor ein Task gestartet werden darf

Aus `definition-of-done.yaml` referenziert. Ein Task ist „ready" wenn:

- [ ] Akzeptanzkriterien klar (was heißt „fertig"?)
- [ ] Falls Architektur-relevant: ADR existiert oder wird vorab geschrieben
- [ ] Abhängigkeiten (`depends_on` im Backlog) erfüllt
- [ ] Keine Out-of-Scope-Drift (Item gehört zur aktuellen Phase)

---

## Wenn du den Chat wechselst / einen neuen Tab öffnest

**Konkretes Vorgehen:**

1. Öffne Claude Code im selben Repo-Verzeichnis
2. Die `CLAUDE.md` wird automatisch geladen
3. Gib als erstes Prompt: **„Status?"** oder **„Wo waren wir?"**
4. Claude wird `progress.yaml` lesen und dir den Stand geben
5. **Vertraue nicht blind** — wenn dir was komisch vorkommt, lass dir die
   relevanten YAMLs zeigen

**Was du NICHT brauchst:**

- Kopieren von Chat-Inhalten
- Manuelles Erklären „wir hatten beschlossen…"
- Erinnerung an ADR-Nummern aus dem Kopf

Alles steht im Repo. **Solange du in diesem Verzeichnis arbeitest, hat
Claude vollen Kontext.**

---

## Konsistenz-Garantien

Wir haben mehrschichtige Absicherung — wenn EINE Schicht durchrutscht,
fängt die nächste:

| Schicht | Mechanismus | Was es schützt |
|---|---|---|
| 1 | `CLAUDE.md` Session-Start-Protokoll | Claude liest immer Status |
| 2 | `progress.yaml` als Source of Truth | Status ist immer aktuell und auffindbar |
| 3 | `definition-of-done.yaml` Checkliste | Keine Tasks „fertig" ohne Checks |
| 4 | Pre-Commit-Hooks (gitleaks, format) | Format/Secrets auch ohne Claude |
| 5 | GitHub Actions CI/CD | Keine Merges ohne grüne Pipeline |
| 6 | ADR-Append-Only-Regel | Entscheidungen können nicht heimlich „verloren" gehen |
| 7 | `failure-modes.yaml` | Bekannte Fehler-Muster mit Defense |
| 8 | `gap-register.yaml` + `G-PROJECT-CONTROL` | Blinde Flecken, Trigger und überfällige Reifeprüfungen |

---

## Wartung dieses Protokolls

- Updates wenn neue YAML-Dateien dazukommen die gelesen werden sollten
- Updates wenn das Workflow-Verhalten sich ändert (z.B. neue Phasen)
- Mindestens 1× pro Phase prüfen ob die Reihenfolge noch sinnvoll ist
