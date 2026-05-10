/* =============================================================
   ScanFair — Phase 2.3: Score-Komponenten (Hi-Fi)
   Reusable Hi-Fi-Komponenten für Score-Ergebnis & Details
   - ProductCard, ScoreHero, ScoreBars, HealthBar (3 Varianten),
     SourceFootnote, NavTab
   ============================================================= */

const SF_C = {
  bg: '#FBFAF6',
  bgAlt: '#F4F2EB',
  card: '#FFFFFF',
  ink1: '#1A2622',
  ink2: '#4A5650',
  ink3: '#7A857F',
  border: '#E5E2D8',
  borderSoft: '#EFEDE5',
  green500: '#0F7B5C',
  green600: '#0A6248',
  green50: '#E8F2EE',
  green100: '#C5DFD3',
  yellow: '#D97706',
  yellow50: '#FEF3C7',
  red: '#C2410C',
  red50: '#FEE2E2',
  e: '#0F7B5C',
  s: '#C97B5C',
  g: '#4F46E5',
  deep: '#0E1B17',
};

function sfTrafficColor(t) {
  return t === 'green' ? SF_C.green500 : t === 'yellow' ? SF_C.yellow : SF_C.red;
}
function sfTrafficBg(t) {
  return t === 'green' ? SF_C.green50 : t === 'yellow' ? SF_C.yellow50 : SF_C.red50;
}

// ─────────────────────────────────────────────────────────────
// ProductCard — used at top of Score & Details screens
// ─────────────────────────────────────────────────────────────
function ProductCard({ product, dark = false, compact = false }) {
  const ink = dark ? '#fff' : SF_C.ink1;
  const sub = dark ? 'rgba(255,255,255,0.6)' : SF_C.ink3;
  const acc = dark ? SF_C.green100 : SF_C.green500;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: compact ? '10px 20px 12px' : '14px 20px 18px' }}>
      <div style={{
        width: compact ? 44 : 52, height: compact ? 44 : 52,
        borderRadius: 12,
        background: dark ? 'rgba(255,255,255,0.08)' : SF_C.bgAlt,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: compact ? 24 : 28,
      }}>{product.image_emoji}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: acc, marginBottom: 2 }}>
          {product.brand}
        </div>
        <div style={{ fontSize: compact ? 15 : 16, fontWeight: 600, color: ink, lineHeight: 1.2, letterSpacing: '-0.01em' }}>
          {product.product_name}
        </div>
        <div style={{ fontSize: 12, color: sub, marginTop: 2 }}>
          {product.category} · {product.origin}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ScoreHero — V1-style: big number + verdict pill (color band)
// ─────────────────────────────────────────────────────────────
function ScoreHero({ esg }) {
  const tc = sfTrafficColor(esg.verdict);
  const tlBg = sfTrafficBg(esg.verdict);
  return (
    <div style={{ padding: '0 20px' }}>
      <div style={{
        background: SF_C.card,
        borderRadius: 20,
        overflow: 'hidden',
        boxShadow: '0 4px 16px rgba(26,38,34,0.08)',
      }}>
        <div style={{ height: 6, background: tc }}/>
        <div style={{ padding: '22px 22px 20px' }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10 }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: tc, marginBottom: 6 }}>
                ESG-Score
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                <span style={{
                  fontFamily: "'Instrument Serif', serif",
                  fontSize: 60, fontWeight: 400, color: SF_C.ink1,
                  lineHeight: 0.9, letterSpacing: '-0.02em',
                }}>{esg.total.toFixed(1)}</span>
                <span style={{ fontSize: 17, color: SF_C.ink3, fontWeight: 400 }}>/ 10</span>
              </div>
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 8,
              padding: '8px 12px',
              borderRadius: 999,
              background: tlBg,
              color: tc,
              fontSize: 12, fontWeight: 600,
              whiteSpace: 'nowrap',
              flexShrink: 0,
            }}>
              <div style={{ width: 7, height: 7, borderRadius: '50%', background: tc, boxShadow: `0 0 0 3px ${tc}25` }}/>
              {esg.verdict_label}
            </div>
          </div>
          <div style={{ fontSize: 13, color: SF_C.ink2, marginTop: 12, lineHeight: 1.5 }}>
            {esg.tagline}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ScoreBars — 3 ESG pillar bars with optional expand
