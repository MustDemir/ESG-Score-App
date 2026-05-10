/* =============================================================
   ScanFair — Phase 2.5: Onboarding & Edge-States
   - O1 Welcome (Brand-Statement)
   - O2 Wie es funktioniert (Scan → Bewertung → Wahl)
   - O3 Datenquellen & Vertrauen + Loslegen
   - E1 Offline (gecachte Scans verfügbar)
   - E2 Low-Data (Datenqualität niedrig)
   - E3 Tablet (Result-Screen 2-Spalten Layout)
   ============================================================= */

// ─────────────────────────────────────────────────────────────
// Shared: Onboarding Stepper (3 dots top-right)
// ─────────────────────────────────────────────────────────────
function OnbStepper({ step, total = 3 }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          height: 4, borderRadius: 2,
          width: i === step ? 22 : 10,
          background: i === step ? SF_C.green500 : SF_C.borderSoft,
          transition: 'all 0.3s',
        }}/>
      ))}
    </div>
  );
}

function OnbHeader({ step }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '14px 22px 0',
    }}>
      <div style={{
        fontFamily: "'Instrument Serif', serif",
        fontSize: 20, color: SF_C.ink1, letterSpacing: '-0.01em',
      }}>
        Scan<em style={{ color: SF_C.green500 }}>Fair</em>
      </div>
      <OnbStepper step={step}/>
    </div>
  );
}

