// ScanFair Discovery — Epics, Roadmap, Risks, Methodology

const sfErFont = { fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif' };
const ER_INK = '#1A1A18';
const ER_INK_60 = '#737370';
const ER_INK_40 = '#A8A8A0';
const ER_LINE = '#E7E7E2';
const ER_PAPER = '#FAFAF9';

// ───────────────────────────────────────────────────
// Epics & User Stories
// ───────────────────────────────────────────────────
function EpicsSection() {
  const epics = window.SF_EPICS;
  const colors = {
    mvp:    { bg: '#F0FDFA', border: '#0F766E', label: 'MVP', labelBg: '#0F766E' },
    phase2: { bg: '#EFF6FF', border: '#1E40AF', label: 'Phase 2', labelBg: '#1E40AF' },
    phase3: { bg: '#F5F3FF', border: '#7C3AED', label: 'Phase 3', labelBg: '#7C3AED' },
  };
  return (
    <div style={{ ...sfErFont, padding: '40px 60px', background: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: ER_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Backlog · Agile Anforderungen
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: ER_INK, letterSpacing: -0.3 }}>
          4 Epics · {epics.reduce((a, e) => a + e.stories.length, 0)} User Stories
        </div>
        <div style={{ fontSize: 13, color: ER_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Aus der Hausarbeit übernommen. Diese Epics + Stories bilden das Backlog für den Developer-Handoff (Phase 4).
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {epics.map(epic => {
          const c = colors[epic.status];
          return (
            <div key={epic.id} style={{
              background: c.bg, border: `2px solid ${c.border}`, borderRadius: 12, overflow: 'hidden',
            }}>
              <div style={{
                padding: 16, display: 'flex', alignItems: 'center', gap: 16,
                background: '#fff', borderBottom: `1px solid ${ER_LINE}`,
              }}>
                <div style={{
                  padding: '4px 10px', background: c.labelBg, color: '#fff',
                  fontSize: 10, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', borderRadius: 4,
                }}>{c.label}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 15, fontWeight: 700, color: ER_INK }}>{epic.name}</div>
                  <div style={{ fontSize: 12, color: ER_INK_60, marginTop: 2 }}>{epic.description}</div>
                </div>
              </div>
              <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 8 }}>
                {epic.stories.map((s, i) => (
                  <div key={i} style={{
                    padding: 12, background: '#fff', border: `1px solid ${ER_LINE}`, borderRadius: 8,
                    fontSize: 12, color: ER_INK, lineHeight: 1.55,
                  }}>
                    <span style={{ color: c.border, fontWeight: 700, marginRight: 6 }}>US{i + 1}</span>
                    {s}
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop: 16, fontSize: 11, color: ER_INK_40, fontStyle: 'italic' }}>
        Quelle: Eigene Darstellung nach Schwaber & Sutherland (2020); Hausarbeit Demir (2025), Folie 5.
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Roadmap
// ───────────────────────────────────────────────────
function RoadmapSection() {
  const phases = window.SF_ROADMAP;
  return (
    <div style={{ ...sfErFont, padding: '40px 60px', background: ER_PAPER }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: ER_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Pilot → Region → National
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: ER_INK, letterSpacing: -0.3 }}>
          Roadmap & Pilot-Plan
        </div>
        <div style={{ fontSize: 13, color: ER_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Dreiphasiger Rollout nach Lean Startup (Ries, 2011) + Kotter 8-Stufen (Kotter, 2014). Risikoarm,
          datengestützt, skalierbar.
        </div>
      </div>

      <div style={{ display: 'flex', gap: 16 }}>
        {phases.map((p, i) => {
          const c = i === 0 ? '#0F766E' : i === 1 ? '#1E40AF' : '#7C3AED';
          return (
            <div key={i} style={{
              flex: 1, background: '#fff', border: `2px solid ${c}`, borderRadius: 12, overflow: 'hidden',
            }}>
              <div style={{ padding: '14px 16px', background: c, color: '#fff' }}>
                <div style={{ fontSize: 11, opacity: 0.85, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>
                  {p.phase} · {p.timeline}
                </div>
                <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2 }}>{p.label}</div>
              </div>
              <div style={{ padding: 16 }}>
                <div style={{ fontSize: 12, color: ER_INK, fontWeight: 600, marginBottom: 12 }}>{p.scope}</div>

                <div style={{ fontSize: 10, color: ER_INK_40, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 6 }}>
                  Features
                </div>
                <ul style={{ margin: '0 0 16px', paddingLeft: 16, fontSize: 12, color: ER_INK, lineHeight: 1.7 }}>
                  {p.features.map((f, j) => <li key={j}>{f}</li>)}
                </ul>

                <div style={{ display: 'flex', gap: 12, marginBottom: 12, padding: 10, background: ER_PAPER, borderRadius: 8 }}>
                  <div>
                    <div style={{ fontSize: 9, color: ER_INK_40, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase' }}>Budget</div>
                    <div style={{ fontSize: 14, color: c, fontWeight: 700, marginTop: 2 }}>{p.budget}</div>
                  </div>
                </div>

                <div style={{ fontSize: 10, color: ER_INK_40, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 6 }}>
                  KPIs
                </div>
                <ul style={{ margin: 0, paddingLeft: 16, fontSize: 11, color: ER_INK_60, lineHeight: 1.6 }}>
                  {p.metrics.map((m, j) => <li key={j}>{m}</li>)}
                </ul>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Risks & Mitigation
// ───────────────────────────────────────────────────
function RisksSection() {
  const risks = window.SF_RISKS;
  const sevColors = {
    high:   { bg: '#FEE2E2', border: '#DC2626', text: '#B91C1C', label: 'Hoch' },
    medium: { bg: '#FEF3C7', border: '#D97706', text: '#B45309', label: 'Mittel' },
    low:    { bg: '#DCFCE7', border: '#16A34A', text: '#15803D', label: 'Niedrig' },
  };
  return (
    <div style={{ ...sfErFont, padding: '40px 60px', background: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: ER_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Proaktiv adressiert
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: ER_INK, letterSpacing: -0.3 }}>
          Risiken & Mitigationsstrategien
        </div>
        <div style={{ fontSize: 13, color: ER_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Transparente Darstellung von Risiken stärkt die Glaubwürdigkeit. Für jedes Risiko ist eine konkrete
          Mitigation definiert.
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
        {risks.map((r, i) => {
          const s = sevColors[r.severity];
          return (
            <div key={i} style={{
              background: ER_PAPER, border: `1px solid ${ER_LINE}`, borderLeft: `4px solid ${s.border}`,
              borderRadius: 10, padding: 16,
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: ER_INK, flex: 1 }}>{r.risk}</div>
                <div style={{
                  padding: '3px 8px', background: s.bg, color: s.text,
                  fontSize: 10, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', borderRadius: 4,
                }}>{s.label}</div>
              </div>
              <div style={{ marginBottom: 10 }}>
                <div style={{ fontSize: 9, color: ER_INK_40, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 4 }}>
                  Impact
                </div>
                <div style={{ fontSize: 12, color: ER_INK, lineHeight: 1.55 }}>{r.impact}</div>
              </div>
              <div style={{ paddingTop: 10, borderTop: `1px solid ${ER_LINE}` }}>
                <div style={{ fontSize: 9, color: '#16A34A', fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 4 }}>
                  ✓ Mitigation
                </div>
                <div style={{ fontSize: 12, color: ER_INK, lineHeight: 1.55 }}>{r.mitigation}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Methodology Section
// ───────────────────────────────────────────────────
function MethodologySection() {
  const m = window.SF_METHODOLOGY;
  return (
    <div style={{ ...sfErFont, padding: '40px 60px', background: ER_PAPER }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: ER_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Wissenschaftlicher Rahmen
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: ER_INK, letterSpacing: -0.3 }}>
          Methodischer Ansatz
        </div>
        <div style={{ fontSize: 13, color: ER_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Design Thinking + Requirements Engineering, ergänzt um Service Design und Lean Startup. Jedes Framework
          adressiert eine spezifische Herausforderung im Konzeptprozess.
        </div>
      </div>

      {/* Design Thinking phases */}
      <div style={{
        padding: 20, background: '#fff', border: `1px solid ${ER_LINE}`, borderRadius: 12, marginBottom: 20,
      }}>
        <div style={{ fontSize: 11, color: ER_INK_40, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 12 }}>
          Design Thinking — Prozessmodell
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {m.phases.map((p, i) => (
            <React.Fragment key={i}>
              <div style={{
                flex: 1, padding: '12px 14px', background: '#F0FDFA',
                border: `2px solid #0F766E`, borderRadius: 8, textAlign: 'center',
              }}>
                <div style={{ fontSize: 10, color: '#0F766E', fontWeight: 700 }}>{i + 1}</div>
                <div style={{ fontSize: 13, fontWeight: 700, color: ER_INK, marginTop: 2 }}>{p}</div>
              </div>
              {i < m.phases.length - 1 && (
                <div style={{ color: ER_INK_40, fontSize: 16 }}>→</div>
              )}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* Frameworks */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
        {m.frameworks.map((f, i) => (
          <div key={i} style={{
            padding: 14, background: '#fff', border: `1px solid ${ER_LINE}`, borderRadius: 8,
          }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: ER_INK, marginBottom: 4 }}>{f.name}</div>
            <div style={{ fontSize: 11, color: ER_INK_60, lineHeight: 1.5, marginBottom: 6 }}>{f.purpose}</div>
            <div style={{ fontSize: 10, color: ER_INK_40, fontStyle: 'italic' }}>{f.source}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

window.EpicsSection = EpicsSection;
window.RoadmapSection = RoadmapSection;
window.RisksSection = RisksSection;
window.MethodologySection = MethodologySection;
