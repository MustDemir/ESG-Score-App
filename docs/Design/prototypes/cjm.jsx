// ScanFair Discovery — Customer Journey Maps (Ist + Soll)

const sfCjmFont = { fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif' };
const CJM_INK = '#1A1A18';
const CJM_INK_60 = '#737370';
const CJM_INK_40 = '#A8A8A0';
const CJM_LINE = '#E7E7E2';
const CJM_PAPER = '#FAFAF9';

// Emotion colors (consistent across both CJMs)
const EMOTION_COLORS = {
  'very-positive': { bg: '#DCFCE7', border: '#16A34A', emoji: '😄', text: '#15803D' },
  'positive':      { bg: '#ECFDF5', border: '#10B981', emoji: '🙂', text: '#047857' },
  'neutral':       { bg: '#F4F4F2', border: '#A8A8A0', emoji: '😐', text: '#525252' },
  'mixed':         { bg: '#FEF3C7', border: '#D97706', emoji: '😕', text: '#B45309' },
  'mild-stress':   { bg: '#FED7AA', border: '#EA580C', emoji: '😣', text: '#C2410C' },
  'high-stress':   { bg: '#FECACA', border: '#DC2626', emoji: '😫', text: '#B91C1C' },
};

// Status badge colors for SOLL CJM
const STATUS_BADGES = {
  mvp:    { bg: '#0F766E', label: 'MVP' },
  phase2: { bg: '#1E40AF', label: 'Phase 2' },
  phase3: { bg: '#7C3AED', label: 'Phase 3' },
  none:   { bg: '#A8A8A0', label: '—' },
};

// CJM Ist (traditional supermarket)
function CjmIstSection() {
  const data = window.SF_CJM_IST;
  const colWidth = 168;
  return (
    <div style={{ ...sfCjmFont, padding: '40px 60px', background: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: CJM_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Ist-Zustand · Pain Points heute
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: CJM_INK, letterSpacing: -0.3 }}>
          {data.title}
        </div>
        <div style={{ fontSize: 13, color: CJM_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          7 Phasen × 5 Dimensionen aus der Hausarbeit. <strong style={{ color: '#B91C1C' }}>Hotspots</strong> markieren
          Phasen mit der größten Pain-Point-Intensität — hier greift ScanFair.
        </div>
      </div>

      {/* CJM Table */}
      <div style={{ overflowX: 'auto', border: `1px solid ${CJM_LINE}`, borderRadius: 12 }}>
        <table style={{ borderCollapse: 'collapse', width: '100%', minWidth: 7 * colWidth + 140 }}>
          <thead>
            <tr style={{ background: CJM_PAPER }}>
              <th style={{ width: 140, padding: 12, textAlign: 'left', fontSize: 11, color: CJM_INK_40, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5, borderBottom: `1px solid ${CJM_LINE}` }}>Dimension</th>
              {data.phases.map(ph => {
                const isHotspot = ph.isPainHotspot;
                return (
                  <th key={ph.id} style={{
                    width: colWidth, padding: 12, textAlign: 'left',
                    background: isHotspot ? '#FEE2E2' : CJM_PAPER,
                    borderBottom: `1px solid ${CJM_LINE}`,
                    borderLeft: `1px solid ${CJM_LINE}`,
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div style={{
                        width: 26, height: 26, borderRadius: 13, background: '#fff',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 14, border: `1px solid ${CJM_LINE}`,
                      }}>{ph.icon}</div>
                      <div>
                        <div style={{ fontSize: 10, color: CJM_INK_40, fontWeight: 600 }}>{ph.id}</div>
                        <div style={{ fontSize: 13, fontWeight: 700, color: CJM_INK }}>{ph.name}</div>
                      </div>
                    </div>
                    {isHotspot && (
                      <div style={{ marginTop: 6, fontSize: 9, fontWeight: 700, color: '#B91C1C', letterSpacing: 0.5, textTransform: 'uppercase' }}>
                        🔥 Pain-Hotspot
                      </div>
                    )}
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {/* Aktionen */}
            <CjmRow label="Aktionen" cells={data.phases.map(ph => ph.actions)} />
            {/* Ziele */}
            <CjmRow label="Ziele & Bedürfnisse" cells={data.phases.map(ph => ph.goals)} altBg />
            {/* Touchpoints */}
            <CjmRow label="Touchpoints" cells={data.phases.map(ph => ph.touchpoints)} />
            {/* Emotion */}
            <tr>
              <td style={cjmLabelCell}>Emotionen</td>
              {data.phases.map(ph => {
                const e = EMOTION_COLORS[ph.emotion];
                return (
                  <td key={ph.id} style={{ ...cjmDataCell, background: e.bg, borderLeft: `1px solid ${CJM_LINE}` }}>
                    <div style={{ fontSize: 22, marginBottom: 4 }}>{e.emoji}</div>
                    <div style={{ fontSize: 11, color: e.text, lineHeight: 1.4 }}>{ph.emotionLabel}</div>
                  </td>
                );
              })}
            </tr>
            {/* Stakeholder */}
            <CjmRow label="Stakeholder" cells={data.phases.map(ph => ph.stakeholders)} altBg />
          </tbody>
        </table>
      </div>

      {/* Source */}
      <div style={{ marginTop: 16, fontSize: 11, color: CJM_INK_40, fontStyle: 'italic' }}>
        Quelle: Adaptiert aus eigener Hausarbeit (Demir, 2025), basierend auf Dräger & Roisch (2025), S. 35–39 und Sölen (2024), S. 37, 60–61.
      </div>
    </div>
  );
}

// CJM Soll (with ScanFair)
function CjmSollSection() {
  const data = window.SF_CJM_SOLL;
  const colWidth = 168;
  return (
    <div style={{ ...sfCjmFont, padding: '40px 60px', background: SF_PAPER }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: '#0F766E', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6, fontWeight: 700 }}>
          Soll-Zustand · Mit ScanFair
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: CJM_INK, letterSpacing: -0.3 }}>
          {data.title}
        </div>
        <div style={{ fontSize: 13, color: CJM_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Dieselben 7 Phasen — wo greift ScanFair konkret ein? Welche Wireframe-Screens decken die Phase ab?
          Welcher Pain wird gelöst?
        </div>
      </div>

      <div style={{ overflowX: 'auto', border: `1px solid ${CJM_LINE}`, borderRadius: 12, background: '#fff' }}>
        <table style={{ borderCollapse: 'collapse', width: '100%', minWidth: 7 * colWidth + 140 }}>
          <thead>
            <tr style={{ background: '#F0FDFA' }}>
              <th style={{ width: 140, padding: 12, textAlign: 'left', fontSize: 11, color: CJM_INK_40, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5, borderBottom: `1px solid ${CJM_LINE}` }}>Dimension</th>
              {data.phases.map(ph => {
                const istPhase = window.SF_CJM_IST.phases.find(p => p.id === ph.id);
                const isHero = ph.isHero;
                return (
                  <th key={ph.id} style={{
                    width: colWidth, padding: 12, textAlign: 'left',
                    background: isHero ? '#CCFBF1' : '#F0FDFA',
                    borderBottom: `1px solid ${CJM_LINE}`,
                    borderLeft: `1px solid ${CJM_LINE}`,
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div style={{
                        width: 26, height: 26, borderRadius: 13, background: '#fff',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 14, border: `1px solid ${CJM_LINE}`,
                      }}>{ph.icon}</div>
                      <div>
                        <div style={{ fontSize: 10, color: CJM_INK_40, fontWeight: 600 }}>{ph.id}</div>
                        <div style={{ fontSize: 13, fontWeight: 700, color: CJM_INK }}>{istPhase.name}</div>
                      </div>
                    </div>
                    {isHero && (
                      <div style={{ marginTop: 6, fontSize: 9, fontWeight: 700, color: '#0F766E', letterSpacing: 0.5, textTransform: 'uppercase' }}>
                        ⭐ Kern-Use-Case
                      </div>
                    )}
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {/* ScanFair Feature */}
            <tr>
              <td style={cjmLabelCell}>ScanFair-Funktion</td>
              {data.phases.map(ph => {
                const status = STATUS_BADGES[ph.sfStatus];
                return (
                  <td key={ph.id} style={{ ...cjmDataCell, borderLeft: `1px solid ${CJM_LINE}` }}>
                    <div style={{
                      display: 'inline-flex', padding: '3px 8px', borderRadius: 4,
                      background: status.bg, color: '#fff', fontSize: 9, fontWeight: 700,
                      letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 6,
                    }}>{status.label}</div>
                    <div style={{ fontSize: 11, color: CJM_INK, fontWeight: 600, lineHeight: 1.4 }}>
                      {ph.sfFeature}
                    </div>
                  </td>
                );
              })}
            </tr>
            {/* Verbesserung */}
            <tr style={{ background: CJM_PAPER }}>
              <td style={cjmLabelCell}>Was ändert sich?</td>
              {data.phases.map(ph => (
                <td key={ph.id} style={{ ...cjmDataCell, background: CJM_PAPER, borderLeft: `1px solid ${CJM_LINE}` }}>
                  <div style={{ fontSize: 11, color: CJM_INK_60, lineHeight: 1.5 }}>{ph.improvement}</div>
                </td>
              ))}
            </tr>
            {/* Linked Screen */}
            <tr>
              <td style={cjmLabelCell}>Wireframe-Screen</td>
              {data.phases.map(ph => (
                <td key={ph.id} style={{ ...cjmDataCell, borderLeft: `1px solid ${CJM_LINE}` }}>
                  {ph.sfScreen ? (
                    <div style={{
                      display: 'inline-block', padding: '4px 8px', border: `1px dashed #0F766E`,
                      borderRadius: 4, fontSize: 11, color: '#0F766E', fontWeight: 600,
                      fontFamily: '"SF Mono", monospace',
                    }}>{ph.sfScreen}</div>
                  ) : (
                    <span style={{ fontSize: 11, color: CJM_INK_40 }}>—</span>
                  )}
                </td>
              ))}
            </tr>
            {/* Pain Solved */}
            <tr style={{ background: CJM_PAPER }}>
              <td style={cjmLabelCell}>Pain gelöst</td>
              {data.phases.map(ph => (
                <td key={ph.id} style={{ ...cjmDataCell, background: CJM_PAPER, borderLeft: `1px solid ${CJM_LINE}` }}>
                  {ph.painSolved ? (
                    <div style={{ fontSize: 11, color: CJM_INK, lineHeight: 1.5 }}>
                      <span style={{ color: '#16A34A', marginRight: 4 }}>✓</span>
                      {ph.painSolved}
                    </div>
                  ) : (
                    <span style={{ fontSize: 11, color: CJM_INK_40 }}>—</span>
                  )}
                </td>
              ))}
            </tr>
            {/* Emotion (improved) */}
            <tr>
              <td style={cjmLabelCell}>Emotion (neu)</td>
              {data.phases.map(ph => {
                const e = EMOTION_COLORS[ph.emotion];
                const istPhase = window.SF_CJM_IST.phases.find(p => p.id === ph.id);
                const eIst = EMOTION_COLORS[istPhase.emotion];
                return (
                  <td key={ph.id} style={{ ...cjmDataCell, background: e.bg, borderLeft: `1px solid ${CJM_LINE}` }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                      <div style={{ fontSize: 22 }}>{e.emoji}</div>
                      {eIst.emoji !== e.emoji && (
                        <div style={{ fontSize: 11, color: e.text, fontWeight: 700 }}>
                          ↑ von {eIst.emoji}
                        </div>
                      )}
                    </div>
                    <div style={{ fontSize: 11, color: e.text, lineHeight: 1.4 }}>{ph.emotionLabel}</div>
                  </td>
                );
              })}
            </tr>
          </tbody>
        </table>
      </div>

      <div style={{ marginTop: 16, fontSize: 11, color: CJM_INK_40, fontStyle: 'italic' }}>
        ScanFair greift in 5 von 7 Phasen ein — am stärksten in Phase 4 (Einkauf), wo der Hauptnutzen liegt.
      </div>
    </div>
  );
}

const cjmLabelCell = {
  padding: '12px 14px', verticalAlign: 'top', borderBottom: `1px solid ${CJM_LINE}`,
  fontSize: 11, color: CJM_INK_60, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5,
  background: '#fff', position: 'sticky', left: 0,
};
const cjmDataCell = {
  padding: '12px 14px', verticalAlign: 'top', borderBottom: `1px solid ${CJM_LINE}`,
};

function CjmRow({ label, cells, altBg }) {
  return (
    <tr style={altBg ? { background: CJM_PAPER } : {}}>
      <td style={cjmLabelCell}>{label}</td>
      {cells.map((items, i) => (
        <td key={i} style={{ ...cjmDataCell, background: altBg ? CJM_PAPER : '#fff', borderLeft: `1px solid ${CJM_LINE}` }}>
          <ul style={{ margin: 0, paddingLeft: 16, fontSize: 11, color: CJM_INK, lineHeight: 1.7 }}>
            {items.map((it, j) => <li key={j}>{it}</li>)}
          </ul>
        </td>
      ))}
    </tr>
  );
}

window.CjmIstSection = CjmIstSection;
window.CjmSollSection = CjmSollSection;
