/* =============================================================
   ScanFair — Phase 2.2: Score-Visualisierung
   3 Varianten der Score-Darstellung im Vergleich
   Gemeinsames Beispiel: GEPA Bio-Schokolade (E:6.2 / S:8.7 / G:7.5 → 7.4 GREEN)
   ============================================================= */

const { useState, useEffect, useMemo } = React;

// ─────────────────────────────────────────────────────────────
// Beispielprodukt (gleich für alle 3 Varianten)
// ─────────────────────────────────────────────────────────────
const PRODUCT = {
  brand: 'GEPA',
  name: 'Bio Edelbitter Schokolade',
  category: 'Schokolade · 100g',
  origin: 'Ghana',
  emoji: '🍫',
  scores: { e: 6.2, s: 8.7, g: 7.5, total: 7.4 },
  traffic: 'green', // green | yellow | red
  verdict: { green: 'Empfehlung', yellow: 'Mit Bedacht', red: 'Vermeiden' },
  highlights: {
    e: 'EU-Bio · Demeter · 5.8 kg CO₂eq',
    s: 'Fairtrade · GEPA fair+ · faire Löhne',
    g: 'Transparente Lieferkette dokumentiert',
  },
  topReason: 'Fairtrade & Demeter-zertifiziert',
};

const COLORS = {
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

// ─────────────────────────────────────────────────────────────
// Shared Helpers
// ─────────────────────────────────────────────────────────────
function trafficColor(t) {
  return t === 'green' ? COLORS.green500 : t === 'yellow' ? COLORS.yellow : COLORS.red;
}

function ProductHeader({ dark = false }) {
  const ink = dark ? '#fff' : COLORS.ink1;
  const sub = dark ? 'rgba(255,255,255,0.7)' : COLORS.ink3;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px 16px' }}>
      <div style={{
        width: 52, height: 52, borderRadius: 12,
        background: dark ? 'rgba(255,255,255,0.08)' : COLORS.bgAlt,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 28,
      }}>{PRODUCT.emoji}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: dark ? COLORS.green100 : COLORS.green500, marginBottom: 2 }}>
          {PRODUCT.brand}
        </div>
        <div style={{ fontSize: 16, fontWeight: 600, color: ink, lineHeight: 1.2, letterSpacing: '-0.01em' }}>
          {PRODUCT.name}
        </div>
        <div style={{ fontSize: 12, color: sub, marginTop: 2 }}>
          {PRODUCT.category} · {PRODUCT.origin}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// VARIANT 1 — KLASSISCHE AMPEL-KARTE