function OnbFooter({ primaryLabel = 'Weiter', skipLabel = 'Überspringen' }) {
  return (
    <div style={{ padding: '20px 22px 24px', marginTop: 'auto' }}>
      <button style={{
        width: '100%',
        padding: '15px 18px',
        background: SF_C.green500, color: '#fff',
        border: 'none', borderRadius: 16,
        fontSize: 15, fontWeight: 600, fontFamily: 'inherit',
        cursor: 'pointer',
        boxShadow: '0 8px 22px rgba(15,123,92,0.22)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      }}>
        {primaryLabel}
        <span style={{ fontSize: 16 }}>→</span>
      </button>
      {skipLabel && (
        <div style={{ textAlign: 'center', marginTop: 10 }}>
          <span style={{ fontSize: 12, fontWeight: 600, color: SF_C.ink3 }}>{skipLabel}</span>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// O1 — Welcome (Brand-Statement)
// ─────────────────────────────────────────────────────────────
function O1_Welcome() {
  return (
    <div style={{
      background: SF_C.bg, height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      position: 'relative', overflow: 'hidden',
    }}>
      {/* warm halo */}
      <div style={{
        position: 'absolute', top: -120, left: '50%', transform: 'translateX(-50%)',
        width: 520, height: 520, borderRadius: '50%',
        background: `radial-gradient(circle, ${SF_C.green50} 0%, rgba(232,242,238,0) 60%)`,
        pointerEvents: 'none',
      }}/>

      <div style={{ position: 'relative', zIndex: 1 }}>
        <OnbHeader step={0}/>
      </div>

      <div style={{ position: 'relative', zIndex: 1, padding: '60px 28px 0', textAlign: 'center' }}>
        {/* Glyph: scan + leaf */}
        <div style={{
          width: 96, height: 96, borderRadius: 28,
          background: SF_C.green500,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 28px',
          boxShadow: '0 14px 36px rgba(15,123,92,0.28)',
          position: 'relative',
        }}>
          <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 7V5a2 2 0 012-2h2"/>
            <path d="M17 3h2a2 2 0 012 2v2"/>
            <path d="M21 17v2a2 2 0 01-2 2h-2"/>
            <path d="M7 21H5a2 2 0 01-2-2v-2"/>
            <line x1="7" y1="12" x2="17" y2="12"/>
          </svg>
          <div style={{
            position: 'absolute', right: -8, bottom: -8,
            width: 36, height: 36, borderRadius: '50%',
            background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: `2px solid ${SF_C.green500}`,
            fontSize: 16,
          }}>🌿</div>
        </div>

        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 12 }}>
          Willkommen bei ScanFair
        </div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 40, lineHeight: 1.05, letterSpacing: '-0.025em',
          color: SF_C.ink1, marginBottom: 16,
        }}>
          Bewusster einkaufen,<br/>
          <em style={{ color: SF_C.green500 }}>ohne Greenwashing.</em>
        </div>
        <div style={{ fontSize: 14.5, color: SF_C.ink2, lineHeight: 1.55, maxWidth: 300, margin: '0 auto' }}>
          Wir prüfen Lebensmittel, Kleidung und Kosmetik nach <strong style={{ color: SF_C.ink1 }}>Umwelt</strong>, <strong style={{ color: SF_C.ink1 }}>Sozialem</strong> und <strong style={{ color: SF_C.ink1 }}>Transparenz</strong> — auf Basis offener Daten.
        </div>
      </div>

      <OnbFooter primaryLabel="Loslegen"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// O2 — Wie es funktioniert (3 Schritte)
// ─────────────────────────────────────────────────────────────
function O2_How() {
  const steps = [
    { n: '01', t: 'Barcode scannen', d: 'Halte den Code in den Rahmen — egal ob Schoki, Shirt oder Shampoo.', ico: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M3 7V5a2 2 0 012-2h2"/><path d="M17 3h2a2 2 0 012 2v2"/>
        <path d="M21 17v2a2 2 0 01-2 2h-2"/><path d="M7 21H5a2 2 0 01-2-2v-2"/>
        <line x1="7" y1="12" x2="17" y2="12"/>
      </svg>
    ) },
    { n: '02', t: 'ESG-Score lesen', d: 'Drei Säulen, eine Zahl: Umwelt · Soziales · Transparenz. Plus kategorie-spezifische Infos.', ico: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <line x1="6" y1="20" x2="6" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="18" y1="20" x2="18" y2="14"/>
      </svg>
    ) },
    { n: '03', t: 'Bewusst entscheiden', d: 'Mit klarem Verdikt, Quellenlage und Alternativen — kein "5-Sterne-Gefühl".', ico: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 6L9 17l-5-5"/>
      </svg>
    ) },
  ];

  return (
    <div style={{
      background: SF_C.bg, height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
    }}>
      <OnbHeader step={1}/>

      <div style={{ padding: '36px 28px 0' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 10 }}>
          So funktioniert's
        </div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 32, lineHeight: 1.1, letterSpacing: '-0.025em',
          color: SF_C.ink1,
        }}>
          Drei Schritte —<br/>
          <em style={{ color: SF_C.green500 }}>weniger als 5 Sekunden.</em>
        </div>
      </div>

      <div style={{ padding: '28px 22px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {steps.map((s, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'flex-start', gap: 14,
            padding: '14px 16px',
            background: SF_C.card,
            border: `1px solid ${SF_C.borderSoft}`,
            borderRadius: 16,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12,
              background: SF_C.green50,
              color: SF_C.green600,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>{s.ico}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 4 }}>
                <span style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.1em', color: SF_C.ink3, fontVariantNumeric: 'tabular-nums' }}>{s.n}</span>
                <span style={{ fontSize: 15, fontWeight: 600, color: SF_C.ink1 }}>{s.t}</span>
              </div>
              <div style={{ fontSize: 12.5, color: SF_C.ink2, lineHeight: 1.5 }}>{s.d}</div>
            </div>
          </div>
        ))}
      </div>

      <OnbFooter/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// O3 — Datenquellen & Vertrauen
