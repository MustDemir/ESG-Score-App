// ScanFair Discovery — Hauptkomponente
// Bindet alle Sektionen in einen DesignCanvas

const { useState: useStateD } = React;

function DiscoveryIntro() {
  return (
    <div style={{
      fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
      padding: '48px 60px', background: '#fff',
      borderBottom: '1px solid #E7E7E2',
    }}>
      <div style={{ maxWidth: 900 }}>
        <div style={{ fontSize: 11, color: '#A8A8A0', letterSpacing: 2, textTransform: 'uppercase', marginBottom: 12 }}>
          ScanFair · Phase 0 — Discovery
        </div>
        <h1 style={{
          fontSize: 48, fontWeight: 800, color: '#1A1A18', letterSpacing: -1,
          margin: 0, lineHeight: 1.05,
        }}>
          Discovery & Strategischer Kontext
        </h1>
        <div style={{
          fontSize: 17, color: '#525252', marginTop: 16, lineHeight: 1.6, maxWidth: 760,
        }}>
          Das Fundament unter den Wireframes: Personas, Customer Journey Maps (Ist + Soll), Value Proposition Canvas,
          User Scenarios, Conjoint-Priorisierung, Epics, Roadmap und Risiken.
          Alle Inhalte verdichtet aus der Hausarbeit (Demir, 2025) und dem PITCH.md.
        </div>
        <div style={{
          marginTop: 24, padding: 16,
          background: '#FFFBEB', borderLeft: '4px solid #F59E0B', borderRadius: 8,
          fontSize: 13, color: '#1A1A18', lineHeight: 1.6, maxWidth: 760,
        }}>
          <strong>So liest man dieses Dokument:</strong> Doppelklick auf eine Sektion = Fullscreen-Fokus,
          Pfeiltasten zum Navigieren zwischen Sektionen, Esc schließt. Mausrad zum Zoomen, Drag zum Pannen.
          Sektionsreihenfolge folgt dem Design-Thinking-Prozess: Verstehen → Beobachten → Synthese → Ideen → Roadmap.
        </div>

        {/* TOC */}
        <div style={{ marginTop: 32 }}>
          <div style={{ fontSize: 11, color: '#A8A8A0', letterSpacing: 1, textTransform: 'uppercase', fontWeight: 700, marginBottom: 12 }}>
            Inhalt · 11 Sektionen
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8, fontSize: 13, color: '#1A1A18' }}>
            {[
              ['01', 'Marktvalidierung & ROI'],
              ['02', 'Methodischer Rahmen'],
              ['03', 'Stakeholder-Map (Freeman)'],
              ['04', 'Personas (Klaus, Thomas, Anna)'],
              ['05', 'Customer Journey Map IST'],
              ['06', 'Customer Journey Map SOLL (mit ScanFair)'],
              ['07', 'Value Proposition Canvas'],
              ['08', 'Conjoint · Feature-Priorität'],
              ['09', 'User Scenarios (Klaus + Thomas)'],
              ['10', 'Kernfunktionen + 5-Step UX'],
              ['11', 'Epics · 4 Epics, 12 Stories'],
              ['12', 'Roadmap · Pilot → National'],
              ['13', 'Risiken & Mitigation'],
            ].map(([n, t]) => (
              <div key={n} style={{
                display: 'flex', gap: 12, padding: '8px 12px',
                background: '#FAFAF9', borderRadius: 6,
              }}>
                <div style={{ color: '#A8A8A0', fontFamily: '"SF Mono", monospace', fontSize: 11 }}>{n}</div>
                <div>{t}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function DiscoveryApp() {
  // Build 13 artboards — each Discovery section
  const sections = [
    { id: 'intro', label: '00 · Übersicht', width: 1200, height: 880, content: <DiscoveryIntro /> },
    { id: 'market', label: '01 · Marktvalidierung & ROI', width: 1200, height: 720, content: <window.MarketSection /> },
    { id: 'methodology', label: '02 · Methodischer Rahmen', width: 1200, height: 720, content: <window.MethodologySection /> },
    { id: 'stakeholder', label: '03 · Stakeholder-Map', width: 1200, height: 620, content: <window.StakeholderSection /> },
    { id: 'personas', label: '04 · Personas', width: 1280, height: 980, content: <window.PersonasSection /> },
    { id: 'cjm-ist', label: '05 · CJM IST · Traditioneller Supermarkt', width: 1480, height: 700, content: <window.CjmIstSection /> },
    { id: 'cjm-soll', label: '06 · CJM SOLL · Mit ScanFair', width: 1480, height: 760, content: <window.CjmSollSection /> },
    { id: 'vpc', label: '07 · Value Proposition Canvas', width: 1200, height: 820, content: <window.VpcSection /> },
    { id: 'conjoint', label: '08 · Conjoint · Feature-Priorität', width: 1200, height: 660, content: <window.ConjointSection /> },
    { id: 'scenarios', label: '09 · User Scenarios', width: 1080, height: 1620, content: <window.ScenariosSection /> },
    { id: 'kernfunktionen', label: '10 · Kernfunktionen + 5-Step UX', width: 1280, height: 700, content: <window.KernfunktionenSection /> },
    { id: 'epics', label: '11 · Epics & User Stories', width: 1200, height: 1100, content: <window.EpicsSection /> },
    { id: 'roadmap', label: '12 · Roadmap', width: 1280, height: 640, content: <window.RoadmapSection /> },
    { id: 'risks', label: '13 · Risiken & Mitigation', width: 1200, height: 620, content: <window.RisksSection /> },
  ];

  const { DesignCanvas, DCSection, DCArtboard } = window;

  return (
    <DesignCanvas title="ScanFair · Discovery">
      <DCSection id="discovery" title="Discovery — Strategischer Kontext">
        {sections.map(s => (
          <DCArtboard key={s.id} id={s.id} label={s.label} width={s.width} height={s.height}>
            {s.content}
          </DCArtboard>
        ))}
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<DiscoveryApp />);
