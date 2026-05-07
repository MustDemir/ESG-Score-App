/* =============================================================
   ScanFair — Phase 2.3: Hi-Fi Hauptscreens S1–S5
   Auf Design-Canvas: 5 iPhone-Mockups + Übersicht
   - Two-Score-Modell: ESG = Hauptscore, Health = Begleithinweis ohne Score
   - Tweak: Health-Bar-Variante (linear / discrete / minimal)
   ============================================================= */

const { useState } = React;

// ─────────────────────────────────────────────────────────────
// Tweak Defaults
// ─────────────────────────────────────────────────────────────
const SCREEN_TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "healthVariant": "linear",
  "scoreOnDarkHero": false,
  "showOriginInScanner": true
}/*EDITMODE-END*/;

// Demo product = GEPA Bio-Schokolade (index 1)
const PROD = window.SCANFAIR_PRODUCTS[1];

// Mock product details for the expandable bars (S4)
const PROD_DETAILS = {
  e: [
    { label: 'CO₂-Fußabdruck',     value: '5.8 kg / 100g · ⌀ Kategorie 6.4 kg' },
    { label: 'Bio-Zertifizierung', value: 'EU-Bio + Demeter' },
    { label: 'Verpackung',         value: 'Papier + Aluminium-Inlay (teilrecyclebar)' },
    { label: 'Transportweg',       value: 'Ghana → DE · Schiff (geringer Flug-Anteil)' },
  ],
  s: [
    { label: 'Faire Löhne',        value: 'Fairtrade + GEPA fair+ (über Mindeststandard)' },
    { label: 'Lieferkette',        value: 'Kakao direkt aus Kuapa Kokoo Kooperative' },
    { label: 'Arbeitsbedingungen', value: 'Audits jährlich · keine Kinderarbeit dokumentiert' },
    { label: 'Bildungsprojekte',   value: 'Schulen vor Ort werden mitfinanziert' },
  ],
  g: [
    { label: 'Datenqualität',      value: '95% komplett · Quelle: GEPA-Nachhaltigkeitsbericht' },
    { label: 'Zertifikate',        value: 'Demeter ✓ · Fairtrade ✓ · EU-Bio ✓' },
    { label: 'Audits',             value: 'Drittpartei-Audit (FLOCERT) · letzte Prüfung 2024' },
    { label: 'Herkunftsnachweis',  value: 'Trace-Code auf Verpackung · prüfbar' },
  ],
};