// ─────────────────────────────────────────────────────────────
const PILLAR_META = {
  e: { label: 'Umwelt',           short: 'E', color: SF_C.e, hint: 'CO₂, Bio, Verpackung, Transport' },
  s: { label: 'Mensch & Soziales', short: 'S', color: SF_C.s, hint: 'Faire Löhne, Lieferkette, Arbeitsbedingungen' },
  g: { label: 'Transparenz',       short: 'G', color: SF_C.g, hint: 'Datenqualität, Audits, Herkunftsnachweise' },
};

function PillarRow({ pillarKey, value, expandable = false, expanded = false, onToggle, details }) {
  const m = PILLAR_META[pillarKey];
  return (
    <div style={{
      borderBottom: `1px solid ${SF_C.borderSoft}`,
      paddingBottom: 14, marginBottom: 14,
    }}>
      <div
        onClick={expandable ? onToggle : undefined}
        style={{
          display: 'flex', alignItems: 'center', gap: 12,
          cursor: expandable ? 'pointer' : 'default',
          userSelect: 'none',
        }}
      >
        <div style={{ width: 6, height: 28, background: m.color, borderRadius: 3, flexShrink: 0 }}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 5 }}>
            <span style={{ fontSize: 14, fontWeight: 600, color: SF_C.ink1, letterSpacing: '-0.005em' }}>{m.label}</span>
            <span style={{ fontSize: 15, fontWeight: 700, color: SF_C.ink1, fontVariantNumeric: 'tabular-nums' }}>
              {value.toFixed(1)}<span style={{ color: SF_C.ink3, fontWeight: 400 }}>/10</span>
            </span>
          </div>
          <div style={{ height: 5, background: SF_C.bgAlt, borderRadius: 3, overflow: 'hidden' }}>
            <div style={{ width: `${value * 10}%`, height: '100%', background: m.color, borderRadius: 3, transition: 'width 0.6s cubic-bezier(0.4,0,0.2,1)' }}/>
          </div>
          <div style={{ fontSize: 11, color: SF_C.ink3, marginTop: 5, lineHeight: 1.4 }}>{m.hint}</div>
        </div>
        {expandable && (
          <div style={{
            width: 24, height: 24, borderRadius: 999,
            background: SF_C.bgAlt,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
            fontSize: 11, color: SF_C.ink2,
            transition: 'transform 0.2s',
            transform: expanded ? 'rotate(180deg)' : 'rotate(0deg)',
          }}>▾</div>
        )}
      </div>
      {expandable && expanded && details && (
        <div style={{
          marginTop: 12, marginLeft: 18,
          padding: '12px 14px',
          background: SF_C.bgAlt,
          borderRadius: 10,
          fontSize: 12.5, color: SF_C.ink2, lineHeight: 1.55,
        }}>
          {details.map((d, i) => (
            <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', marginBottom: i === details.length - 1 ? 0 : 8 }}>
              <span style={{ flexShrink: 0, color: m.color, fontWeight: 700 }}>·</span>
              <div>
                <span style={{ color: SF_C.ink1, fontWeight: 600 }}>{d.label}</span>
                <span style={{ color: SF_C.ink3 }}>: {d.value}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function ScoreBars({ esg, expandable = false, defaultExpanded = null, productDetails = null }) {
  const [openKey, setOpenKey] = React.useState(defaultExpanded);
  const toggle = (k) => setOpenKey(prev => prev === k ? null : k);

  return (
    <div style={{ padding: '20px' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3, marginBottom: 12 }}>
        Drei Säulen
      </div>
      <div style={{ background: SF_C.card, borderRadius: 16, padding: '16px 18px 2px', border: `1px solid ${SF_C.borderSoft}` }}>
        <PillarRow pillarKey="e" value={esg.e} expandable={expandable} expanded={openKey==='e'} onToggle={()=>toggle('e')} details={productDetails && productDetails.e}/>
        <PillarRow pillarKey="s" value={esg.s} expandable={expandable} expanded={openKey==='s'} onToggle={()=>toggle('s')} details={productDetails && productDetails.s}/>
        <div style={{ borderBottom: 'none', marginBottom: 0, paddingBottom: 0 }}>
          <PillarRow pillarKey="g" value={esg.g} expandable={expandable} expanded={openKey==='g'} onToggle={()=>toggle('g')} details={productDetails && productDetails.g}/>
        </div>
      </div>
      {!expandable && (
        <div style={{ marginTop: 10, textAlign: 'right' }}>
          <span style={{ fontSize: 13, color: SF_C.green500, fontWeight: 600 }}>Details &amp; Quellen →</span>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SecondaryBar — universeller Begleitbalken (für Food / Clothing / Cosmetics)
// Verwendet info = product.secondaryInfo (title / position / barLeft / barRight / label / facts)
// Variants: linear (default) | discrete | minimal
// ─────────────────────────────────────────────────────────────
function SecondaryBar({ info, variant = 'linear' }) {
  // Alias-Mapping: alte HealthBar-Aufrufer übergeben { health }
  const data = info;
  const title = data.title || 'Gesundheit';
  const barLeft = data.barLeft || 'ungünstig';
  const barRight = data.barRight || 'nährstoffreich';
  const Header = (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3 }}>
        {title}
      </div>
      <div style={{ fontSize: 11, color: SF_C.ink3, fontStyle: 'italic' }}>
        kein Score · zur Information
      </div>
    </div>
  );

  if (variant === 'minimal') {
    return (
      <div style={{ padding: '4px 20px 0' }}>
        <div style={{ background: SF_C.card, borderRadius: 16, padding: '14px 16px 16px', border: `1px solid ${SF_C.borderSoft}` }}>
          {Header}
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            padding: '6px 12px',
            borderRadius: 999,
            background: SF_C.bgAlt,
            fontSize: 13, fontWeight: 600, color: SF_C.ink1,
            marginBottom: 10,
          }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: healthDotColor(data.position) }}/>
            {data.label}
          </div>
          <div style={{ fontSize: 12, color: SF_C.ink2, lineHeight: 1.5 }}>
            {data.facts}
          </div>
        </div>
      </div>
    );
  }

  if (variant === 'discrete') {
    const buckets = [
      { range: [0, 2.5],  label: 'kritisch' },
      { range: [2.5, 5],  label: 'gehaltvoll' },
      { range: [5, 7.5],  label: 'ausgewogen' },
      { range: [7.5, 10.01], label: 'gut' },
    ];
    const activeIdx = buckets.findIndex(b => data.position >= b.range[0] && data.position < b.range[1]);
    const colors = ['#C26A4A', '#D9A35A', '#94B864', '#3D9B76'];
    return (
      <div style={{ padding: '4px 20px 0' }}>
        <div style={{ background: SF_C.card, borderRadius: 16, padding: '14px 16px 16px', border: `1px solid ${SF_C.borderSoft}` }}>
          {Header}
          <div style={{ display: 'flex', gap: 4, marginBottom: 10 }}>
            {buckets.map((b, i) => (
              <div key={i} style={{
                flex: 1,
                padding: '7px 4px',
                borderRadius: 6,
                background: i === activeIdx ? colors[i] : SF_C.bgAlt,
                color: i === activeIdx ? '#fff' : SF_C.ink3,
                fontSize: 11, fontWeight: 600,
                textAlign: 'center',
                letterSpacing: '0.02em',
                transition: 'all 0.3s',
              }}>{b.label}</div>
            ))}
          </div>
          <div style={{ fontSize: 12, color: SF_C.ink2, lineHeight: 1.5 }}>
            {data.facts}
          </div>
        </div>
      </div>
    );
  }

  // Variant A — linear (default)
  const pct = (data.position / 10) * 100;
  return (
    <div style={{ padding: '4px 20px 0' }}>
      <div style={{ background: SF_C.card, borderRadius: 16, padding: '14px 16px 16px', border: `1px solid ${SF_C.borderSoft}` }}>
        {Header}
        <div style={{ position: 'relative', height: 10, marginBottom: 8 }}>
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(90deg, #C26A4A 0%, #D9A35A 33%, #94B864 66%, #3D9B76 100%)',
            borderRadius: 5,
          }}/>
          {/* marker */}
          <div style={{
            position: 'absolute',
            left: `${pct}%`,
            top: '50%',
            transform: 'translate(-50%, -50%)',
            width: 18, height: 18, borderRadius: '50%',
            background: '#fff',
            border: `3px solid ${SF_C.ink1}`,
            boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
          }}/>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: SF_C.ink3, marginBottom: 10, letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>
          <span>{barLeft}</span>
          <span>{barRight}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 6 }}>
          <span style={{ fontSize: 14, fontWeight: 600, color: SF_C.ink1 }}>{data.label}</span>
        </div>
        <div style={{ fontSize: 12, color: SF_C.ink2, lineHeight: 1.5 }}>
          {data.facts}
        </div>
      </div>
    </div>
  );
}

function healthDotColor(pos) {
  // links (niedrig) = ungünstig (rot), rechts (hoch) = nährstoffreich (grün)
  if (pos < 2.5) return '#C26A4A';
  if (pos < 5)   return '#D9A35A';
  if (pos < 7.5) return '#94B864';
  return '#3D9B76';
}

// ─────────────────────────────────────────────────────────────
// Methodik-Footnote
// ─────────────────────────────────────────────────────────────
function MethodFootnote({ product }) {
  return (
    <div style={{ padding: '14px 20px 22px' }}>
      <div style={{
        background: SF_C.bgAlt,
        borderRadius: 12,
        padding: '12px 14px',
        fontSize: 11, color: SF_C.ink3, lineHeight: 1.55,
      }}>
        <strong style={{ color: SF_C.ink2, fontWeight: 600 }}>Datenquelle:</strong>{' '}
        Open Food Facts · ScanFair-Methodik v1.0 · Datenqualität:{' '}
        <span style={{ color: SF_C.green600, fontWeight: 600 }}>
          {Math.round(product.data_completeness * 100)}%
        </span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// CTA Footer (3 actions)
// ─────────────────────────────────────────────────────────────
function ScoreCTAs() {
  const Btn = ({ icon, label, primary = false }) => (
    <button style={{
      flex: 1,
      padding: '12px 8px',
      background: primary ? SF_C.green500 : SF_C.card,
      color: primary ? '#fff' : SF_C.ink1,
      border: primary ? 'none' : `1px solid ${SF_C.borderSoft}`,
      borderRadius: 12,
      fontSize: 13, fontWeight: 600,
      cursor: 'pointer',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
      fontFamily: 'inherit',
    }}>
      <div style={{ fontSize: 16 }}>{icon}</div>
      {label}
    </button>
  );
  return (
    <div style={{ padding: '8px 20px 20px', display: 'flex', gap: 8 }}>
      <Btn icon="✓" label="Merken" primary/>
      <Btn icon="↗" label="Alternativen"/>
      <Btn icon="⌫" label="Erneut"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Top Nav (back + share)
// ─────────────────────────────────────────────────────────────
function ScreenNav({ onBack, dark = false, title }) {
  const ink = dark ? '#fff' : SF_C.ink1;
  const sub = dark ? 'rgba(255,255,255,0.6)' : SF_C.ink3;
  return (
    <div style={{
      padding: '8px 16px 4px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      fontSize: 13,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontWeight: 600, color: ink }}>
        <span style={{ fontSize: 22, lineHeight: 1, marginTop: -2 }}>‹</span>
        <span style={{ fontSize: 13 }}>Zurück</span>
      </div>
      {title && (
        <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: sub }}>{title}</span>
      )}
      <div style={{ display: 'flex', gap: 14, color: ink, fontSize: 16 }}>
        <span>↗</span>
        <span style={{ marginTop: -2 }}>⋯</span>
      </div>
    </div>
  );
}

// Export all to global
// Backwards-compat: HealthBar nimmt {health} und delegiert an SecondaryBar
function HealthBar({ health, variant = 'linear' }) {
  return <SecondaryBar info={health} variant={variant}/>;
}

// SecondaryChecklist — diskrete ✓/✗-Items mit Quellenangabe (S4 Details)
function SecondaryChecklist({ title = 'Im Detail', items }) {
  if (!items || !items.length) return null;
  return (
    <div style={{ padding: '4px 20px 0' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3, marginBottom: 12 }}>
        {title}
      </div>
      <div style={{ background: SF_C.card, borderRadius: 16, padding: '6px 16px', border: `1px solid ${SF_C.borderSoft}` }}>
        {items.map((it, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'flex-start', gap: 12,
            padding: '12px 0',
            borderBottom: i < items.length - 1 ? `1px solid ${SF_C.borderSoft}` : 'none',
          }}>
            <div style={{
              width: 22, height: 22, borderRadius: 999,
              background: it.ok ? SF_C.green50 : '#FEE2E2',
              color: it.ok ? SF_C.green600 : '#C2410C',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
              fontSize: 13, fontWeight: 700,
              marginTop: 1,
            }}>{it.ok ? '✓' : '✕'}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: SF_C.ink1, lineHeight: 1.3 }}>{it.label}</div>
              {it.note && <div style={{ fontSize: 11.5, color: SF_C.ink3, marginTop: 2, lineHeight: 1.4 }}>{it.note}</div>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  SF_C, sfTrafficColor, sfTrafficBg,
  ProductCard, ScoreHero, ScoreBars, PillarRow,
  SecondaryBar, SecondaryChecklist, HealthBar,
  MethodFootnote, ScoreCTAs, ScreenNav,
});