// ─────────────────────────────────────────────────────────────
function O3_Trust() {
  const sources = [
    { k: 'OFF',   t: 'Open Food Facts',         d: '3.5M Produkte · CC BY-SA',     c: '#0F7B5C' },
    { k: 'OBF',   t: 'Open Beauty Facts',       d: 'Inhaltsstoffe & INCI',         c: '#C97B5C' },
    { k: 'GS1',   t: 'GS1-Datenbank',           d: 'Marken & Hersteller',          c: '#4F46E5' },
    { k: 'NGO',   t: 'NGO-Reports',             d: 'FairWear · Greenpeace · Öko-Test', c: '#0A6248' },
  ];

  return (
    <div style={{
      background: SF_C.bg, height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
    }}>
      <OnbHeader step={2}/>

      <div style={{ padding: '36px 28px 0' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 10 }}>
          Worauf wir vertrauen
        </div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 32, lineHeight: 1.1, letterSpacing: '-0.025em',
          color: SF_C.ink1, marginBottom: 14,
        }}>
          Offene Daten,<br/>
          <em style={{ color: SF_C.green500 }}>nachvollziehbar.</em>
        </div>
        <div style={{ fontSize: 13.5, color: SF_C.ink2, lineHeight: 1.55 }}>
          Jede Bewertung zeigt die Quelle und die Datenqualität. Du siehst, woher wir wissen, was wir behaupten.
        </div>
      </div>

      <div style={{ padding: '24px 22px 0', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {sources.map((s, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '12px 14px',
            background: SF_C.card,
            border: `1px solid ${SF_C.borderSoft}`,
            borderRadius: 12,
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10,
              background: s.c, color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 10, fontWeight: 700, letterSpacing: '0.04em',
              flexShrink: 0,
            }}>{s.k}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: SF_C.ink1 }}>{s.t}</div>
              <div style={{ fontSize: 11.5, color: SF_C.ink3, marginTop: 1 }}>{s.d}</div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ padding: '14px 22px 0' }}>
        <div style={{
          background: SF_C.green50,
          border: `1px solid ${SF_C.green100}`,
          borderRadius: 12,
          padding: '12px 14px',
          fontSize: 12, color: SF_C.green600, lineHeight: 1.5,
        }}>
          <strong style={{ fontWeight: 700 }}>Kein Score ohne Quelle.</strong> Fehlt uns Datengrundlage, sagen wir es — statt zu raten.
        </div>
      </div>

      <OnbFooter primaryLabel="Ersten Scan starten" skipLabel={null}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// E1 — Offline (keine Verbindung, gecachte Scans verfügbar)
