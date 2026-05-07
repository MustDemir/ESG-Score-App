// ScanFair Discovery — Scroll-Variante (vertikal, kein Canvas)
// Alle Sektionen untereinander, mit Sticky-TOC links

const { useState: useStateScroll, useEffect: useEffectScroll } = React;

// ────────────────────────────────────────────────────────────────
// INTRO / HERO
// ────────────────────────────────────────────────────────────────

function DiscoveryHeroScroll() {
  return (
    <section id="intro" style={{
      padding: '64px 80px 56px',
      background: 'linear-gradient(180deg, #fff 0%, #FAFAF9 100%)',
      borderBottom: '1px solid #E7E7E2',
    }}>
      <div style={{ maxWidth: 900 }}>
        <div style={{ fontSize: 11, color: '#0F7B5C', letterSpacing: 2, textTransform: 'uppercase', marginBottom: 12, fontWeight: 700 }}>
          ScanFair · Phase 0 — Discovery
        </div>
        <h1 style={{
          fontSize: 56, fontWeight: 800, color: '#1A1A18', letterSpacing: -1,
          margin: 0, lineHeight: 1.05,
        }}>
          Discovery & Strategischer Kontext
        </h1>
        <p style={{
          fontSize: 18, color: '#525252', marginTop: 20, lineHeight: 1.6, maxWidth: 760,
        }}>
          Das Fundament unter den Wireframes: Personas, Customer Journey Maps (Ist + Soll),
          Value Proposition Canvas, User Scenarios, Conjoint-Priorisierung, Epics, Roadmap und Risiken.
          Verdichtet aus der Hausarbeit (Demir, 2025) und dem PITCH.md.
        </p>
        <div style={{
          marginTop: 24, padding: '14px 18px',
          background: '#E8F2EE', borderLeft: '4px solid #0F7B5C', borderRadius: 8,
          fontSize: 13, color: '#1A1A18', lineHeight: 1.6, maxWidth: 760,
        }}>
          <strong>📜 Scroll-Ansicht:</strong> Alle 14 Sektionen vertikal. Über das Sticky-Menü links
          springst du direkt zu jedem Kapitel. Pfeiltasten ↑↓ blättern Sektion für Sektion.
          {' '}
          <a href="00-discovery.html" style={{ color: '#0F7B5C', fontWeight: 600 }}>
            ↗ Zur Canvas-Ansicht wechseln
          </a>
        </div>
      </div>
    </section>
  );
}

// ────────────────────────────────────────────────────────────────
// SCROLL CONTAINER für eine Sektion
// ────────────────────────────────────────────────────────────────

function ScrollSection({ id, num, title, fullBleed, children }) {
  return (
    <section id={id} style={{
      padding: '48px 0',
      borderBottom: '1px solid #E7E7E2',
      background: '#FAFAF9',
      scrollMarginTop: 20,
    }}>
      {/* Section-Header */}
      <div style={{ padding: '0 80px', marginBottom: 24 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', gap: 16,
          fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
        }}>
          <div style={{
            fontSize: 13, fontWeight: 700, color: '#0F7B5C',
            fontFamily: '"SF Mono", monospace', letterSpacing: 1,
          }}>
            {num}
          </div>
          <h2 style={{
            margin: 0, fontSize: 22, fontWeight: 700, color: '#1A1A18', letterSpacing: -0.3,
          }}>
            {title}
          </h2>
        </div>
      </div>

      {/* Section Body — natürliche Höhe, volle Breite, optional horizontal scroll für extrabreite Inhalte */}
      <div style={{
        padding: fullBleed ? '0 24px' : '0 80px',
      }}>
        <div style={{
          background: '#fff',
          borderRadius: 16,
          border: '1px solid #E7E7E2',
          boxShadow: '0 2px 12px rgba(0,0,0,0.04)',
          overflow: fullBleed ? 'auto' : 'hidden',
        }}>
          {children}
        </div>
      </div>
    </section>
  );
}

// ────────────────────────────────────────────────────────────────
// STICKY TOC (links)
// ────────────────────────────────────────────────────────────────

