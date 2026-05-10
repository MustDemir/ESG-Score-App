/* =============================================================
   ScanFair — Phase 2.4: Screens (Multi-Kategorie)
   - S1 hell, S2 hell-Chrome, S2.5 Erkennung, S5 Not-Found
   - S3a/b/c & S4a/b/c werden in 02-screens-results.jsx definiert
   ============================================================= */

// ─────────────────────────────────────────────────────────────
// S1 — Home / Scanner (HELL)
// ─────────────────────────────────────────────────────────────
function S1_HomeLight() {
  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
      position: 'relative', overflow: 'hidden',
    }}>
      {/* warm halo at top */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(120% 60% at 50% 0%, rgba(15,123,92,0.08) 0%, rgba(251,250,246,0) 60%)',
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
          fontSize: 22, color: SF_C.ink1, letterSpacing: '-0.01em',
        }}>
          Scan<em style={{ color: SF_C.green500 }}>Fair</em>
        </div>
        <div style={{
          width: 36, height: 36, borderRadius: 999,
          background: SF_C.bgAlt,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 14, fontWeight: 600, color: SF_C.ink1,
        }}>S</div>
      </div>

      {/* Greeting */}
      <div style={{ position: 'relative', zIndex: 1, padding: '32px 24px 0' }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: SF_C.green500, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 8 }}>
          Donnerstag, 21. Mai
        </div>
        <div style={{
          fontFamily: "'Instrument Serif', serif",
          fontSize: 38, lineHeight: 1.05, letterSpacing: '-0.02em',
          color: SF_C.ink1, maxWidth: 280,
        }}>
          Was gibt's heute<br/>
          <em style={{ color: SF_C.green500 }}>im Wagen?</em>
        </div>
      </div>

      {/* Scanner CTA */}
      <div style={{ position: 'relative', zIndex: 1, padding: '32px 24px 0' }}>
        <button style={{
          width: '100%',
          padding: '20px 22px',
          borderRadius: 20,
          background: SF_C.green500,
          color: '#fff', border: 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          cursor: 'pointer', fontFamily: 'inherit',
          boxShadow: '0 12px 28px rgba(15,123,92,0.25)',
        }}>
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.green100, marginBottom: 4 }}>
              Hauptaktion
            </div>
            <div style={{ fontSize: 18, fontWeight: 600 }}>Barcode scannen</div>
          </div>
          <div style={{
            width: 48, height: 48, borderRadius: 14,
            background: 'rgba(255,255,255,0.2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
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
            background: SF_C.card,
            border: `1px solid ${SF_C.borderSoft}`,
            color: SF_C.ink1, borderRadius: 12,
            fontSize: 13, fontWeight: 600, fontFamily: 'inherit',
            cursor: 'pointer',
          }}>Suchen</button>
          <button style={{
            flex: 1, padding: '11px 12px',
            background: SF_C.card,
            border: `1px solid ${SF_C.borderSoft}`,
            color: SF_C.ink1, borderRadius: 12,
            fontSize: 13, fontWeight: 600, fontFamily: 'inherit',
            cursor: 'pointer',
          }}>Manuell eingeben</button>
        </div>
      </div>

      {/* Category badges — was scannt man eigentlich */}
      <div style={{ position: 'relative', zIndex: 1, padding: '28px 24px 0' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3, marginBottom: 10 }}>
          Was du scannen kannst
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {[
            { ico: '🥕', l: 'Lebensmittel' },
            { ico: '👕', l: 'Kleidung' },
            { ico: '🧴', l: 'Kosmetik' },
          ].map((c, i) => (
            <div key={i} style={{
              flex: 1,
              padding: '12px 8px',
              background: SF_C.card,
              border: `1px solid ${SF_C.borderSoft}`,
              borderRadius: 14,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              fontSize: 12, fontWeight: 600, color: SF_C.ink1,
              textAlign: 'center',
            }}>
              <div style={{ fontSize: 22 }}>{c.ico}</div>
              {c.l}
            </div>
          ))}
        </div>
      </div>

      {/* Recent Scans */}
      <div style={{ position: 'relative', zIndex: 1, padding: '24px 24px 0', flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.ink3 }}>
            Zuletzt gescannt
          </div>
          <div style={{ fontSize: 12, color: SF_C.green500, fontWeight: 600 }}>Alle ›</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            { p: window.SCANFAIR_PRODUCTS[3], time: 'gerade eben' },
            { p: window.SCANFAIR_PRODUCTS[4], time: 'heute, 11:04' },
            { p: window.SCANFAIR_PRODUCTS[7], time: 'gestern' },
          ].map((it, i) => {
            const tc = sfTrafficColor(it.p.esg.verdict);
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 12px',
                borderRadius: 14,
                background: SF_C.card,
                border: `1px solid ${SF_C.borderSoft}`,
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
                  <div style={{ fontSize: 11, color: SF_C.ink3 }}>
                    {it.time}
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
      </div>

      {/* Bottom Tabs */}
      <div style={{
        position: 'relative', zIndex: 1,
        display: 'flex',
        padding: '10px 16px 14px',
        borderTop: `1px solid ${SF_C.borderSoft}`,
        background: 'rgba(251,250,246,0.92)',
        backdropFilter: 'blur(12px)',
        marginTop: 'auto',
      }}>
        {[
          { l: 'Scannen', a: true,  i: '◉' },
          { l: 'Verlauf', i: '☰' },
          { l: 'Impact',  i: '↗' },
          { l: 'Profil',  i: '○' },
        ].map((t, i) => (
          <div key={i} style={{
            flex: 1, textAlign: 'center',
            color: t.a ? SF_C.green500 : SF_C.ink3,
            fontSize: 11, fontWeight: 600,
          }}>
            <div style={{ fontSize: 20, marginBottom: 2 }}>{t.i}</div>
            {t.l}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S2 — Camera Scan (Kamera dunkel, Chrome hell-tönig)
// ─────────────────────────────────────────────────────────────
function S2_ScannerLight() {
  return (
    <div style={{
      background: '#1a1814',
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: '#fff',
      position: 'relative',
    }}>
      {/* mock camera viewport */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(180deg, #2a2520 0%, #1a1814 60%, #1a1814 100%)',
      }}/>
      <div style={{ position: 'absolute', left: '50%', top: '45%', transform: 'translate(-50%, -50%)', fontSize: 200, opacity: 0.05 }}>
        🍫
      </div>

      {/* Top nav — soft cream pills */}
      <div style={{ position: 'relative', zIndex: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 18px' }}>
        <div style={{
          width: 36, height: 36, borderRadius: 999,
          background: 'rgba(251,250,246,0.92)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18, color: SF_C.ink1, fontWeight: 500,
        }}>×</div>
        <div style={{
          padding: '7px 14px',
          borderRadius: 999,
          background: 'rgba(251,250,246,0.92)',
          fontSize: 12, fontWeight: 700, color: SF_C.ink1, letterSpacing: '0.04em',
        }}>SCANNER</div>
        <div style={{
          width: 36, height: 36, borderRadius: 999,
          background: 'rgba(251,250,246,0.92)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 16, color: SF_C.ink1,
        }}>⚡</div>
      </div>

      {/* Scan frame — green corners (brand-tied) */}
      <div style={{ position: 'relative', zIndex: 2, flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ position: 'relative', width: 260, height: 180 }}>
          {[
            { top: 0, left: 0, borderTop: `3px solid ${SF_C.green100}`, borderLeft: `3px solid ${SF_C.green100}` },
            { top: 0, right: 0, borderTop: `3px solid ${SF_C.green100}`, borderRight: `3px solid ${SF_C.green100}` },
            { bottom: 0, left: 0, borderBottom: `3px solid ${SF_C.green100}`, borderLeft: `3px solid ${SF_C.green100}` },
            { bottom: 0, right: 0, borderBottom: `3px solid ${SF_C.green100}`, borderRight: `3px solid ${SF_C.green100}` },
          ].map((s, i) => (
            <div key={i} style={{ position: 'absolute', width: 32, height: 32, ...s }}/>
          ))}
          <div style={{
            position: 'absolute',
            left: 8, right: 8, top: '50%', height: 2,
            background: `linear-gradient(90deg, transparent 0%, ${SF_C.green100} 20%, #fff 50%, ${SF_C.green100} 80%, transparent 100%)`,
            boxShadow: `0 0 14px ${SF_C.green500}`,
          }}/>
          <div style={{
            position: 'absolute',
            top: 'calc(100% + 18px)', left: 0, right: 0,
            textAlign: 'center',
            fontSize: 13, fontWeight: 500, color: 'rgba(255,255,255,0.85)',
          }}>Barcode in den Rahmen halten</div>
        </div>
      </div>

      {/* Footer — cream chrome */}
      <div style={{ position: 'relative', zIndex: 2, padding: '16px 20px 22px' }}>
        <div style={{
          background: 'rgba(251,250,246,0.92)',
          borderRadius: 14,
          padding: '12px 14px',
          display: 'flex', alignItems: 'center', gap: 12,
          color: SF_C.ink1,
        }}>
          <div style={{ width: 32, height: 32, borderRadius: 8, background: SF_C.bgAlt, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>⌨</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: SF_C.ink1 }}>Barcode manuell eingeben</div>
            <div style={{ fontSize: 11, color: SF_C.ink3 }}>Falls dein Code nicht erkannt wird</div>
          </div>
          <div style={{ fontSize: 18, color: SF_C.ink3 }}>›</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S2.5 — Detection / Routing screen
// ("Erkannt: Lebensmittel" mit Korrektur-Option)
// ─────────────────────────────────────────────────────────────
function S25_Detection({ detectedType = 'food', product }) {
  const TYPE_META = {
    food:      { label: 'Lebensmittel', ico: '🥕', desc: 'wir prüfen Nährwerte, Zucker und Verarbeitungsgrad' },
    clothing:  { label: 'Kleidung',     ico: '👕', desc: 'wir prüfen Material, Lieferkette und Langlebigkeit' },
    cosmetics: { label: 'Kosmetik',     ico: '🧴', desc: 'wir prüfen Inhaltsstoffe, Mikroplastik und Tierversuche' },
  };
  const t = TYPE_META[detectedType];
  const otherTypes = Object.keys(TYPE_META).filter(k => k !== detectedType);

  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      color: SF_C.ink1,
    }}>
      <ScreenNav title="Erkennung"/>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 28px' }}>
        {/* Pulse / Detection animation */}
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{
            width: 110, height: 110, borderRadius: '50%',
            background: `radial-gradient(circle, ${SF_C.green50} 0%, ${SF_C.bg} 70%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 18px',
            position: 'relative',
          }}>
            <div style={{
              position: 'absolute', inset: -8, borderRadius: '50%',
              border: `2px solid ${SF_C.green500}`, opacity: 0.25,
            }}/>
            <div style={{ fontSize: 50 }}>{t.ico}</div>
          </div>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 6 }}>
            Erkannt
          </div>
          <div style={{
            fontFamily: "'Instrument Serif', serif",
            fontSize: 36, lineHeight: 1.1, letterSpacing: '-0.02em',
            color: SF_C.ink1, marginBottom: 8,
          }}>{t.label}</div>
          <div style={{ fontSize: 14, color: SF_C.ink2, lineHeight: 1.5, maxWidth: 280, margin: '0 auto' }}>
            {t.desc}
          </div>
        </div>

        {/* Loading dots (pretend we're loading the right module) */}
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{ fontSize: 12, color: SF_C.ink3, marginBottom: 8 }}>
            Lade kategorie-spezifische Bewertung …
          </div>
          <div style={{ display: 'inline-flex', gap: 4 }}>
            {[0, 1, 2].map(i => (
              <div key={i} style={{ width: 6, height: 6, borderRadius: '50%', background: SF_C.green500, opacity: 0.4 }}/>
            ))}
          </div>
        </div>

        {/* Correction CTA */}
        <div style={{
          background: SF_C.card,
          border: `1px solid ${SF_C.borderSoft}`,
          borderRadius: 14,
          padding: '12px 14px',
          fontSize: 13, color: SF_C.ink2, lineHeight: 1.5,
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.06em', color: SF_C.ink3, marginBottom: 6, textTransform: 'uppercase' }}>
            Falsche Kategorie?
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {otherTypes.map(k => (
              <button key={k} style={{
                padding: '7px 12px',
                borderRadius: 999,
                background: SF_C.bgAlt,
                border: `1px solid ${SF_C.borderSoft}`,
                color: SF_C.ink1,
                fontSize: 12, fontWeight: 600, fontFamily: 'inherit',
                cursor: 'pointer',
                display: 'inline-flex', alignItems: 'center', gap: 6,
              }}>
                <span>{TYPE_META[k].ico}</span>
                {TYPE_META[k].label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S5 — Not Found (light)
// ─────────────────────────────────────────────────────────────
function S5_NotFound() {
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

Object.assign(window, { S1_HomeLight, S2_ScannerLight, S25_Detection, S5_NotFound });