// ─────────────────────────────────────────────────────────────
function E1_Offline() {
  return (
    <div style={{
      background: SF_C.bg, height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
    }}>
      <ScreenNav title="Offline"/>

      {/* Status banner */}
      <div style={{
        margin: '0 16px',
        padding: '12px 14px',
        background: '#FEF3C7',
        border: '1px solid #FCD34D',
        borderRadius: 12,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 999,
          background: '#fff', color: '#92400E',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <line x1="3" y1="3" x2="21" y2="21"/>
            <path d="M5 12.55a11 11 0 0114.08 0"/>
            <path d="M1.42 9a16 16 0 0121.16 0"/>
            <path d="M8.53 16.11a6 6 0 016.95 0"/>
            <line x1="12" y1="20" x2="12.01" y2="20"/>
          </svg>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#92400E' }}>Keine Verbindung</div>
          <div style={{ fontSize: 11.5, color: '#78350F', marginTop: 1 }}>Neue Scans pausieren — gecachte Produkte sind weiter verfügbar.</div>
        </div>
      </div>

      <div style={{ padding: '28px 28px 12px', textAlign: 'center' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.ink3, marginBottom: 8 }}>
          Aus dem Cache
        </div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 28, lineHeight: 1.1, letterSpacing: '-0.02em',
          color: SF_C.ink1,
        }}>
          12 Produkte<br/>
          <em style={{ color: SF_C.green500 }}>weiterhin abrufbar.</em>
        </div>
      </div>

      {/* cached scans list */}
      <div style={{ padding: '16px 16px 0', flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
        {[
          { p: window.SCANFAIR_PRODUCTS[3], age: 'Heute' },
          { p: window.SCANFAIR_PRODUCTS[4], age: 'Heute' },
          { p: window.SCANFAIR_PRODUCTS[7], age: 'Gestern' },
          { p: window.SCANFAIR_PRODUCTS[5], age: 'Gestern' },
        ].map((it, i) => {
          const tc = sfTrafficColor(it.p.esg.verdict);
          return (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 12px',
              borderRadius: 14,
              background: SF_C.card,
              border: `1px solid ${SF_C.borderSoft}`,
              opacity: 0.94,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: SF_C.bgAlt,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 18,
              }}>{it.p.image_emoji}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: SF_C.ink1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {it.p.product_name}
                </div>
                <div style={{ fontSize: 11, color: SF_C.ink3, display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span>{it.age}</span>
                  <span style={{ width: 3, height: 3, borderRadius: '50%', background: SF_C.ink3, opacity: 0.5 }}/>
                  <span>gecacht</span>
                </div>
              </div>
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 5,
                padding: '5px 9px',
                borderRadius: 999,
                background: sfTrafficBg(it.p.esg.verdict),
                fontSize: 12, fontWeight: 700, color: tc,
              }}>
                <div style={{ width: 6, height: 6, borderRadius: '50%', background: tc }}/>
                {it.p.esg.total.toFixed(1)}
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ padding: '14px 16px 22px' }}>
        <button style={{
          width: '100%',
          padding: '13px 18px',
          background: SF_C.card,
          border: `1px solid ${SF_C.borderSoft}`,
          color: SF_C.ink1, borderRadius: 14,
          fontSize: 13, fontWeight: 600, fontFamily: 'inherit',
          cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <span style={{ fontSize: 14 }}>↻</span>
          Erneut versuchen
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// E2 — Low-Data (Datenqualität niedrig — Hinweis statt Score)
// ─────────────────────────────────────────────────────────────
function E2_LowData({ product }) {
  const p = product || window.SCANFAIR_DEMO_BY_TYPE.cosmetics;
  return (
    <div style={{
      background: SF_C.bg, height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
    }}>
      <ScreenNav title="Begrenzt bewertbar"/>
      <ProductCard product={p}/>

      <div style={{ padding: '0 20px 0' }}>
        <div style={{
          background: SF_C.card,
          borderRadius: 20,
          overflow: 'hidden',
          boxShadow: '0 4px 16px rgba(26,38,34,0.06)',
        }}>
          {/* striped warning band */}
          <div style={{
            height: 6,
            background: 'repeating-linear-gradient(90deg, #D9A35A 0 12px, #B8853F 12px 24px)',
          }}/>
          <div style={{ padding: '22px 22px 20px' }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: '#B8853F', marginBottom: 8 }}>
              Datengrundlage zu dünn
            </div>
            <div style={{
              fontFamily: "'Instrument Serif', serif",
              fontSize: 30, lineHeight: 1.1, letterSpacing: '-0.02em',
              color: SF_C.ink1, marginBottom: 12,
            }}>
              Wir geben hier <em style={{ color: '#B8853F' }}>keinen Score.</em>
            </div>
            <div style={{ fontSize: 13.5, color: SF_C.ink2, lineHeight: 1.55 }}>
              Drei von acht Indikatoren fehlen. Statt zu raten zeigen wir, was wir wissen — und was nicht.
            </div>
          </div>
        </div>
      </div>

      {/* Quality breakdown */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3, marginBottom: 10 }}>
          Datenqualität
        </div>
        <div style={{ background: SF_C.card, borderRadius: 16, padding: '14px 16px', border: `1px solid ${SF_C.borderSoft}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
            <div style={{ flex: 1, height: 8, background: SF_C.bgAlt, borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ width: '38%', height: '100%', background: '#D9A35A' }}/>
            </div>
            <span style={{ fontSize: 14, fontWeight: 700, color: SF_C.ink1, fontVariantNumeric: 'tabular-nums' }}>38%</span>
          </div>
          {[
            { ok: true,  l: 'Marke & Hersteller',    s: 'GS1' },
            { ok: true,  l: 'Inhaltsstoffe (INCI)',   s: 'Open Beauty Facts' },
            { ok: false, l: 'Lieferketten-Transparenz', s: 'fehlt' },
            { ok: false, l: 'Mikroplastik-Prüfung',     s: 'fehlt' },
            { ok: false, l: 'Tierversuche-Status',      s: 'fehlt' },
          ].map((it, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '8px 0',
              borderBottom: i < arr.length - 1 ? `1px solid ${SF_C.borderSoft}` : 'none',
            }}>
              <div style={{
                width: 18, height: 18, borderRadius: 999,
                background: it.ok ? SF_C.green50 : '#FEE2E2',
                color: it.ok ? SF_C.green600 : '#C2410C',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, fontWeight: 700, flexShrink: 0,
              }}>{it.ok ? '✓' : '?'}</div>
              <div style={{ flex: 1, fontSize: 12.5, color: SF_C.ink1 }}>{it.l}</div>
              <div style={{ fontSize: 11, color: SF_C.ink3 }}>{it.s}</div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div style={{ padding: '14px 20px 22px', marginTop: 'auto' }}>
        <button style={{
          width: '100%',
          padding: '13px 18px',
          background: SF_C.green500, color: '#fff',
          border: 'none', borderRadius: 14,
          fontSize: 14, fontWeight: 600, fontFamily: 'inherit',
          cursor: 'pointer',
        }}>
          Hersteller anfragen
        </button>
        <div style={{ textAlign: 'center', fontSize: 11.5, color: SF_C.ink3, marginTop: 10, lineHeight: 1.5 }}>
          Sammeln wir genug Anfragen, leiten wir sie gebündelt weiter.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// E3 — Tablet (Result-Screen, 2-Spalten Layout)
//   Wird auf größerem Frame gerendert — dieselbe Logik, breiteres Grid.
// ─────────────────────────────────────────────────────────────
function E3_TabletResult({ product }) {
  const p = product || window.SCANFAIR_DEMO_BY_TYPE.food;
  return (
    <div style={{
      background: SF_C.bg, height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
    }}>
      {/* Top bar */}
      <div style={{
        padding: '16px 28px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        borderBottom: `1px solid ${SF_C.borderSoft}`,
        background: 'rgba(251,250,246,0.94)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          <div style={{
            fontFamily: "'Instrument Serif', serif",
            fontSize: 22, color: SF_C.ink1, letterSpacing: '-0.01em',
          }}>
            Scan<em style={{ color: SF_C.green500 }}>Fair</em>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: SF_C.ink3 }}>
            <span>Scan</span>
            <span>›</span>
            <span style={{ color: SF_C.ink1, fontWeight: 600 }}>Ergebnis</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button style={{
            padding: '9px 14px', background: SF_C.card,
            border: `1px solid ${SF_C.borderSoft}`,
            color: SF_C.ink1, borderRadius: 10, fontSize: 12.5, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer',
          }}>↗ Teilen</button>
          <button style={{
            padding: '9px 14px', background: SF_C.green500,
            border: 'none',
            color: '#fff', borderRadius: 10, fontSize: 12.5, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer',
          }}>✓ Merken</button>
        </div>
      </div>

      {/* 2-column main */}
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1.05fr 1fr', gap: 24, padding: 24, overflow: 'hidden' }}>
        {/* Left: Hero + Product */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16, minWidth: 0 }}>
          {/* Product card big */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 18,
            padding: '20px 22px',
            background: SF_C.card,
            borderRadius: 20,
            border: `1px solid ${SF_C.borderSoft}`,
          }}>
            <div style={{
              width: 84, height: 84, borderRadius: 18,
              background: SF_C.bgAlt,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 44, flexShrink: 0,
            }}>{p.image_emoji}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 4 }}>
                {p.brand}
              </div>
              <div style={{ fontSize: 22, fontWeight: 600, color: SF_C.ink1, lineHeight: 1.2, letterSpacing: '-0.01em' }}>
                {p.product_name}
              </div>
              <div style={{ fontSize: 13, color: SF_C.ink3, marginTop: 4 }}>
                {p.category} · {p.origin}
              </div>
            </div>
          </div>

          {/* Hero score — bigger */}
          <div style={{
            background: SF_C.card,
            borderRadius: 24,
            overflow: 'hidden',
            boxShadow: '0 6px 22px rgba(26,38,34,0.06)',
            flex: 1,
            display: 'flex', flexDirection: 'column',
          }}>
            <div style={{ height: 8, background: sfTrafficColor(p.esg.verdict) }}/>
            <div style={{ padding: '28px 28px 24px', flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', color: sfTrafficColor(p.esg.verdict), marginBottom: 10 }}>
                  ESG-Score
                </div>
                <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                    <span style={{
                      fontFamily: "'Instrument Serif', serif",
                      fontSize: 96, fontWeight: 400, color: SF_C.ink1,
                      lineHeight: 0.85, letterSpacing: '-0.025em',
                    }}>{p.esg.total.toFixed(1)}</span>
                    <span style={{ fontSize: 22, color: SF_C.ink3 }}>/ 10</span>
                  </div>
                  <div style={{
                    display: 'inline-flex', alignItems: 'center', gap: 8,
                    padding: '10px 14px',
                    borderRadius: 999,
                    background: sfTrafficBg(p.esg.verdict),
                    color: sfTrafficColor(p.esg.verdict),
                    fontSize: 13, fontWeight: 600,
                    whiteSpace: 'nowrap',
                  }}>
                    <div style={{ width: 8, height: 8, borderRadius: '50%', background: sfTrafficColor(p.esg.verdict) }}/>
                    {p.esg.verdict_label}
                  </div>
                </div>
                <div style={{ fontSize: 14.5, color: SF_C.ink2, marginTop: 16, lineHeight: 1.55 }}>
                  {p.esg.tagline}
                </div>
              </div>

              {/* Pillars inline */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginTop: 22 }}>
                {[
                  { k: 'e', l: 'Umwelt' },
                  { k: 's', l: 'Soziales' },
                  { k: 'g', l: 'Transparenz' },
                ].map((pi, i) => (
                  <div key={i} style={{ padding: '12px 14px', background: SF_C.bgAlt, borderRadius: 12 }}>
                    <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3, marginBottom: 4 }}>{pi.l}</div>
                    <div style={{ fontSize: 22, fontWeight: 600, fontFamily: "'Instrument Serif', serif", color: SF_C.ink1, fontVariantNumeric: 'tabular-nums' }}>
                      {p.esg[pi.k].toFixed(1)}<span style={{ fontSize: 12, color: SF_C.ink3 }}>/10</span>
                    </div>
                    <div style={{ height: 4, background: '#E5E2D8', borderRadius: 2, marginTop: 8, overflow: 'hidden' }}>
                      <div style={{ width: `${p.esg[pi.k] * 10}%`, height: '100%', background: PILLAR_META[pi.k].color, borderRadius: 2 }}/>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Right: Secondary + Checklist + Footnote */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, minWidth: 0, overflow: 'auto' }}>
          {p.secondaryInfo && (
            <div style={{ background: SF_C.card, borderRadius: 16, padding: '16px 18px', border: `1px solid ${SF_C.borderSoft}` }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3 }}>
                  {p.secondaryInfo.title || 'Gesundheit'}
                </div>
                <div style={{ fontSize: 11, color: SF_C.ink3, fontStyle: 'italic' }}>kein Score · zur Information</div>
              </div>
              <div style={{ position: 'relative', height: 10, marginBottom: 8 }}>
                <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(90deg, #C26A4A 0%, #D9A35A 33%, #94B864 66%, #3D9B76 100%)', borderRadius: 5 }}/>
                <div style={{
                  position: 'absolute',
                  left: `${(p.secondaryInfo.position / 10) * 100}%`,
                  top: '50%', transform: 'translate(-50%, -50%)',
                  width: 18, height: 18, borderRadius: '50%',
                  background: '#fff', border: `3px solid ${SF_C.ink1}`,
                  boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
                }}/>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: SF_C.ink3, marginBottom: 10, letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>
                <span>{p.secondaryInfo.barLeft || 'ungünstig'}</span>
                <span>{p.secondaryInfo.barRight || 'nährstoffreich'}</span>
              </div>
              <div style={{ fontSize: 14, fontWeight: 600, color: SF_C.ink1, marginBottom: 4 }}>{p.secondaryInfo.label}</div>
              <div style={{ fontSize: 12.5, color: SF_C.ink2, lineHeight: 1.5 }}>{p.secondaryInfo.facts}</div>
            </div>
          )}

          {p.checklist && p.checklist.length > 0 && (
            <div style={{ background: SF_C.card, borderRadius: 16, padding: '6px 16px', border: `1px solid ${SF_C.borderSoft}` }}>
              {p.checklist.slice(0, 5).map((it, i, arr) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'flex-start', gap: 12,
                  padding: '12px 0',
                  borderBottom: i < arr.length - 1 ? `1px solid ${SF_C.borderSoft}` : 'none',
                }}>
                  <div style={{
                    width: 22, height: 22, borderRadius: 999,
                    background: it.ok ? SF_C.green50 : '#FEE2E2',
                    color: it.ok ? SF_C.green600 : '#C2410C',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0, fontSize: 13, fontWeight: 700, marginTop: 1,
                  }}>{it.ok ? '✓' : '✕'}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 600, color: SF_C.ink1, lineHeight: 1.3 }}>{it.label}</div>
                    {it.note && <div style={{ fontSize: 11.5, color: SF_C.ink3, marginTop: 2, lineHeight: 1.4 }}>{it.note}</div>}
                  </div>
                </div>
              ))}
            </div>
          )}

          <div style={{
            background: SF_C.bgAlt,
            borderRadius: 12,
            padding: '12px 14px',
            fontSize: 11.5, color: SF_C.ink3, lineHeight: 1.55,
          }}>
            <strong style={{ color: SF_C.ink2, fontWeight: 600 }}>Datenquelle:</strong>{' '}
            Open Food Facts · ScanFair-Methodik v1.0 · Datenqualität:{' '}
            <span style={{ color: SF_C.green600, fontWeight: 600 }}>
              {Math.round(p.data_completeness * 100)}%
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  O1_Welcome, O2_How, O3_Trust,
  E1_Offline, E2_LowData, E3_TabletResult,
});