function StickyToc({ sections }) {
  const [active, setActive] = useStateScroll('intro');

  useEffectScroll(() => {
    const handleScroll = () => {
      // Sektion bestimmen, deren Top-Kante am nächsten zum Viewport-Top ist
      let current = 'intro';
      for (const s of sections) {
        const el = document.getElementById(s.id);
        if (el) {
          const rect = el.getBoundingClientRect();
          if (rect.top <= 120) current = s.id;
        }
      }
      setActive(current);
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll();
    return () => window.removeEventListener('scroll', handleScroll);
  }, [sections]);

  return (
    <nav style={{
      position: 'sticky', top: 24, alignSelf: 'flex-start',
      width: 220, flexShrink: 0,
      padding: '20px 16px',
      background: '#fff',
      borderRadius: 12,
      border: '1px solid #E7E7E2',
      fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
      maxHeight: 'calc(100vh - 48px)',
      overflowY: 'auto',
    }}>
      <div style={{
        fontSize: 10, color: '#A8A8A0', letterSpacing: 1.5, textTransform: 'uppercase',
        fontWeight: 700, marginBottom: 12, paddingLeft: 8,
      }}>
        Inhalt
      </div>
      <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
        {sections.map(s => {
          const isActive = active === s.id;
          return (
            <li key={s.id}>
              <a
                href={`#${s.id}`}
                style={{
                  display: 'flex',
                  gap: 8,
                  padding: '7px 8px',
                  fontSize: 12,
                  color: isActive ? '#0F7B5C' : '#525252',
                  fontWeight: isActive ? 700 : 500,
                  textDecoration: 'none',
                  borderRadius: 6,
                  background: isActive ? '#E8F2EE' : 'transparent',
                  borderLeft: isActive ? '3px solid #0F7B5C' : '3px solid transparent',
                  lineHeight: 1.3,
                }}
              >
                <span style={{
                  fontFamily: '"SF Mono", monospace',
                  fontSize: 10,
                  color: isActive ? '#0F7B5C' : '#A8A8A0',
                  flexShrink: 0,
                }}>
                  {s.num}
                </span>
                <span>{s.short}</span>
              </a>
            </li>
          );
        })}
      </ul>

      <div style={{
        marginTop: 16, paddingTop: 12, borderTop: '1px solid #E7E7E2',
      }}>
        <a href="00-discovery.html" style={{
          fontSize: 11, color: '#0F7B5C', textDecoration: 'none', fontWeight: 600,
          display: 'flex', alignItems: 'center', gap: 6, padding: '6px 8px',
        }}>
          ↗ Canvas-Ansicht
        </a>
      </div>
    </nav>
  );
}

// ────────────────────────────────────────────────────────────────
// MAIN APP
// ────────────────────────────────────────────────────────────────

function DiscoveryScrollApp() {
  const sections = [
    { id: 'intro',          num: '00', short: 'Übersicht',                   title: 'Übersicht',                                        fullBleed: false, Component: null },
    { id: 'market',         num: '01', short: 'Markt & ROI',                  title: 'Marktvalidierung & ROI',                          fullBleed: false, Component: window.MarketSection },
    { id: 'methodology',    num: '02', short: 'Methodik',                     title: 'Methodischer Rahmen',                             fullBleed: false, Component: window.MethodologySection },
    { id: 'stakeholder',    num: '03', short: 'Stakeholder',                  title: 'Stakeholder-Map (Freeman)',                       fullBleed: false, Component: window.StakeholderSection },
    { id: 'personas',       num: '04', short: 'Personas',                     title: 'Personas — Klaus, Thomas, Anna',                  fullBleed: false, Component: window.PersonasSection },
    { id: 'cjm-ist',        num: '05', short: 'CJM IST',                      title: 'Customer Journey Map IST',                        fullBleed: true,  Component: window.CjmIstSection },
    { id: 'cjm-soll',       num: '06', short: 'CJM SOLL',                     title: 'Customer Journey Map SOLL (mit ScanFair)',        fullBleed: true,  Component: window.CjmSollSection },
    { id: 'vpc',            num: '07', short: 'Value Proposition',            title: 'Value Proposition Canvas',                        fullBleed: false, Component: window.VpcSection },
    { id: 'conjoint',       num: '08', short: 'Conjoint',                     title: 'Conjoint — Feature-Priorität',                    fullBleed: false, Component: window.ConjointSection },
    { id: 'scenarios',      num: '09', short: 'User Scenarios',               title: 'User Scenarios — Klaus + Thomas',                 fullBleed: false, Component: window.ScenariosSection },
    { id: 'kernfunktionen', num: '10', short: 'Kernfunktionen',               title: 'Kernfunktionen + 5-Step UX',                      fullBleed: false, Component: window.KernfunktionenSection },
    { id: 'epics',          num: '11', short: 'Epics & Stories',              title: 'Epics — 4 Epics · 12 Stories',                    fullBleed: false, Component: window.EpicsSection },
    { id: 'roadmap',        num: '12', short: 'Roadmap',                      title: 'Roadmap — Pilot → National',                      fullBleed: false, Component: window.RoadmapSection },
    { id: 'risks',          num: '13', short: 'Risiken',                      title: 'Risiken & Mitigation',                            fullBleed: false, Component: window.RisksSection },
  ];

  // Pfeiltasten ↑↓ navigieren zwischen Sektionen
  useEffectScroll(() => {
    const handleKey = (e) => {
      if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return;
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      e.preventDefault();

      // aktuelle Sektion finden
      let currentIdx = 0;
      for (let i = 0; i < sections.length; i++) {
        const el = document.getElementById(sections[i].id);
        if (el && el.getBoundingClientRect().top <= 120) currentIdx = i;
      }
      const nextIdx = e.key === 'ArrowDown'
        ? Math.min(currentIdx + 1, sections.length - 1)
        : Math.max(currentIdx - 1, 0);
      const next = document.getElementById(sections[nextIdx].id);
      if (next) {
        const top = next.getBoundingClientRect().top + window.pageYOffset - 16;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, []);

  return (
    <div style={{
      display: 'flex',
      gap: 24,
      padding: '24px 24px 80px',
      maxWidth: 1700,
      margin: '0 auto',
      fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
    }}>
      <StickyToc sections={sections} />

      <main style={{ flex: 1, minWidth: 0 }}>
        <DiscoveryHeroScroll />

        {sections.slice(1).map(s => {
          const Comp = s.Component;
          if (!Comp) return null;
          return (
            <ScrollSection
              key={s.id}
              id={s.id}
              num={s.num}
              title={s.title}
              fullBleed={s.fullBleed}
            >
              <Comp />
            </ScrollSection>
          );
        })}

        <footer style={{
          padding: '40px 80px',
          textAlign: 'center',
          fontSize: 12,
          color: '#A8A8A0',
        }}>
          ScanFair · Discovery · Phase 0 — Mustafa Demir 2025
        </footer>
      </main>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<DiscoveryScrollApp />);