// ─────────────────────────────────────────────────────────────
// S1 — Home / Scanner (Hero)
// ─────────────────────────────────────────────────────────────
function S1_Home({ tweaks }) {
  return (
    <div style={{
      background: SF_C.deep,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: '#fff',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* warm grain overlay */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(120% 80% at 50% 0%, rgba(15,123,92,0.35) 0%, rgba(14,27,23,0) 60%)',
        pointerEvents: 'none',
      }}/>

      {/* Top — brand + profile */}
      <div style={{
        position: 'relative', zIndex: 1,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '12px 20px 0',
      }}>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 22, color: '#fff', letterSpacing: '-0.01em',
        }}>
          Scan<em style={{ color: SF_C.green100 }}>Fair</em>
        </div>
        <div style={{
          width: 36, height: 36, borderRadius: 999,
          background: 'rgba(255,255,255,0.1)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 14, fontWeight: 600,
        }}>S</div>
      </div>

      {/* Greeting */}
      <div style={{ position: 'relative', zIndex: 1, padding: '32px 24px 0' }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: SF_C.green100, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 8 }}>
          Donnerstag, 21. Mai
        </div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 38, lineHeight: 1.05, letterSpacing: '-0.02em',
          color: '#fff', maxWidth: 280,
        }}>
          Was gibt's heute<br/>
          <em style={{ color: SF_C.green100 }}>im Wagen?</em>
        </div>
      </div>

      {/* Scanner CTA */}
      <div style={{ position: 'relative', zIndex: 1, padding: '36px 24px 0' }}>
        <button style={{
          width: '100%',
          padding: '20px 22px',
          borderRadius: 20,
          background: SF_C.green500,
          color: '#fff', border: 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          cursor: 'pointer', fontFamily: 'inherit',
          boxShadow: '0 8px 32px rgba(15,123,92,0.4)',
        }}>
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.green100, marginBottom: 4 }}>
              Hauptaktion
            </div>
            <div style={{ fontSize: 18, fontWeight: 600 }}>Barcode scannen</div>
          </div>
          <div style={{
            width: 48, height: 48, borderRadius: 14,
            background: 'rgba(255,255,255,0.18)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 22,
          }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round">
              <path d="M3 7V5a2 2 0 012-2h2"/>
              <path d="M17 3h2a2 2 0 012 2v2"/>
              <path d="M21 17v2a2 2 0 01-2 2h-2"/>
              <path d="M7 21H5a2 2 0 01-2-2v-2"/>
              <line x1="7" y1="12" x2="17" y2="12"/>
            </svg>
          </div>
        </button>
        <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
          <button style={{
            flex: 1, padding: '11px 12px',
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            color: '#fff', borderRadius: 12,
            fontSize: 13, fontWeight: 500, fontFamily: 'inherit',
            cursor: 'pointer',
          }}>Suchen</button>
          <button style={{
            flex: 1, padding: '11px 12px',
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            color: '#fff', borderRadius: 12,
            fontSize: 13, fontWeight: 500, fontFamily: 'inherit',
            cursor: 'pointer',
          }}>Manuell eingeben</button>
        </div>
      </div>

      {/* Recent Scans */}
      <div style={{ position: 'relative', zIndex: 1, padding: '32px 24px 0', flex: 1 }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'rgba(255,255,255,0.5)', marginBottom: 12 }}>
          Zuletzt gescannt
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { p: window.SCANFAIR_PRODUCTS[3], time: 'gerade eben' },
            { p: window.SCANFAIR_PRODUCTS[5], time: 'heute, 09:14' },
            { p: window.SCANFAIR_PRODUCTS[2], time: 'gestern' },
          ].map((it, i) => {
            const tc = sfTrafficColor(it.p.esg.verdict);
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 12px',
                borderRadius: 14,
                background: 'rgba(255,255,255,0.06)',
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: 'rgba(255,255,255,0.08)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 18,
                }}>{it.p.image_emoji}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: '#fff', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {it.p.product_name}
                  </div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)' }}>
                    {it.time}
                  </div>
                </div>
                <div style={{
                  display: 'inline-flex', alignItems: 'center', gap: 5,
                  padding: '5px 9px',
                  borderRadius: 999,
                  background: `${tc}40`,
                  fontSize: 12, fontWeight: 700, color: '#fff',
                }}>
                  <div style={{ width: 6, height: 6, borderRadius: '50%', background: tc }}/>
                  {it.p.esg.total.toFixed(1)}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom Tabs */}
      <div style={{
        position: 'relative', zIndex: 1,
        display: 'flex',
        padding: '12px 16px 16px',
        borderTop: '1px solid rgba(255,255,255,0.08)',
        background: 'rgba(14,27,23,0.85)',
        backdropFilter: 'blur(12px)',
        marginTop: 'auto',
      }}>
        {[
          { l: 'Scannen', a: true, i: '◉' },
          { l: 'Verlauf', i: '☰' },
          { l: 'Impact',  i: '↗' },
          { l: 'Profil',  i: '○' },
        ].map((t, i) => (
          <div key={i} style={{
            flex: 1, textAlign: 'center',
            color: t.a ? '#fff' : 'rgba(255,255,255,0.45)',
            fontSize: 11, fontWeight: 600,
          }}>
            <div style={{ fontSize: 20, marginBottom: 2, color: t.a ? SF_C.green100 : 'inherit' }}>{t.i}</div>
            {t.l}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S2 — Scan / Camera State
// ─────────────────────────────────────────────────────────────
function S2_Scanner({ tweaks }) {
  return (
    <div style={{
      background: '#0A0F0D',
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: '#fff',
      position: 'relative',
    }}>
      {/* Mock camera background — gradient simulating supermarket */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(180deg, #2a2520 0%, #1a1814 40%, #0E1B17 100%)',
      }}/>
      {/* Subtle product silhouette */}
      <div style={{
        position: 'absolute',
        left: '50%', top: '45%',
        transform: 'translate(-50%, -50%)',
        fontSize: 200, opacity: 0.06,
      }}>{PROD.image_emoji}</div>

      {/* Top nav */}
      <div style={{ position: 'relative', zIndex: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 18px' }}>
        <div style={{
          width: 36, height: 36, borderRadius: 999,
          background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18, color: '#fff',
        }}>×</div>
        <div style={{
          padding: '6px 12px',
          borderRadius: 999,
          background: 'rgba(255,255,255,0.15)',
          backdropFilter: 'blur(8px)',
          fontSize: 12, fontWeight: 600, color: '#fff',
        }}>Scanner</div>
        <div style={{
          width: 36, height: 36, borderRadius: 999,
          background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 16, color: '#fff',
        }}>⚡</div>
      </div>

      {/* Scan frame */}
      <div style={{ position: 'relative', zIndex: 2, flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ position: 'relative', width: 260, height: 180 }}>
          {/* corners */}
          {[
            { top: 0, left: 0, borderTop: '3px solid #fff', borderLeft: '3px solid #fff' },
            { top: 0, right: 0, borderTop: '3px solid #fff', borderRight: '3px solid #fff' },
            { bottom: 0, left: 0, borderBottom: '3px solid #fff', borderLeft: '3px solid #fff' },
            { bottom: 0, right: 0, borderBottom: '3px solid #fff', borderRight: '3px solid #fff' },
          ].map((s, i) => (
            <div key={i} style={{ position: 'absolute', width: 32, height: 32, borderTopLeftRadius: i===0?6:0, borderTopRightRadius: i===1?6:0, borderBottomLeftRadius: i===2?6:0, borderBottomRightRadius: i===3?6:0, ...s }}/>
          ))}
          {/* Scanline */}
          <div style={{
            position: 'absolute',
            left: 8, right: 8,
            top: '50%',
            height: 2,
            background: 'linear-gradient(90deg, transparent 0%, #3D9B76 20%, #8FC2A8 50%, #3D9B76 80%, transparent 100%)',
            boxShadow: '0 0 12px #3D9B76',
          }}/>
          {/* hint text */}
          <div style={{
            position: 'absolute',
            top: 'calc(100% + 18px)', left: 0, right: 0,
            textAlign: 'center',
            fontSize: 13, fontWeight: 500, color: 'rgba(255,255,255,0.85)',
          }}>Barcode in den Rahmen halten</div>
        </div>
      </div>

      {/* Footer hint */}
      <div style={{ position: 'relative', zIndex: 2, padding: '16px 24px 24px' }}>
        <div style={{
          background: 'rgba(255,255,255,0.08)', backdropFilter: 'blur(10px)',
          borderRadius: 14,
          padding: '12px 14px',
          display: 'flex', alignItems: 'center', gap: 12,
          border: '1px solid rgba(255,255,255,0.1)',
        }}>
          <div style={{ width: 32, height: 32, borderRadius: 8, background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>⌨</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#fff' }}>Barcode manuell eingeben</div>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.55)' }}>Falls dein Code nicht erkannt wird</div>
          </div>
          <div style={{ fontSize: 18, color: 'rgba(255,255,255,0.5)' }}>›</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S3 — Score Result (HERO — V1+V3 Hybrid)
// ─────────────────────────────────────────────────────────────
function S3_ScoreResult({ tweaks }) {
  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      overflow: 'auto',
    }}>
      <ScreenNav title="Ergebnis"/>
      <ProductCard product={PROD}/>
      <ScoreHero esg={PROD.esg}/>
      <ScoreBars esg={PROD.esg}/>
      <HealthBar health={PROD.health} variant={tweaks.healthVariant}/>
      <ScoreCTAs/>
      <MethodFootnote product={PROD}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S4 — Score Details (expandable bars)
// ─────────────────────────────────────────────────────────────
function S4_ScoreDetails({ tweaks }) {
  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      overflow: 'auto',
    }}>
      <ScreenNav title="Details &amp; Quellen"/>
      <ProductCard product={PROD} compact/>

      {/* Tab switch ESG / Hist */}
      <div style={{ padding: '4px 20px 12px' }}>
        <div style={{
          display: 'flex',
          background: SF_C.bgAlt,
          padding: 4,
          borderRadius: 12,
          gap: 4,
        }}>
          {['ESG-Säulen', 'Vergleich', 'Quellen'].map((t, i) => (
            <div key={i} style={{
              flex: 1, textAlign: 'center',
              padding: '8px 10px',
              borderRadius: 8,
              fontSize: 12, fontWeight: 600,
              background: i === 0 ? SF_C.card : 'transparent',
              color: i === 0 ? SF_C.ink1 : SF_C.ink3,
              boxShadow: i === 0 ? '0 1px 3px rgba(0,0,0,0.04)' : 'none',
            }}>{t}</div>
          ))}
        </div>
      </div>

      {/* Expandable bars — first one expanded by default */}
      <ScoreBars esg={PROD.esg} expandable defaultExpanded="e" productDetails={PROD_DETAILS}/>

      <HealthBar health={PROD.health} variant={tweaks.healthVariant}/>
      <MethodFootnote product={PROD}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S5 — Not Found
// ─────────────────────────────────────────────────────────────
function S5_NotFound({ tweaks }) {
  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
    }}>
      <ScreenNav title="Nicht gefunden"/>

      <div style={{ padding: '40px 28px 16px', textAlign: 'center' }}>
        <div style={{
          width: 88, height: 88, borderRadius: '50%',
          background: SF_C.bgAlt,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 22px',
          fontSize: 36,
        }}>🔍</div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 32, lineHeight: 1.1, letterSpacing: '-0.02em',
          color: SF_C.ink1,
          marginBottom: 12,
        }}>
          Dieses Produkt<br/>
          <em style={{ color: SF_C.green500 }}>kennen wir noch nicht.</em>
        </div>
        <div style={{ fontSize: 14, color: SF_C.ink2, lineHeight: 1.55, maxWidth: 280, margin: '0 auto' }}>
          Hilf uns, die Datenbank zu erweitern. Mach ein Foto vom Produkt — der Rest passiert automatisch.
        </div>
      </div>

      <div style={{ padding: '8px 20px 0' }}>
        <div style={{
          background: SF_C.card,
          borderRadius: 16,
          padding: 4,
          border: `1px solid ${SF_C.borderSoft}`,
        }}>
          {[
            { ico: '📷', l: 'Foto vom Produkt machen', d: 'Vorder- und Rückseite reichen aus', primary: true },
            { ico: '✎',  l: 'Manuell hinzufügen',       d: 'Marke, Name, Kategorie eingeben' },
            { ico: '✉',  l: 'Hersteller anfragen',      d: 'Wir fragen die Daten direkt an' },
          ].map((opt, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              padding: '14px 14px',
              borderBottom: i < 2 ? `1px solid ${SF_C.borderSoft}` : 'none',
              cursor: 'pointer',
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10,
                background: opt.primary ? SF_C.green500 : SF_C.bgAlt,
                color: opt.primary ? '#fff' : SF_C.ink1,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 18,
              }}>{opt.ico}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: SF_C.ink1 }}>{opt.l}</div>
                <div style={{ fontSize: 12, color: SF_C.ink3, marginTop: 2 }}>{opt.d}</div>
              </div>
              <div style={{ fontSize: 18, color: SF_C.ink3 }}>›</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '24px 28px', textAlign: 'center' }}>
        <div style={{
          fontSize: 12, color: SF_C.ink3, lineHeight: 1.55,
          padding: '12px 14px',
          background: SF_C.bgAlt,
          borderRadius: 12,
        }}>
          ScanFair lebt von Crowdsourcing. Jeder neue Eintrag macht die Datenbank für alle wertvoller.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// PhoneFrame Wrapper
// ─────────────────────────────────────────────────────────────
function PhoneFrame({ dark = false, children }) {
  return (
    <IOSDevice width={400} height={840} dark={dark}>
      <IOSStatusBar dark={dark}/>
      <div style={{ height: 'calc(100% - 50px)', overflow: 'hidden' }}>
        {children}
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Overview Board
// ─────────────────────────────────────────────────────────────
function OverviewBoard() {
  return (
    <div style={{
      background: '#fff', height: '100%',
      padding: '40px 48px',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
      boxSizing: 'border-box',
    }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 12 }}>
        Phase 2.3 · Hauptscreens S1–S5
      </div>
      <div style={{
        fontFamily: "'Instrument Serif', serif",
        fontSize: 52, lineHeight: 1.1, letterSpacing: '-0.025em',
        color: SF_C.ink1, marginBottom: 16, maxWidth: 740,
      }}>
        Die fünf Bildschirme der Kern-Scanner-Schleife.
      </div>
      <div style={{ fontSize: 15, color: SF_C.ink2, lineHeight: 1.55, maxWidth: 700, marginBottom: 28 }}>
        Hi-Fi-Mockups im finalen Look. <strong>Two-Score-Modell</strong>: ESG ist der Hauptscore (Zahl + Verdict + 3 Säulen),
        Health ist Begleithinweis (kein Score, nur Skala-Position). Auf S3 &amp; S4 kannst du via{' '}
        <strong style={{ color: SF_C.green600 }}>Tweaks</strong> die Health-Bar-Variante live umschalten — drei
        Optionen zum Vergleich.
      </div>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(5, 1fr)',
        gap: 10,
        marginBottom: 24,
      }}>
        {[
          { n: 'S1', t: 'Home / Scanner',     d: 'Dunkler Hero, Scanner-CTA, letzte Scans' },
          { n: 'S2', t: 'Kamera-Scan',        d: 'Aktiver Scan-Vorgang mit Rahmen' },
          { n: 'S3', t: 'Score-Ergebnis ⭐', d: 'V1+V3-Hybrid: Hero + Säulen + Health' },
          { n: 'S4', t: 'Score-Details',      d: 'Aufklappbare Bars mit Quellen' },
          { n: 'S5', t: 'Nicht gefunden',     d: 'Crowdsourcing-CTA' },
        ].map((s, i) => (
          <div key={i} style={{
            padding: '14px 14px',
            border: `1px solid ${SF_C.borderSoft}`,
            borderRadius: 12,
            background: SF_C.bg,
            minHeight: 110,
          }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.06em', color: SF_C.green500, marginBottom: 6 }}>
              {s.n}
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, color: SF_C.ink1, marginBottom: 4, lineHeight: 1.2 }}>{s.t}</div>
            <div style={{ fontSize: 11, color: SF_C.ink2, lineHeight: 1.45 }}>{s.d}</div>
          </div>
        ))}
      </div>
      <div style={{
        padding: '14px 18px',
        background: SF_C.green50,
        borderRadius: 12,
        fontSize: 13, color: SF_C.green600, lineHeight: 1.55,
        borderLeft: `3px solid ${SF_C.green500}`,
        maxWidth: 760,
      }}>
        <strong>Two-Score-Modell:</strong> Du wolltest, dass Health nicht in den Score eingerechnet wird —
        weil etwas Ungesundes ethisch top sein kann (GEPA-Bio-Schoko) und etwas Gesundes ethisch problematisch
        (Coca-Cola Zero). Der Health-Balken hat deshalb <em>keine Zahl</em>, nur Position auf einer Skala plus
        eine knappe Faktenzeile. Maximaler Respekt für die Autonomie des Nutzers.
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Tweaks Panel
// ─────────────────────────────────────────────────────────────
function ScreenTweaks({ tweaks, setTweak }) {
  return (
    <TweaksPanel title="ScanFair Tweaks">
      <TweakSection label="Health-Balken auf S3 &amp; S4">
        <TweakRadio
          label="Variante"
          value={tweaks.healthVariant}
          options={[
            { label: 'Linear',   value: 'linear' },
            { label: 'Diskret',  value: 'discrete' },
            { label: 'Minimal',  value: 'minimal' },
          ]}
          onChange={(v) => setTweak('healthVariant', v)}
        />
      </TweakSection>
    </TweaksPanel>
  );
}

// ─────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────
function App() {
  const [tweaks, setTweak] = useTweaks(SCREEN_TWEAK_DEFAULTS);
  return (
    <>
      <DesignCanvas
        title="ScanFair · Phase 2.3 — Hi-Fi Hauptscreens"
        subtitle="S1–S5 Kern-Scanner-Schleife · Two-Score-Modell · Tweaks für Health-Variante"
        defaultTool="hand"
      >
        <DCSection id="overview" title="Überblick — was du hier siehst">
          <DCArtboard id="ov" label="Phase 2.3 — Die fünf Hauptscreens" width={920} height={520}>
            <OverviewBoard/>
          </DCArtboard>
        </DCSection>

        <DCSection id="main" title="Hauptscreens — drag-reorder, click für Vollbild">
          <DCArtboard id="s1" data-screen-label="S1 Home" label="S1 — Home / Scanner" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame dark><S1_Home tweaks={tweaks}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s2" data-screen-label="S2 Scanner" label="S2 — Kamera-Scan" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame dark><S2_Scanner tweaks={tweaks}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s3" data-screen-label="S3 Score Result" label="S3 — Score-Ergebnis ⭐ HERO" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S3_ScoreResult tweaks={tweaks}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s4" data-screen-label="S4 Score Details" label="S4 — Score-Details (Quellen)" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S4_ScoreDetails tweaks={tweaks}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s5" data-screen-label="S5 Not Found" label="S5 — Nicht gefunden" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S5_NotFound tweaks={tweaks}/></PhoneFrame>
            </div>
          </DCArtboard>
        </DCSection>

        <DCSection id="next" title="Nächster Schritt">
          <DCArtboard id="next-board" label="Was kommt nach Phase 2.3" width={880} height={360}>
            <div style={{ background: SF_C.bg, height: '100%', padding: '36px 44px', fontFamily: "'Inter', sans-serif", color: SF_C.ink1, boxSizing: 'border-box' }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 12 }}>
                Phase 2.4 + 2.5 stehen an
              </div>
              <div style={{ fontFamily: "'Instrument Serif', serif", fontSize: 32, lineHeight: 1.1, letterSpacing: '-0.02em', marginBottom: 16, maxWidth: 700 }}>
                Sobald du mir sagst, welche Health-Variante &amp; welche kleinen Anpassungen du willst, baue ich:
              </div>
              <ul style={{ margin: 0, padding: 0, listStyle: 'none', fontSize: 14, color: SF_C.ink2, lineHeight: 1.6 }}>
                <li><strong style={{ color: SF_C.ink1 }}>Phase 2.4</strong> — S6 Meal-Prep &amp; S7 Impact-Tracker (deine zwei Differenzierungs-Features)</li>
                <li><strong style={{ color: SF_C.ink1 }}>Phase 2.5</strong> — Onboarding (3 Screens) + Edge-States (Permission, Offline)</li>
                <li><strong style={{ color: SF_C.ink1 }}>Phase 3</strong>   — Klickbarer Prototyp mit allen Screens verbunden</li>
              </ul>
            </div>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>
      <ScreenTweaks tweaks={tweaks} setTweak={setTweak}/>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
