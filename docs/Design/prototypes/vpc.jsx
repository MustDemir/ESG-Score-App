// ScanFair Discovery — Value Proposition Canvas, Stakeholder, Conjoint, Market

const sfVpcFont = { fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif' };
const VPC_INK = '#1A1A18';
const VPC_INK_60 = '#737370';
const VPC_INK_40 = '#A8A8A0';
const VPC_LINE = '#E7E7E2';
const VPC_PAPER = '#FAFAF9';

// ───────────────────────────────────────────────────
// Value Proposition Canvas
// ───────────────────────────────────────────────────
function VpcSection() {
  const v = window.SF_VPC;
  return (
    <div style={{ ...sfVpcFont, padding: '40px 60px', background: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: VPC_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Strategy · Product-Market-Fit
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: VPC_INK, letterSpacing: -0.3 }}>
          Value Proposition Canvas
        </div>
        <div style={{ fontSize: 13, color: VPC_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Nach Osterwalder et al. (2014). Links das Kundenprofil (Pains, Gains, Jobs), rechts unser Wertangebot.
          Die Pfeile zeigen, wie ScanFair-Features konkrete Pains lindern und Gains schaffen.
        </div>
      </div>

      <div style={{ display: 'flex', gap: 20, alignItems: 'stretch' }}>
        {/* Customer (circle) */}
        <div style={{
          flex: 1, background: '#FEF2F2', border: '2px solid #DC2626', borderRadius: 16, padding: 24,
        }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#DC2626', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 16 }}>
            Kunde · Customer Profile
          </div>
          <VpcBlock title="Pains" emoji="⚠️" color="#DC2626" items={v.customer.pains} />
          <VpcBlock title="Gains" emoji="✨" color="#16A34A" items={v.customer.gains} />
          <VpcBlock title="Jobs to be Done" emoji="🎯" color="#1E40AF" items={v.customer.jobs} />
        </div>

        {/* Arrow */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{
            width: 40, height: 40, borderRadius: 20, background: '#0F766E',
            color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 20, fontWeight: 700,
          }}>+</div>
        </div>

        {/* Product (square) */}
        <div style={{
          flex: 1, background: '#F0FDFA', border: '2px solid #0F766E', borderRadius: 16, padding: 24,
        }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#0F766E', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 16 }}>
            ScanFair · Value Map
          </div>
          <VpcBlock title="Pain Relievers" emoji="🛡️" color="#0F766E" items={v.product.relievers} />
          <VpcBlock title="Gain Creators" emoji="🚀" color="#16A34A" items={v.product.creators} />
          <VpcBlock title="Products & Services" emoji="📱" color="#1E40AF" items={v.product.products} />
        </div>
      </div>

      <div style={{ marginTop: 16, fontSize: 11, color: VPC_INK_40, fontStyle: 'italic' }}>
        Quelle: Eigene Darstellung nach Osterwalder, Pigneur, Bernarda & Smith (2014).
      </div>
    </div>
  );
}

function VpcBlock({ title, emoji, color, items }) {
  return (
    <div style={{
      background: '#fff', border: `1px solid ${VPC_LINE}`, borderRadius: 10,
      padding: 14, marginBottom: 12,
    }}>
      <div style={{ fontSize: 11, fontWeight: 700, color, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 8 }}>
        {emoji} {title}
      </div>
      <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12, color: VPC_INK, lineHeight: 1.7 }}>
        {items.map((it, i) => <li key={i}>{it}</li>)}
      </ul>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Stakeholder Map (Freeman)
// ───────────────────────────────────────────────────
function StakeholderSection() {
  const s = window.SF_STAKEHOLDERS;
  const groups = [
    { key: 'primary',   color: '#0F766E', bg: '#F0FDFA' },
    { key: 'secondary', color: '#1E40AF', bg: '#EFF6FF' },
    { key: 'tertiary',  color: '#7C3AED', bg: '#F5F3FF' },
  ];
  return (
    <div style={{ ...sfVpcFont, padding: '40px 60px', background: VPC_PAPER }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: VPC_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Ökosystem
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: VPC_INK, letterSpacing: -0.3 }}>
          Stakeholder-Map
        </div>
        <div style={{ fontSize: 13, color: VPC_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Nach Freeman (1984). ScanFair ist nicht isoliert — drei Stakeholder-Ringe beeinflussen Konzept und Rollout.
        </div>
      </div>

      <div style={{ display: 'flex', gap: 20 }}>
        {groups.map(g => {
          const grp = s[g.key];
          return (
            <div key={g.key} style={{
              flex: 1, padding: 20, background: g.bg, border: `2px solid ${g.color}`, borderRadius: 12,
            }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: g.color, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 14 }}>
                {grp.label}
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {grp.items.map((it, i) => (
                  <div key={i} style={{
                    background: '#fff', border: `1px solid ${VPC_LINE}`, borderRadius: 8, padding: 12,
                  }}>
                    <div style={{ fontSize: 13, fontWeight: 700, color: VPC_INK, marginBottom: 4 }}>{it.name}</div>
                    <div style={{ fontSize: 11, color: VPC_INK_60, lineHeight: 1.5 }}>{it.role}</div>
                    {it.personas && (
                      <div style={{ marginTop: 6, fontSize: 10, color: g.color, fontWeight: 600 }}>
                        → {it.personas.join(' · ')}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Conjoint-Analyse Feature-Priorität
// ───────────────────────────────────────────────────
function ConjointSection() {
  const data = window.SF_CONJOINT;
  const max = Math.max(...data.map(d => d.weight));
  return (
    <div style={{ ...sfVpcFont, padding: '40px 60px', background: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: VPC_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Datengestützte Priorisierung
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, color: VPC_INK, letterSpacing: -0.3 }}>
          Conjoint-Analyse · Feature-Priorität
        </div>
        <div style={{ fontSize: 13, color: VPC_INK_60, marginTop: 8, maxWidth: 800, lineHeight: 1.6 }}>
          Relative Wichtigkeit aus der Hausarbeit-Conjoint-Analyse. Diese Daten steuern direkt unsere
          Layout-Entscheidungen: Echtzeit-Score (35%) ist Hero in S3, Personalisierung (25%) prominent,
          Lieferketten-Transparenz (20%) eigene Sektion in S4.
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {data.map((d, i) => {
          const status = window.STATUS_BADGES_CJM ? window.STATUS_BADGES_CJM[d.status] : { mvp: { bg: '#0F766E', label: 'MVP' }, phase2: { bg: '#1E40AF', label: 'Phase 2' } }[d.status] || { bg: '#A8A8A0', label: '—' };
          const sBg = d.status === 'mvp' ? '#0F766E' : d.status === 'phase2' ? '#1E40AF' : '#A8A8A0';
          const sLabel = d.status === 'mvp' ? 'MVP' : d.status === 'phase2' ? 'Phase 2' : '—';
          return (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 16,
              padding: 16, background: VPC_PAPER, border: `1px solid ${VPC_LINE}`, borderRadius: 10,
            }}>
              <div style={{ width: 28, fontSize: 18, fontWeight: 700, color: VPC_INK_40, textAlign: 'right' }}>
                {i + 1}
              </div>
              <div style={{ flex: '0 0 280px' }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: VPC_INK, marginBottom: 2 }}>{d.feature}</div>
                <div style={{ fontSize: 11, color: VPC_INK_60, fontFamily: '"SF Mono", monospace' }}>
                  {d.screen}
                </div>
              </div>
              <div style={{ flex: 1, position: 'relative', height: 32, background: '#fff', borderRadius: 6, border: `1px solid ${VPC_LINE}`, overflow: 'hidden' }}>
                <div style={{
                  position: 'absolute', left: 0, top: 0, bottom: 0,
                  width: `${(d.weight / max) * 100}%`,
                  background: `linear-gradient(90deg, #0F766E, #14B8A6)`,
                  display: 'flex', alignItems: 'center', justifyContent: 'flex-end', paddingRight: 12,
                  color: '#fff', fontSize: 13, fontWeight: 700,
                }}>
                  {d.weight}%
                </div>
              </div>
              <div style={{
                padding: '4px 10px', background: sBg, color: '#fff',
                fontSize: 10, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', borderRadius: 4,
              }}>{sLabel}</div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop: 16, fontSize: 11, color: VPC_INK_40, fontStyle: 'italic' }}>
        Quelle: Eigene Darstellung nach Green & Srinivasan (1990); Hausarbeit Demir (2025). Hypothetische Daten — Validierung im Pilot.
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────
// Market Stats (Killer Stats from Hausarbeit)
// ───────────────────────────────────────────────────
function MarketSection() {
  const m = window.SF_MARKET;
  return (
    <div style={{ ...sfVpcFont, padding: '40px 60px', background: '#0F172A', color: '#fff' }}>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: '#94A3B8', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6, fontWeight: 700 }}>
          Marktvalidierung
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -0.3 }}>
          Der Markt ruft — die Daten sind eindeutig
        </div>
      </div>

      {/* Killer Stat — full width */}
      <div style={{
        padding: 32, background: 'linear-gradient(135deg, #0F766E, #14B8A6)', borderRadius: 16,
        display: 'flex', alignItems: 'center', gap: 32, marginBottom: 24,
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 64, fontWeight: 800, lineHeight: 1, letterSpacing: -2 }}>
            {m.killerStat.ready}%
          </div>
          <div style={{ fontSize: 14, marginTop: 8, opacity: 0.9, lineHeight: 1.5 }}>
            der Verbraucher sind bereit, mehr für nachhaltige Produkte zu zahlen.
          </div>
        </div>
        <div style={{ width: 1, alignSelf: 'stretch', background: 'rgba(255,255,255,0.3)' }} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 64, fontWeight: 800, lineHeight: 1, letterSpacing: -2, color: '#FBBF24' }}>
            {m.killerStat.find}%
          </div>
          <div style={{ fontSize: 14, marginTop: 8, opacity: 0.9, lineHeight: 1.5 }}>
            finden verlässliche Informationen am Point of Sale.
          </div>
        </div>
      </div>

      <div style={{ fontSize: 11, color: '#94A3B8', marginBottom: 20, fontStyle: 'italic' }}>
        Quelle: {m.killerStat.source}. Diese Lücke schließt ScanFair.
      </div>

      {/* Growth Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: 24 }}>
        {m.growth.map((g, i) => (
          <div key={i} style={{
            padding: 20, background: '#1E293B', borderRadius: 12, border: '1px solid #334155',
          }}>
            <div style={{ fontSize: 36, fontWeight: 800, color: '#5EEAD4', letterSpacing: -1 }}>
              {g.value}
            </div>
            <div style={{ fontSize: 13, color: '#fff', marginTop: 6, fontWeight: 600 }}>{g.label}</div>
            <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 4 }}>{g.period}</div>
            <div style={{ fontSize: 10, color: '#64748B', marginTop: 8, fontStyle: 'italic' }}>{g.source}</div>
          </div>
        ))}
      </div>

      {/* ROI Prognose */}
      <div style={{ padding: 20, background: '#1E293B', borderRadius: 12, border: '1px solid #334155' }}>
        <div style={{ fontSize: 11, color: '#94A3B8', letterSpacing: 1, textTransform: 'uppercase', fontWeight: 700, marginBottom: 14 }}>
          ROI-Prognose · Pilot-Projekt
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
          {m.roi.map((r, i) => (
            <div key={i}>
              <div style={{ fontSize: 28, fontWeight: 800, color: '#FBBF24', letterSpacing: -0.5 }}>{r.value}</div>
              <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 4, lineHeight: 1.4 }}>{r.metric}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

window.VpcSection = VpcSection;
window.StakeholderSection = StakeholderSection;
window.ConjointSection = ConjointSection;
window.MarketSection = MarketSection;
