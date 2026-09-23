# Control-Assurance-Review der Quality Gates

- Datum: 2026-09-04
- Prüfstand: Arbeitsstand auf `docs/project-status-2026-08-31` (nicht committed)
- Umfang: lokaler Quality-Gate-Runner, Gate-Schema v2, Regulierungs-Horizon,
  Quellenbeobachtung, Feature-Deklarationen und GitHub-Workflow
- Ergebnis: Die drei festgestellten Design-Lücken sind behoben und mit
  Negativtests geprüft. Das ist kein Rechtsgutachten, keine
  Release-Freigabe und keine SLSA-Zertifizierung.

## Prüfmaßstab

Der Review verfolgt jede Kontrolle von ihrem Zweck über die Gate-Definition
und die technische Durchsetzung bis zu einem absichtlich fehlerhaften Fall.
Er trennt dabei Design-Angemessenheit (ist die Kontrolle passend aufgebaut)
von technischer Wirksamkeit im lokalen Lauf (erzwingt sie die behauptete
Reaktion). Als Referenz dienen die im Quellenregister verknüpften
Engineering-Praktiken: testbare Policy-Regeln (OPA), überprüfbare
SDLC-Praktiken (NIST SSDF) und nachvollziehbare Build-Integrität (SLSA).

| Finding | Risiko vor dem Review | Korrektur | Verifizierte Wirkung | Status |
| --- | --- | --- | --- | --- |
| CA-001 Frist-Erzwingung | `next_review_due`, `next_full_review_due` und die Frist des qualifizierten Vergleichsreviews waren dokumentiert, aber nicht profilabhängig durchgesetzt. | `validate_compliance_horizon.rb` stuft überfällige Fristen im Development als Warnung und in `release_candidate`/`submission` als Fehler ein. | Der Horizon-Selbsttest erzeugt eine überfällige Kontrollfrist, eine überfällige Vollprüfung und ein überfälliges Rechtsreview vor Wirksamkeitsdatum. Die strengen Profile scheitern, Development warnt. | behoben |
| CA-002 Quellen-Deltas | Ein HTTP-HEAD-Snapshot ohne Ausgangspunkt konnte keine wiederholbare Quellenänderung feststellen; ein Prüfauftrag war nicht versionsgebunden an eine strenge Freigabe gekoppelt. | Eine versionierte technische Baseline speichert Signaturen aus URL, deklariertem Stand, HTTP-Markern und einem begrenzten Inhaltsmarker. Ein strenges Profil erzeugt zusätzlich eine frische Beobachtung und verlangt für jedes Signal einen späteren manuellen Review-Datensatz mit derselben Signatur. | Der Quellen-Selbsttest prüft unveränderte, geänderte, fehlende und nicht auswertbare Signaturen. Ein Horizon-Selbsttest weist nach, dass ein unreviewtes Signal `release_candidate` blockiert und erst ein späterer, passender Review-Datensatz akzeptiert wird. | behoben, mit bewusster manueller Restgrenze |
| CA-003 Feature-Deklarationen | Ein auf `false` gesetztes Feature war bislang überwiegend eine Selbstauskunft. | Der Deklarationsvertrag deckt alle 16 `feature_*`-Flags exakt ab: statische Abwesenheit bzw. Präsenz, oder nachvollziehbare manuelle Attestation bei nicht aus Code ableitbaren Geschäftsrollen. | Der Selbsttest fügt testweise einen OpenAI-Endpunkt ein; die deklarierte Nichtnutzung von KI scheitert. Fehlender Aktivitätsmarker und fehlende manuelle Evidenz scheitern ebenfalls. | behoben |

## Beurteilung der Kontrolle

Die Fristen- und Deklarationskontrollen sind deterministisch und in den lokalen
Runner eingebunden. Ihre entscheidenden Negativfälle sind regressionsgetestet.
Die Quellenbeobachtung ist absichtlich sicherheitsorientiert: Ein nicht lesbarer
Quelleninhalt wird nie als „unverändert“ oder als Freigabe interpretiert,
sondern als Prüfauftrag.

Der aktuelle Online-Abgleich erzeugte zwei technische Deltas (`APPLE-ARG`,
`EC-AIA-ART50-FAQ`) und vier nicht auswertbare Inhaltsmarker. Der leere
Review-Log führt daher im strengen Profil bewusst zu sechs konkreten
Blockern. Diese Blocker werden nicht durch eine technische Änderung oder eine
automatische Baseline-Aktualisierung geschlossen.

Das folgt dem üblichen Muster für Policy-as-Code: eindeutige Regeln werden
automatisiert getestet; fachliche und rechtliche Bewertung erhält eine
nachvollziehbare menschliche Entscheidung. Die Implementierung ist damit mit
den genannten Engineering-Praktiken ausgerichtet, ohne eine Konformitäts- oder
Zertifizierungsaussage für OPA, NIST SSDF oder SLSA zu beanspruchen.

## Akzeptierte Grenzen und nächste Evidenz

- Die statische Suche erkennt keine absichtlich verschleierten, zur Laufzeit
  geladenen oder serverseitig aktivierten Funktionen. Jede Funktionsänderung
  bleibt deshalb ein Release- und Code-Review-Trigger.
- UGC, Altersklassifikation sowie EUDR-Operator-/Trader-Rolle sind
  Produkt- und Geschäftsentscheidungen. Sie benötigen weiterhin die im
  Deklarationsvertrag hinterlegte manuelle Evidenz.
- Apple- und einzelne EUR-Lex-Quellen liefern nicht in jedem Abruf verwertbaren
  Inhalt. Das Ergebnis bleibt `content_marker_inconclusive` und fordert einen
  menschlichen Delta-Abgleich; es wird nicht stillschweigend grün.
- Ein künftiger SLSA-Build-Level-Claim erfordert separate, prüfbare
  Herkunftsattestierungen. Die vorhandene Dependency- und CI-Absicherung
  allein genügt dafür nicht.

## Nachweise

- `docs/project/compliance/regulatory-horizon.yaml`
- `docs/project/compliance/source-observation-baseline.yaml`
- `docs/project/compliance/source-observation-review-log.yaml`
- `docs/project/compliance/capability-declaration-contract.yaml`
- `scripts/quality/validate_compliance_horizon.rb`
- `scripts/quality/observe_compliance_sources.rb`
- `scripts/quality/validate_capability_declarations.rb`
- `scripts/quality/test_compliance_horizon_gate.rb`
- `scripts/quality/test_compliance_source_observation.rb`
- `scripts/quality/test_capability_declarations.rb`
- `docs/project/compliance/source-register.yaml` (OPA-POLICY-TESTING,
  NIST-SSDF-800-218, SLSA-BUILD-LEVELS)
