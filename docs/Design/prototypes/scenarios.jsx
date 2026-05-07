// ScanFair Discovery — User Scenarios (Klaus & Thomas) + Kernfunktionen + 5-Step UX

const sfScenFont = { fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif' };
const SCN_INK = '#1A1A18';
const SCN_INK_60 = '#737370';
const SCN_INK_40 = '#A8A8A0';
const SCN_LINE = '#E7E7E2';
const SCN_PAPER = '#FAFAF9';

// ───────────────────────────────────────────────────
// User Scenarios (Klaus + Thomas)
// ───────────────────────────────────────────────────
const SCENARIOS = [
  {
    id: 'klaus',
    persona: 'Klaus (68)',
    title: 'Im Supermarkt — Spontaner Einkauf',
    accent: '#1E40AF',
    situation: 'Klaus steht im Gang des Supermarkts. Er hält sein Smartphone in der Hand. Er möchte zwischen verschiedenen Joghurt-Produkten eine informierte Entscheidung treffen.',
    userStory: 'Als umweltbewusster Käufer möchte ich beim Einkauf sofort detaillierte ESG-Daten zu jedem Produkt sehen, damit ich fundierte und nachhaltige Kaufentscheidungen treffen kann.',
    illustration: '🧑🏻‍🦳📱🥛',
    steps: [
      { n: 1, title: 'Barcode scannen', items: [
        'Klaus richtet die Kamera seines Smartphones auf das Produkt',
        'Die App erkennt den Barcode automatisch',
        'Die Produktdaten werden sofort aus der Datenbank abgerufen',
      ], screen: 'S2 Scanner' },
      { n: 2, title: 'ESG-Dashboard anzeigen', items: [
        'Die App zeigt den CO₂-Fußabdruck von 2,5 kg CO₂ prominent an',
        'Ein übersichtliches Balkendiagramm stellt verschiedene Nachhaltigkeitskategorien dar',
        'Die Bewertung wird farbcodiert von A bis F dargestellt',
        'Der Gesamtnachhaltigkeits-Score ist auf einen Blick sichtbar',
      ], screen: 'S3 Score' },
      { n: 3, title: 'Vergleichsfunktion nutzen', items: [
        'Die App schlägt automatisch alternative Produkte mit besseren Werten vor',
        'Produkte mit besseren ESG-Scores werden hervorgehoben',
        'Ein integrierter Preisvergleich ermöglicht die Abwägung zwischen Kosten und Nachhaltigkeit',
      ], screen: 'S3 Alternativen' },
      { n: 4, title: 'Entscheidungshilfe erhalten', items: [
        'Detaillierte Informationen zur Herkunft werden angezeigt',
        'Relevante Zertifizierungen und Siegel sind dokumentiert',
        '(Phase 2) AR-Overlay zeigt Sustainability-Badges direkt über dem Produkt',
      ], screen: 'S4 Details' },
    ],
  },
  {
    id: 'thomas',
    persona: 'Thomas (28)',
    title: 'Zuhause — Einkaufsliste planen',
    accent: '#0F766E',
    situation: 'Thomas plant seine Mahlzeiten für die kommende Woche. Er öffnet die App und navigiert zur „Meal Prep"-Funktion.',
    userStory: 'Als gesundheitsbewusster Meal-Prepper möchte ich meine bewährten Einkaufslisten wiederverwenden und automatisch an aktuelle Angebote und Verfügbarkeiten anpassen lassen, damit ich Zeit spare und gleichzeitig nachhaltig und proteinreich einkaufe.',
    illustration: '🧑🏻‍💻📱🥗',
    steps: [
      { n: 1, title: 'Intelligente Einkaufslisten-Funktion', items: [
        'Thomas wählt „Letzte Einkaufsliste laden" aus',
        'Die App lädt seine bewährte Meal-Prep-Liste vom letzten Monat hoch',
        'Automatisch werden die Produkte mit den aktuellen Angeboten seines bevorzugten Supermarkts abgeglichen',
      ], screen: 'S6 Planung' },
      { n: 2, title: 'Personalisierte Filter', items: [
        'Thomas aktiviert seine gespeicherten Filter',
        '„Protein >20g" – für seine Fitness-Ziele',
        '„Regional" – für Nachhaltigkeit',
        '„Schnelle Rezepte" – für stressige Arbeitstage',
        '„Vegan-Option" – für Abwechslung',
      ], screen: 'S6 Filter' },
      { n: 3, title: 'Smart-Anpassung', items: [
        '✓ „Hähnchenbrust ist diese Woche 15% reduziert"',
        '⚠ „Ihr übliches Bio-Quinoa ist nicht verfügbar – Alternative: Regionales Dinkel (+0,5 ESG-Score)"',
        '💡 „Neue nachhaltige Option: Lokale Linsen (ESG-Score: 9.45)"',
      ], screen: 'S6 Smart' },
      { n: 4, title: 'Visuelle Übersicht', items: [
        'Ein Kreisdiagramm zeigt die ESG-Verteilung seiner geplanten Einkäufe',
        'Eine Liste mit Icons zeigt die Produkte mit ihren jeweiligen Nachhaltigkeitsbewertungen',
        'Farbcodierung: Grün für ausgezeichnete Werte, Orange für mittlere Bewertungen',
      ], screen: 'S6 + S7 Impact' },
      { n: 5, title: 'Wochenplan-Integration', items: [
        'Die App schlägt basierend auf seinen Filterkriterien „Gesunde Snacks" und proteinreiche Rezepte vor',
        'Thomas kann direkt Rezepte für die Woche auswählen und die benötigten Zutaten werden automatisch zur Liste hinzugefügt',
      ], screen: 'S6 Rezepte' },
    ],
  },
];

function ScenarioCard({ scn }) {
  return (
    <div style={{
      ...sfScenFont, background: '#fff', border: `1px solid ${SCN_LINE}`, borderRadius: 16,
      overflow: 'hidden', maxWidth: 920,
    }}>
      {/* Header */}
      <div style={{
        background: scn.accent + '0A', borderBottom: `2px solid ${scn.accent}`,
        padding: 24, display: 'flex', gap: 24, alignItems: 'center',
      }}>
        <div style={{
          width: 96, height: 96, borderRadius: 48, background: scn.accent + '14',
          border: `3px solid ${scn.accent}`, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 36, flexShrink: 0,
        }}>{scn.illustration}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, color: scn.accent, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 4 }}>
            {scn.persona} · User Scenario
          </div>
          <div style={{ fontSize: 22, fontWeight: 700, color: SCN_INK, letterSpacing: -0.3, marginBottom: 8 }}>
            {scn.title}
          </div>
          <div style={{
            padding: 12, background: '#fff', border: `1px solid ${SCN_LINE}`, borderRadius: 8,
            fontSize: 12, color: SCN_INK, lineHeight: 1.55,
          }}>
            <span style={{ color: SCN_INK_40, fontWeight: 700, fontSize: 10, letterSpacing: 0.5, textTransform: 'uppercase', marginRight: 6 }}>Situation:</span>
            {scn.situation}
          </div>
        </div>
      </div>

      {/* User Story */}
      <div style={{
        margin: 24, padding: 16, background: '#FFFBEB', borderLeft: `3px solid #F59E0B`, borderRadius: 8,
      }}>
        <div style={{ fontSize: 10, color: '#B45309', fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 6 }}>
          User Story
        </div>
        <div style={{ fontSize: 13, color: SCN_INK, fontStyle: 'italic', lineHeight: 1.6 }}>
          „{scn.userStory}"
        </div>
      </div>

      {/* Steps */}
      <div style={{ padding: '0 24px 24px' }}>
        <div style={{ fontSize: 11, color: SCN_INK_40, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 12 }}>
          App-Nutzung · {scn.steps.length} Schritte
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {scn.steps.map(step => (
            <div key={step.n} style={{
              display: 'flex', gap: 14, padding: 14,
              background: SCN_PAPER, border: `1px solid ${SCN_LINE}`, borderRadius: 10,
            }}>
              <div style={{
                width: 30, height: 30, borderRadius: 15, background: scn.accent, color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 13, fontWeight: 700, flexShrink: 0,
              }}>{step.n}</div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: SCN_INK }}>{step.title}</div>
                  <div style={{
                    padding: '2px 8px', border: `1px dashed ${scn.accent}`, borderRadius: 4,
                    fontSize: 10, color: scn.accent, fontWeight: 600,
                    fontFamily: '"SF Mono", monospace',
                  }}>{step.screen}</div>
                </div>
                <ul style={{ margin: 0, paddingLeft: 16, fontSize: 12, color: SCN_INK_60, lineHeight: 1.6 }}>
                  {step.items.map((it, i) => <li key={i}>{it}</li>)}
                </ul>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ScenariosSection() {
  return (
    <div style={{ ...sfScenFont, padding: '40px 60px', background: SCN_PAPER }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: SCN_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Konkrete Anwendungsfälle
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: SCN_INK, letterSpacing: -0.3 }}>
          User Scenarios
        </div>
        <div style={{ fontSize: 13, color: SCN_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Zwei narrative Szenarien aus der Hausarbeit. Sie zeigen, wie ScanFair konkret im Alltag wirkt — und welche
          Wireframe-Screens wir dafür bauen müssen.
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
        {SCENARIOS.map(scn => <ScenarioCard key={scn.id} scn={scn} />)}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Kernfunktionen-Diagramm (E/S/G + 3 Funktionen)
// ───────────────────────────────────────────────────
function KernfunktionenSection() {
  return (
    <div style={{ ...sfScenFont, padding: '40px 60px', background: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: SCN_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Was macht ScanFair?
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: SCN_INK, letterSpacing: -0.3 }}>
          Eine App, drei Dimensionen, unendlich Transparenz
        </div>
        <div style={{ fontSize: 13, color: SCN_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Drei Kernfunktionen, die auf den drei ESG-Dimensionen basieren — und ein 5-Schritte-User-Flow,
          der die App auf einen Blick erklärt.
        </div>
      </div>

      <div style={{ display: 'flex', gap: 32 }}>
        {/* Left: 3 Funktionen */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: SCN_INK, marginBottom: 4 }}>
            Funktion 1: Produkt-Scan & ESG-Score in Echtzeit
          </div>
          {/* ESG Triangle */}
          <div style={{
            position: 'relative', height: 240, padding: 20,
            background: SCN_PAPER, border: `1px solid ${SCN_LINE}`, borderRadius: 12,
          }}>
            {/* E (top) */}
            <div style={{
              position: 'absolute', top: 16, left: '50%', transform: 'translateX(-50%)',
              width: 160, padding: 12, background: '#ECFDF5', border: '2px solid #16A34A', borderRadius: 8,
              textAlign: 'center',
            }}>
              <div style={{ fontSize: 24, fontWeight: 800, color: '#16A34A' }}>E</div>
              <div style={{ fontSize: 11, color: SCN_INK_60, lineHeight: 1.4, marginTop: 2 }}>
                Environmental<br />CO₂, Wasser, Verpackung
              </div>
            </div>
            {/* S (bottom-left) */}
            <div style={{
              position: 'absolute', bottom: 16, left: 16,
              width: 150, padding: 12, background: '#FEF2F2', border: '2px solid #DC2626', borderRadius: 8,
            }}>
              <div style={{ fontSize: 24, fontWeight: 800, color: '#DC2626' }}>S</div>
              <div style={{ fontSize: 11, color: SCN_INK_60, lineHeight: 1.4, marginTop: 2 }}>
                Social<br />Arbeit, Lieferkette, Fair Trade
              </div>
            </div>
            {/* G (bottom-right) */}
            <div style={{
              position: 'absolute', bottom: 16, right: 16,
              width: 150, padding: 12, background: '#EFF6FF', border: '2px solid #1E40AF', borderRadius: 8,
            }}>
              <div style={{ fontSize: 24, fontWeight: 800, color: '#1E40AF' }}>G</div>
              <div style={{ fontSize: 11, color: SCN_INK_60, lineHeight: 1.4, marginTop: 2 }}>
                Governance<br />Ethik, Compliance, Zertifikate
              </div>
            </div>
          </div>

          <div style={{ padding: 14, background: '#F0FDFA', border: '1px solid #5EEAD4', borderRadius: 10 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#0F766E', marginBottom: 4 }}>Funktion 2: Personalisierte Alternativen-Empfehlung</div>
            <div style={{ fontSize: 11, color: SCN_INK_60, lineHeight: 1.5, fontStyle: 'italic' }}>
              „Dieses Produkt hat Score 6/10. Probieren Sie Alternative X mit Score 9/10."
            </div>
          </div>

          <div style={{ padding: 14, background: '#F5F3FF', border: '1px solid #C4B5FD', borderRadius: 10 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#7C3AED', marginBottom: 4 }}>Funktion 3: Persönlicher Impact-Tracker</div>
            <div style={{ fontSize: 11, color: SCN_INK_60, lineHeight: 1.5 }}>
              Visualisierung des eigenen ökologischen Fußabdrucks über Zeit
            </div>
          </div>
        </div>

        {/* Right: 5-Step User Flow */}
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: SCN_INK, marginBottom: 12 }}>
            User Experience — 5 Schritte
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              { n: 1, title: 'App öffnen, Barcode/QR scannen', desc: 'Nutzer scannt Produkt mit der Kamera → App erkennt Produkt automatisch', color: '#16A34A' },
              { n: 2, title: 'ESG Score erscheint (Ampel)', desc: 'Sofortige Bewertung auf einen Blick mit Farbcodierung Grün/Gelb/Rot', color: '#16A34A' },
              { n: 3, title: 'Details aufklappen (E/S/G)', desc: 'Einzelbewertungen für Environmental, Social, Governance', color: '#1E40AF' },
              { n: 4, title: 'Alternative vorgeschlagen', desc: 'KI empfiehlt nachhaltigere Produkte personalisiert nach Nutzerpräferenzen', color: '#F97316' },
              { n: 5, title: 'Kauf tracken → Impact-Dashboard', desc: 'Persönlicher ökologischer Fußabdruck wird visualisiert — Fortschritt sichtbar', color: '#7C3AED' },
            ].map(s => (
              <div key={s.n} style={{
                display: 'flex', gap: 12, padding: 12, background: SCN_PAPER,
                border: `1px solid ${SCN_LINE}`, borderRadius: 10,
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 16, background: s.color, color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 14, fontWeight: 700, flexShrink: 0,
                }}>{s.n}</div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: s.color, marginBottom: 2 }}>{s.title}</div>
                  <div style={{ fontSize: 11, color: SCN_INK_60, lineHeight: 1.5 }}>{s.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ marginTop: 16, fontSize: 11, color: SCN_INK_40, fontStyle: 'italic' }}>
        Quelle: Eigene Darstellung basierend auf Wolniak et al. (2024) und Hausarbeit Demir (2025).
      </div>
    </div>
  );
}

window.ScenariosSection = ScenariosSection;
window.KernfunktionenSection = KernfunktionenSection;