// "Sofort verständlich, vertraut wie YUKA / Nutri-Score"
// ─────────────────────────────────────────────────────────────
function ScoreV1_TrafficLight() {
  const tc = trafficColor(PRODUCT.traffic);
  const tlBg = PRODUCT.traffic === 'green' ? COLORS.green50
    : PRODUCT.traffic === 'yellow' ? COLORS.yellow50 : COLORS.red50;

  const Bar = ({ label, value, color, hint }) => (
    <div style={{ marginBottom: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 8, height: 8, borderRadius: 2, background: color }}/>
          <span style={{ fontSize: 13, fontWeight: 600, color: COLORS.ink1, letterSpacing: '0.04em', textTransform: 'uppercase' }}>{label}</span>
        </div>
        <span style={{ fontSize: 15, fontWeight: 700, color: COLORS.ink1, fontVariantNumeric: 'tabular-nums' }}>
          {value.toFixed(1)}<span style={{ color: COLORS.ink3, fontWeight: 400 }}>/10</span>
        </span>
      </div>
      <div style={{ height: 6, background: COLORS.bgAlt, borderRadius: 3, overflow: 'hidden' }}>
        <div style={{ width: `${value * 10}%`, height: '100%', background: color, borderRadius: 3, transition: 'width 0.6s var(--sf-ease)' }}/>
      </div>
      <div style={{ fontSize: 12, color: COLORS.ink3, marginTop: 5, lineHeight: 1.4 }}>{hint}</div>
    </div>
  );

  return (
    <div style={{ background: COLORS.bg, height: '100%', display: 'flex', flexDirection: 'column', fontFamily: "'Inter', sans-serif" }}>
      <ProductHeader/>

      {/* HERO Score Card — full bleed traffic-color band */}
      <div style={{ padding: '0 20px' }}>
        <div style={{
          background: COLORS.card,
          borderRadius: 20,
          overflow: 'hidden',
          boxShadow: '0 4px 16px rgba(26,38,34,0.08)',
        }}>
          {/* Color band */}
          <div style={{ height: 6, background: tc }}/>
          <div style={{ padding: '24px 24px 22px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: tc, marginBottom: 6 }}>
                  ESG-Score
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                  <span style={{
                    fontFamily: "'Instrument Serif', serif",
                    fontSize: 64, fontWeight: 400, color: COLORS.ink1,
                    lineHeight: 0.9, letterSpacing: '-0.02em',
                  }}>{PRODUCT.scores.total.toFixed(1)}</span>
                  <span style={{ fontSize: 18, color: COLORS.ink3, fontWeight: 400 }}>/ 10</span>
                </div>
              </div>
              {/* Traffic light dot */}
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 8,
                padding: '8px 14px',
                borderRadius: 999,
                background: tlBg,
                color: tc,
                fontSize: 13, fontWeight: 600,
                whiteSpace: 'nowrap',
              }}>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: tc, boxShadow: `0 0 0 3px ${tc}25` }}/>
                {PRODUCT.verdict[PRODUCT.traffic]}
              </div>
            </div>
            <div style={{ fontSize: 13, color: COLORS.ink2, marginTop: 14, lineHeight: 1.5 }}>
              {PRODUCT.topReason}. Solide ESG-Bewertung dank Bio &amp; Fair.
            </div>
          </div>
        </div>
      </div>

      {/* E/S/G Bars */}
      <div style={{ padding: '20px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: COLORS.ink3, marginBottom: 14 }}>
          Drei Säulen
        </div>
        <div style={{ background: COLORS.card, borderRadius: 16, padding: 20, border: `1px solid ${COLORS.borderSoft}` }}>
          <Bar label="Environmental" value={PRODUCT.scores.e} color={COLORS.e} hint={PRODUCT.highlights.e}/>
          <Bar label="Social" value={PRODUCT.scores.s} color={COLORS.s} hint={PRODUCT.highlights.s}/>
          <div style={{ marginBottom: 0 }}>
            <Bar label="Governance" value={PRODUCT.scores.g} color={COLORS.g} hint={PRODUCT.highlights.g}/>
          </div>
        </div>
      </div>

      {/* Pro/Con Quick */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{ background: COLORS.card, borderRadius: 16, padding: '14px 16px', border: `1px solid ${COLORS.borderSoft}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 13, color: COLORS.ink1 }}>
            <span style={{ fontWeight: 600 }}>4 Stärken</span>
            <span style={{ color: COLORS.ink3 }}> · 2 Schwächen</span>
          </div>
          <div style={{ fontSize: 13, color: COLORS.green500, fontWeight: 600 }}>Details →</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// VARIANT 2 — RADIAL DONUT (Fitness-Tracker Vibe)
// "Modern, datenfokussiert, mit Mini-Donuts für E/S/G"
// ─────────────────────────────────────────────────────────────
function Donut({ value, max = 10, size = 200, stroke = 16, color, trackColor = COLORS.bgAlt, children }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - value / max);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={trackColor} strokeWidth={stroke}/>
        <circle
          cx={size/2} cy={size/2} r={r}
          fill="none" stroke={color} strokeWidth={stroke}
          strokeDasharray={c}
          strokeDashoffset={offset}
          strokeLinecap="round"
          style={{ transition: 'stroke-dashoffset 0.9s cubic-bezier(0.4,0,0.2,1)' }}
        />
      </svg>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexDirection: 'column',
      }}>{children}</div>
    </div>
  );
}

function ScoreV2_RadialDonut() {
  const tc = trafficColor(PRODUCT.traffic);
  const grade = PRODUCT.scores.total >= 8 ? 'A' : PRODUCT.scores.total >= 6.5 ? 'B' : PRODUCT.scores.total >= 5 ? 'C' : PRODUCT.scores.total >= 3.5 ? 'D' : 'E';

  return (
    <div style={{
      background: COLORS.deep,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: '#fff',
    }}>
      <ProductHeader dark/>

      {/* Big Donut */}
      <div style={{ display: 'flex', justifyContent: 'center', padding: '8px 0 24px' }}>
        <Donut value={PRODUCT.scores.total} size={220} stroke={14} color={tc} trackColor="rgba(255,255,255,0.08)">
          <div style={{
            fontFamily: "'Instrument Serif', serif",
            fontSize: 72, fontWeight: 400,
            lineHeight: 0.9, letterSpacing: '-0.02em',
            color: '#fff',
          }}>{PRODUCT.scores.total.toFixed(1)}</div>
          <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', marginTop: 4, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600 }}>
            von 10
          </div>
        </Donut>
      </div>

      {/* Verdict pill */}
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 28 }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 10,
          padding: '10px 18px',
          borderRadius: 999,
          background: `${tc}26`,
          border: `1px solid ${tc}66`,
          color: '#fff',
          fontSize: 14, fontWeight: 600,
        }}>
          <span style={{
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            width: 22, height: 22, borderRadius: '50%',
            background: tc, color: '#fff',
            fontSize: 13, fontWeight: 700, letterSpacing: '-0.02em',
          }}>{grade}</span>
          {PRODUCT.verdict[PRODUCT.traffic]}
        </div>
      </div>

      {/* 3 Mini Donuts */}
      <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
        {[
          { label: 'Environmental', short: 'E', value: PRODUCT.scores.e, color: COLORS.e, hint: 'CO₂, Bio, Verpackung' },
          { label: 'Social', short: 'S', value: PRODUCT.scores.s, color: '#E8956E', hint: 'Faire Löhne, Lieferkette' },
          { label: 'Governance', short: 'G', value: PRODUCT.scores.g, color: '#8B85F2', hint: 'Transparenz, Audits' },
        ].map((p, i) => (
          <div key={i} style={{
            background: 'rgba(255,255,255,0.04)',
            borderRadius: 16,
            padding: '14px 8px 12px',
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            border: '1px solid rgba(255,255,255,0.06)',
          }}>
            <Donut value={p.value} size={68} stroke={6} color={p.color} trackColor="rgba(255,255,255,0.08)">
              <div style={{ fontSize: 18, fontWeight: 700, color: '#fff', fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>
                {p.value.toFixed(1)}
              </div>
            </Donut>
            <div style={{ fontSize: 11, fontWeight: 700, color: p.color, marginTop: 8, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
              {p.short} · {p.label.split(' ')[0].slice(0,4)}
            </div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.5)', marginTop: 4, textAlign: 'center', lineHeight: 1.3, padding: '0 4px' }}>
              {p.hint}
            </div>
          </div>
        ))}
      </div>

      {/* Reason card */}
      <div style={{ padding: '20px 16px 0' }}>
        <div style={{
          background: 'rgba(255,255,255,0.04)',
          border: `1px solid ${tc}55`,
          borderRadius: 16,
          padding: '14px 16px',
          display: 'flex', alignItems: 'flex-start', gap: 12,
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: `${tc}33`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={tc} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: tc, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 4 }}>
              Hauptgrund
            </div>
            <div style={{ fontSize: 14, color: '#fff', lineHeight: 1.4 }}>
              {PRODUCT.topReason} — überdurchschnittlich für diese Kategorie.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// VARIANT 3 — EDITORIAL / STORY
// "Magazin-haft, Display-Serif, Begründung im Vordergrund"
// ─────────────────────────────────────────────────────────────
function ScoreV3_Editorial() {
  const tc = trafficColor(PRODUCT.traffic);
  const total = PRODUCT.scores.total;

  return (
    <div style={{
      background: COLORS.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
    }}>
      <ProductHeader/>

      {/* Big editorial score */}
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: tc, marginBottom: 8 }}>
          Verdict · {PRODUCT.verdict[PRODUCT.traffic]}
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
          <div style={{
            fontFamily: "'Instrument Serif', serif",
            fontSize: 128, fontWeight: 400, color: COLORS.ink1,
            lineHeight: 0.85, letterSpacing: '-0.04em',
          }}>{total.toFixed(1)}</div>
          <div style={{ paddingTop: 16 }}>
            <div style={{ fontSize: 14, color: COLORS.ink3, fontWeight: 500 }}>von 10.0</div>
            <div style={{
              width: 32, height: 2, background: tc, marginTop: 10, marginBottom: 10,
            }}/>
            <div style={{
              fontFamily: "'Instrument Serif', serif",
              fontStyle: 'italic',
              fontSize: 22, color: COLORS.ink1, lineHeight: 1.15,
            }}>solide<br/>nachhaltig.</div>
          </div>
        </div>
      </div>

      {/* Stacked horizontal bar — composition */}
      <div style={{ padding: '0 20px 12px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: COLORS.ink3, marginBottom: 10 }}>
          Wie sich der Score zusammensetzt
        </div>
        <div style={{ display: 'flex', height: 36, borderRadius: 8, overflow: 'hidden', border: `1px solid ${COLORS.borderSoft}` }}>
          {[
            { label: 'E', value: PRODUCT.scores.e, color: COLORS.e },
            { label: 'S', value: PRODUCT.scores.s, color: COLORS.s },
            { label: 'G', value: PRODUCT.scores.g, color: COLORS.g },
          ].map((p, i) => {
            const sum = PRODUCT.scores.e + PRODUCT.scores.s + PRODUCT.scores.g;
            const pct = (p.value / sum) * 100;
            return (
              <div key={i} style={{
                width: `${pct}%`, background: p.color,
                color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                gap: 6,
                fontSize: 12, fontWeight: 600,
              }}>
                <span style={{ opacity: 0.85 }}>{p.label}</span>
                <span style={{ fontWeight: 700 }}>{p.value.toFixed(1)}</span>
              </div>
            );
          })}
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: COLORS.ink3, marginTop: 6, letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>
          <span>Environmental</span>
          <span>Social</span>
          <span>Governance</span>
        </div>
      </div>

      {/* Narrative reasons */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {[
            { label: 'Environmental', value: PRODUCT.scores.e, color: COLORS.e, text: 'EU-Bio & Demeter zertifiziert. Kakaoanbau ohne Pestizide. CO₂-Fußabdruck mit 5.8 kg/100g durchschnittlich für Kakao.' },
            { label: 'Social', value: PRODUCT.scores.s, color: COLORS.s, text: 'Fairtrade plus GEPA fair+ — über Mindeststandards hinaus. Garantiert faire Löhne und Bildungsprojekte vor Ort.' },
            { label: 'Governance', value: PRODUCT.scores.g, color: COLORS.g, text: 'Transparente Lieferkette dokumentiert. Hersteller veröffentlicht Nachhaltigkeitsbericht jährlich.' },
          ].map((p, i) => (
            <div key={i} style={{ display: 'flex', gap: 14 }}>
              <div style={{ flexShrink: 0, paddingTop: 2 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: '50%',
                  border: `2px solid ${p.color}`,
                  background: COLORS.card,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 14, fontWeight: 700, color: p.color,
                  fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em',
                }}>{p.value.toFixed(1)}</div>
              </div>
              <div style={{ flex: 1, minWidth: 0, paddingTop: 4 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: p.color, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 4 }}>
                  {p.label}
                </div>
                <div style={{ fontSize: 13, color: COLORS.ink2, lineHeight: 1.5 }}>{p.text}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA strip */}
      <div style={{ padding: '20px' }}>
        <div style={{
          fontSize: 13, color: COLORS.green500, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '12px 0 4px',
          borderTop: `1px solid ${COLORS.borderSoft}`,
        }}>
          <span>Methodik &amp; Quellen anzeigen</span>
          <span>→</span>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Frame Wrapper for canvas
// ─────────────────────────────────────────────────────────────
function PhoneFrame({ dark = false, title, children }) {
  return (
    <IOSDevice width={400} height={840} dark={dark}>
      <IOSStatusBar dark={dark}/>
      <div style={{
        background: dark ? COLORS.deep : COLORS.bg,
        height: 'calc(100% - 50px)',
        overflow: 'auto',
        WebkitOverflowScrolling: 'touch',
      }}>
        {/* Top bar — minimal, just back button */}
        <div style={{
          padding: '8px 16px 0',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          fontSize: 13, color: dark ? 'rgba(255,255,255,0.6)' : COLORS.ink3,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontWeight: 600, color: dark ? '#fff' : COLORS.ink1 }}>
            <span style={{ fontSize: 18 }}>‹</span>
            <span style={{ fontSize: 13 }}>Scannen</span>
          </div>
          <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>Variante {title}</span>
          <span style={{ fontSize: 18 }}>⋯</span>
        </div>
        {children}
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Notes column for each variant
// ─────────────────────────────────────────────────────────────
function VariantNotes({ title, tagline, pros, cons, recommendation }) {
  return (
    <div style={{
      width: 360, padding: 28,
      background: '#fff',
      borderRadius: 16,
      border: `1px solid ${COLORS.borderSoft}`,
      fontFamily: "'Inter', sans-serif",
      color: COLORS.ink1,
    }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: COLORS.green500, marginBottom: 8 }}>
        {title}
      </div>
      <div style={{
        fontFamily: "'Instrument Serif', serif",
        fontSize: 28, lineHeight: 1.15, letterSpacing: '-0.02em',
        color: COLORS.ink1, marginBottom: 16,
      }}>{tagline}</div>
      <div style={{ height: 1, background: COLORS.borderSoft, margin: '0 0 16px' }}/>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: COLORS.green500, marginBottom: 8 }}>Stärken</div>
      <ul style={{ margin: 0, padding: 0, listStyle: 'none', marginBottom: 16 }}>
        {pros.map((p, i) => (
          <li key={i} style={{ fontSize: 13, color: COLORS.ink2, lineHeight: 1.5, marginBottom: 6, paddingLeft: 16, position: 'relative' }}>
            <span style={{ position: 'absolute', left: 0, top: 6, width: 8, height: 1.5, background: COLORS.green500 }}/>
            {p}
          </li>
        ))}
      </ul>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: COLORS.yellow, marginBottom: 8 }}>Risiken</div>
      <ul style={{ margin: 0, padding: 0, listStyle: 'none', marginBottom: 16 }}>
        {cons.map((p, i) => (
          <li key={i} style={{ fontSize: 13, color: COLORS.ink2, lineHeight: 1.5, marginBottom: 6, paddingLeft: 16, position: 'relative' }}>
            <span style={{ position: 'absolute', left: 0, top: 6, width: 8, height: 1.5, background: COLORS.yellow }}/>
            {p}
          </li>
        ))}
      </ul>
      <div style={{
        background: COLORS.bgAlt,
        padding: '12px 14px',
        borderRadius: 10,
        fontSize: 12, color: COLORS.ink2, lineHeight: 1.5,
        borderLeft: `3px solid ${COLORS.green500}`,
      }}>
        <span style={{ fontWeight: 700, color: COLORS.ink1 }}>Empfehlung: </span>
        {recommendation}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Overview / Intro Artboard
// ─────────────────────────────────────────────────────────────
function OverviewBoard() {
  return (
    <div style={{
      background: '#fff', height: '100%',
      padding: '40px 48px',
      fontFamily: "'Inter', sans-serif",
      color: COLORS.ink1,
      boxSizing: 'border-box',
    }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: COLORS.green500, marginBottom: 12 }}>
        Phase 2.2 · Score-Visualisierung
      </div>
      <div style={{
        fontFamily: "'Instrument Serif', serif",
        fontSize: 56, lineHeight: 1.15, letterSpacing: '-0.025em',
        color: COLORS.ink1, marginBottom: 16, maxWidth: 720,
      }}>
        Drei Wege, einen <em style={{ color: COLORS.green500 }}>ESG-Score</em> zu zeigen.
      </div>
      <div style={{ fontSize: 16, color: COLORS.ink2, lineHeight: 1.55, maxWidth: 680, marginBottom: 28 }}>
        Der Score-Bildschirm ist der wichtigste Moment der App — hier passiert die Aha-Erfahrung
        oder der Abbruch. Ich zeige drei Varianten, alle mit dem <strong>gleichen Beispielprodukt</strong>
        (GEPA Bio Edelbitter — 7.4/10 grün), damit du Äpfel mit Äpfeln vergleichen kannst.
      </div>
      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr 1fr',
        gap: 16,
        marginBottom: 28,
      }}>
        {[
          { n: '01', t: 'Ampel-Karte', d: 'Vertraut, sofort lesbar. YUKA-/Nutri-Score-Vibe. Konservativ.', c: COLORS.green500 },
          { n: '02', t: 'Radial Donut', d: 'Modern, dunkel, Fitness-Tracker-Feel. Zahl + Schulnote.', c: COLORS.s },
          { n: '03', t: 'Editorial', d: 'Magazin-haft. Display-Serif. Begründung im Vordergrund.', c: COLORS.g },
        ].map((v, i) => (
          <div key={i} style={{
            padding: '20px',
            border: `1px solid ${COLORS.borderSoft}`,
            borderRadius: 14,
            background: COLORS.bg,
          }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', color: v.c, marginBottom: 6 }}>
              {v.n}
            </div>
            <div style={{ fontSize: 18, fontWeight: 700, color: COLORS.ink1, marginBottom: 6 }}>{v.t}</div>
            <div style={{ fontSize: 13, color: COLORS.ink2, lineHeight: 1.5 }}>{v.d}</div>
          </div>
        ))}
      </div>
      <div style={{
        padding: '16px 20px',
        background: COLORS.green50,
        borderRadius: 12,
        fontSize: 13, color: COLORS.green600, lineHeight: 1.55,
        borderLeft: `3px solid ${COLORS.green500}`,
        maxWidth: 760,
      }}>
        <strong>So benutzt du das hier:</strong> Drag-Reorder die Artboards, um deinen Favoriten zuerst zu legen.
        Klick auf eine Artboard für Vollbild. Sag mir am Ende, welche Variante (oder welche Mischung)
        in Phase 2.3 für die echten Hauptscreens benutzt werden soll.
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Main App — Design Canvas
// ─────────────────────────────────────────────────────────────
function App() {
  return (
    <DesignCanvas
      title="ScanFair · Phase 2.2 — Score-Visualisierung"
      subtitle="Drei Varianten · gemeinsames Beispielprodukt · iPhone-Mockups"
      defaultTool="hand"
    >
      <DCSection id="overview" title="Überblick — was du hier siehst">
        <DCArtboard id="ov" label="Phase 2.2 — Drei Varianten der Score-Visualisierung" width={880} height={620}>
          <OverviewBoard/>
        </DCArtboard>
      </DCSection>

      <DCSection id="v1" title="Variante 1 — Ampel-Karte (vertraut, konservativ)">
        <DCArtboard id="v1-phone" label="V1 · iPhone-Mockup" width={420} height={880}>
          <div style={{ background: COLORS.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <PhoneFrame title="1" >
              <ScoreV1_TrafficLight/>
            </PhoneFrame>
          </div>
        </DCArtboard>
        <DCArtboard id="v1-notes" label="V1 · Designnotizen & Bewertung" width={400} height={880}>
          <div style={{ background: COLORS.bgAlt, height: '100%', padding: 20, boxSizing: 'border-box', display: 'flex', alignItems: 'center' }}>
            <VariantNotes
              title="V1 · Ampel-Karte"
              tagline="Vertraut wie Nutri-Score, aber präziser durch die 0–10-Zahl."
              pros={[
                'Sofort verständlich — Ampelfarbe entspricht Hausarbeit-Konzept',
                'Niedrige kognitive Last für Erstnutzer (60+, Quick-Shopper)',
                '3-Säulen-Balken sind druckfähig (kann auf Verpackung gedruckt werden)',
                'Robuste Lesbarkeit auch bei niedrigem Kontrast / im Geschäft',
              ]}
              cons={[
                'Wirkt etwas \u201Emedizinisch\u201C, weniger emotional/inspirierend',
                'Differenzierung zu YUKA / Open Food Facts schwierig',
                'Wenig Raum für Storytelling über das Produkt',
              ]}
              recommendation={'Beste Wahl für die MVP-Hauptscreens. Maximale Verständlichkeit, geringstes Risiko bei der Zielgruppe der ESG-skeptischen Quick-Shopper. Setze hier in Phase 2.3 auf, wenn du verlässlich bauen willst.'}
            />
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="v2" title="Variante 2 — Radial Donut (modern, dark)">
        <DCArtboard id="v2-phone" label="V2 · iPhone-Mockup (Dark)" width={420} height={880}>
          <div style={{ background: COLORS.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <PhoneFrame dark title="2">
              <ScoreV2_RadialDonut/>
            </PhoneFrame>
          </div>
        </DCArtboard>
        <DCArtboard id="v2-notes" label="V2 · Designnotizen & Bewertung" width={400} height={880}>
          <div style={{ background: COLORS.bgAlt, height: '100%', padding: 20, boxSizing: 'border-box', display: 'flex', alignItems: 'center' }}>
            <VariantNotes
              title="V2 · Radial Donut"
              tagline="Apple-Watch-Vibe trifft Schulnoten-System. Premium-Feel."
              pros={[
                'Sehr distinctive Optik — App fühlt sich modern an, nicht behördlich',
                'Donuts sind kraftvolle Visualisierung — Fortschritt zur Vollkommenheit',
                'Schulnote (A–E) bedient deutsche Mental Models',
                'Dark Theme passt zum \u201EPremium-Choice\u201C-Gefühl',
              ]}
              cons={[
                'Höhere kognitive Last — Donut + Note + Zahl + Pillar-Donuts',
                'Schulnoten könnten Eco-Score (auch A–E) doppeln und verwirren',
                'Dark-only Screen mitten im Light-Flow ist abrupt',
                'Die 3 Mini-Donuts zeigen wenig Raum für Erklärung',
              ]}
              recommendation={'Riskante, aber differenzierende Wahl. Empfohlen, wenn ScanFair sich als \u201EPremium ESG-App für junge LOHAS\u201C positioniert. Vor Phase 2.3 mit 2 Nutzern testen \u2014 verstehen sie A\u2013E neben 7.4/10?'}
            />
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="v3" title="Variante 3 — Editorial / Story (Begründung im Fokus)">
        <DCArtboard id="v3-phone" label="V3 · iPhone-Mockup" width={420} height={880}>
          <div style={{ background: COLORS.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <PhoneFrame title="3">
              <ScoreV3_Editorial/>
            </PhoneFrame>
          </div>
        </DCArtboard>
        <DCArtboard id="v3-notes" label="V3 · Designnotizen & Bewertung" width={400} height={880}>
          <div style={{ background: COLORS.bgAlt, height: '100%', padding: 20, boxSizing: 'border-box', display: 'flex', alignItems: 'center' }}>
            <VariantNotes
              title="V3 · Editorial"
              tagline="Magazin-Layout. Display-Serif. Die Story zählt mehr als der Score."
              pros={[
                'Adressiert direkt das Hausarbeit-Insight: Nutzer wollen WISSEN, warum',
                'Stacked Bar zeigt Komposition — nicht nur Werte, sondern Verteilung',
                'Begründungstexte direkt am Screen — keine Tap-Through-Hürde',
                'Differenziert ScanFair von \u201EScore-Apps\u201C \u2014 wir sind eine Recherche-App',
              ]}
              cons={[
                'Lesezeit höher — schlecht für Quick-Shopper im Supermarkt',
                'Mehr Text = höherer Übersetzungs-/Lokalisierungsaufwand',
                'Italic-Serif kann auf älteren Android-Geräten schlecht rendern',
              ]}
              recommendation={'Beste Wahl, wenn die Zielgruppe \u201Einformierte LOHAS\u201C ist (Persona \u201ESara\u201C aus Phase 1). Schwächer für Quick-Buyers. Möglich als \u201EDetail-Variante\u201C in Tab-Switch \u2014 kurze Übersicht (V1) plus tieferes Verständnis (V3).'}
            />
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="next" title="Nächster Schritt">
        <DCArtboard id="next-board" label="Was kommt nach Phase 2.2" width={880} height={420}>
          <div style={{
            background: COLORS.bg, height: '100%',
            padding: '40px 48px',
            fontFamily: "'Inter', sans-serif",
            color: COLORS.ink1,
            boxSizing: 'border-box',
          }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: COLORS.green500, marginBottom: 12 }}>
              Deine Entscheidung
            </div>
            <div style={{
              fontFamily: "'Instrument Serif', serif",
              fontSize: 36, lineHeight: 1.1, letterSpacing: '-0.02em',
              color: COLORS.ink1, marginBottom: 20, maxWidth: 700,
            }}>
              Welche Variante (oder welche Mischung) wird die Grundlage für Phase 2.3?
            </div>
            <div style={{ fontSize: 14, color: COLORS.ink2, lineHeight: 1.55, maxWidth: 700, marginBottom: 20 }}>
              In <strong>Phase 2.3</strong> baue ich die Hauptscreens S1–S5 (Home, Scanner, Score, Details, Not-Found)
              im finalen Hi-Fi-Stil. Die Score-Visualisierung wird auf jedem dieser Screens auftauchen — also lohnt es sich, jetzt zu entscheiden.
            </div>
            <div style={{
              padding: '14px 18px',
              background: COLORS.green50,
              borderRadius: 12,
              fontSize: 13, color: COLORS.green600, lineHeight: 1.55,
              borderLeft: `3px solid ${COLORS.green500}`,
              maxWidth: 700,
            }}>
              <strong>Mein Vorschlag:</strong> V1 als Standard für Hauptscreens (max. Verständlichkeit) + V3 als Tab-Switch
              auf dem Score-Screen für Nutzer, die mehr wissen wollen. V2 als Konzept aufheben für ein späteres
              \u201EPro/Premium\u201C-Theme. Sag mir, ob das passt \u2014 oder welchen Weg du gehen willst.
            </div>
          </div>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
