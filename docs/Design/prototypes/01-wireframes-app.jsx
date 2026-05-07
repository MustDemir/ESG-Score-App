// ScanFair — Phase 1 Wireframes
// Lo-Fi wireframes, sitemap, user flow for all screens
// Pure grayscale: no colors yet (visual identity comes in Phase 2)

const { useState } = React;

// ═══════════════════════════════════════════════════════════════
// WIREFRAME PRIMITIVES — keep visual style consistent
// ═══════════════════════════════════════════════════════════════

const WF_GRAY_50 = '#FAFAF9';
const WF_GRAY_100 = '#F4F4F2';
const WF_GRAY_200 = '#E7E7E2';
const WF_GRAY_300 = '#D4D4CE';
const WF_GRAY_400 = '#A8A8A0';
const WF_GRAY_500 = '#737370';
const WF_GRAY_700 = '#3E3E3B';
const WF_GRAY_900 = '#1A1A18';

const wfFont = { fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif' };

// Box: a placeholder content area
function WfBox({ height = 40, label, dashed = false, fill = WF_GRAY_100, children, style = {} }) {
  return (
    <div style={{
      ...wfFont,
      width: '100%',
      minHeight: height,
      background: fill,
      border: dashed ? `1.5px dashed ${WF_GRAY_400}` : `1px solid ${WF_GRAY_200}`,
      borderRadius: 8,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: WF_GRAY_500, fontSize: 11, letterSpacing: 0.3, textTransform: 'uppercase',
      padding: 8, boxSizing: 'border-box',
      ...style,
    }}>
      {children || label}
    </div>
  );
}

// Annotation label (red explanatory note)
function WfNote({ children, style = {} }) {
  return (
    <div style={{
      ...wfFont, fontSize: 10, color: '#B91C1C',
      fontStyle: 'italic', letterSpacing: 0.2, lineHeight: 1.4,
      paddingLeft: 16, position: 'relative',
      ...style,
    }}>
      <span style={{ position: 'absolute', left: 0 }}>↳</span>
      {children}
    </div>
  );
}

// iPhone-shaped wireframe device (simplified, no colors)
function WfPhone({ children, label, annotations = [] }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
      <div style={{
        ...wfFont, fontSize: 11, fontWeight: 600, color: WF_GRAY_700,
        letterSpacing: 0.5, textTransform: 'uppercase',
      }}>{label}</div>
      <div style={{
        width: 320, height: 660, background: '#fff',
        border: `2px solid ${WF_GRAY_700}`, borderRadius: 36,
        position: 'relative', overflow: 'hidden',
        boxShadow: '0 4px 24px rgba(0,0,0,0.08)',
      }}>
        {/* notch */}
        <div style={{
          position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
          width: 100, height: 22, background: WF_GRAY_900, borderRadius: 12, zIndex: 10,
        }} />
        {/* status bar */}
        <div style={{
          padding: '12px 24px 4px', display: 'flex', justifyContent: 'space-between',
          ...wfFont, fontSize: 11, fontWeight: 600, color: WF_GRAY_700,
        }}>
          <span>9:41</span>
          <span style={{ width: 100 }}/>
          <span>•••</span>
        </div>
        {/* screen content */}
        <div style={{
          padding: '20px 16px', height: 'calc(100% - 50px)', overflow: 'hidden',
          display: 'flex', flexDirection: 'column', gap: 12,
        }}>
          {children}
        </div>
      </div>
      {annotations.length > 0 && (
        <div style={{ width: 320, display: 'flex', flexDirection: 'column', gap: 4, marginTop: 4 }}>
          {annotations.map((a, i) => <WfNote key={i}>{a}</WfNote>)}
        </div>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// INDIVIDUAL WIREFRAMES
// ═══════════════════════════════════════════════════════════════

function WfOnboarding1() {
  return (
    <WfPhone label="Onboarding 1 — Was ist ESG?" annotations={[
      'Großes visuelles Element (Phase 2: Illustration)',
      'Klare Headline + 1-Satz-Erklärung',
      'Skip-Link rechts oben für Power-User',
    ]}>
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <WfBox height={28} fill="transparent" style={{ width: 60, border: 'none' }}>SKIP</WfBox>
      </div>
      <WfBox height={200} label="Hero-Illustration" />
      <WfBox height={32} label="Headline (24pt Bold)" fill={WF_GRAY_200} />
      <WfBox height={60} label="Body-Text (3 Zeilen)" />
      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
        <div style={{ width: 24, height: 6, background: WF_GRAY_700, borderRadius: 3 }}/>
        <div style={{ width: 6, height: 6, background: WF_GRAY_300, borderRadius: 3 }}/>
        <div style={{ width: 6, height: 6, background: WF_GRAY_300, borderRadius: 3 }}/>
      </div>
      <WfBox height={48} label="WEITER →" fill={WF_GRAY_700} style={{ color: '#fff', fontSize: 13 }} />
    </WfPhone>
  );
}

function WfOnboarding2() {
  return (
    <WfPhone label="Onboarding 2 — Wie funktioniert's?" annotations={[
      '3 Steps visualisiert: Scan → Score → Entscheidung',
      'Vertrauensformel: "Wir aggregieren — wir erfinden nicht"',
    ]}>
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <WfBox height={28} fill="transparent" style={{ width: 60, border: 'none' }}>SKIP</WfBox>
      </div>
      <WfBox height={32} label="Headline" fill={WF_GRAY_200} />
      <div style={{ display: 'flex', gap: 12 }}>
        <WfBox height={80} label="① Scan" />
        <WfBox height={80} label="② Score" />
        <WfBox height={80} label="③ Entscheid." />
      </div>
      <WfBox height={70} label="Vertrauens-Statement" dashed />
      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
        <div style={{ width: 6, height: 6, background: WF_GRAY_300, borderRadius: 3 }}/>
        <div style={{ width: 24, height: 6, background: WF_GRAY_700, borderRadius: 3 }}/>
        <div style={{ width: 6, height: 6, background: WF_GRAY_300, borderRadius: 3 }}/>
      </div>
      <WfBox height={48} label="WEITER →" fill={WF_GRAY_700} style={{ color: '#fff', fontSize: 13 }} />
    </WfPhone>
  );
}

function WfOnboarding3() {
  return (
    <WfPhone label="Onboarding 3 — Datenschutz" annotations={[
      'DSGVO-by-Design als Verkaufsargument',
      'Keine Account-Erstellung nötig im MVP',
      'Letzter Screen → CTA „Loslegen"',
    ]}>
      <WfBox height={32} label="Headline" fill={WF_GRAY_200} />
      <WfBox height={80} label="Lock/Shield Icon" />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <WfBox height={36} label="✓ Keine personenbez. Daten" />
        <WfBox height={36} label="✓ EU-gehostet (Supabase FRA)" />
        <WfBox height={36} label="✓ Kein Tracking, kein Login" />
      </div>
      <WfBox height={50} label="Sprach-Toggle DE / EN" dashed />
      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
        <div style={{ width: 6, height: 6, background: WF_GRAY_300, borderRadius: 3 }}/>
        <div style={{ width: 6, height: 6, background: WF_GRAY_300, borderRadius: 3 }}/>
        <div style={{ width: 24, height: 6, background: WF_GRAY_700, borderRadius: 3 }}/>
      </div>
      <WfBox height={48} label="LOSLEGEN →" fill={WF_GRAY_700} style={{ color: '#fff', fontSize: 13 }} />
    </WfPhone>
  );
}

function WfHome() {
  return (
    <WfPhone label="S1 — Home / Scanner" annotations={[
      'Hero: Scan-Button als zentrale Action (≥ 60% des Screens above the fold)',
      'Suchfeld als Alternative für User die nicht scannen wollen',
      'Letzte Scans = sozialer Anker, zeigt App in Benutzung',
      'Bottom-Nav: Home / Favoriten (Phase 2) / Vergleich (Phase 2) / Mehr',
    ]}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <WfBox height={32} fill="transparent" style={{ width: 110, border: 'none', justifyContent: 'flex-start', fontWeight: 700, color: WF_GRAY_900, fontSize: 18 }}>SCANFAIR</WfBox>
        <WfBox height={32} fill="transparent" style={{ width: 32, border: 'none' }}>⚙</WfBox>
      </div>
      <WfBox height={36} label="🔍  Produkt suchen oder Code eingeben" />
      <WfBox height={170} dashed>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 70, height: 70, borderRadius: '50%', border: `3px solid ${WF_GRAY_700}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28 }}>📷</div>
          <div style={{ fontSize: 11, fontWeight: 600 }}>BARCODE SCANNEN</div>
          <div style={{ fontSize: 9, color: WF_GRAY_400, textTransform: 'none' }}>Tap zum Starten</div>
        </div>
      </WfBox>
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 4px 0' }}>
        <span style={{ ...wfFont, fontSize: 10, fontWeight: 600, color: WF_GRAY_700, letterSpacing: 0.5 }}>LETZTE SCANS</span>
        <span style={{ ...wfFont, fontSize: 10, color: WF_GRAY_500 }}>Alle ansehen →</span>
      </div>
      <WfBox height={50} label="Produkt-Karte 1 (Bild · Name · Score)" />
      <WfBox height={50} label="Produkt-Karte 2" />
      <WfBox height={50} label="Produkt-Karte 3" />
      <div style={{ flex: 1 }} />
      <WfBox height={50} fill={WF_GRAY_50} style={{ borderRadius: 0, borderLeft: 'none', borderRight: 'none', borderBottom: 'none' }}>
        <div style={{ display: 'flex', justifyContent: 'space-around', width: '100%', fontSize: 9 }}>
          <span style={{ color: WF_GRAY_900, fontWeight: 600 }}>HOME</span>
          <span style={{ color: WF_GRAY_400 }}>FAVORITEN</span>
          <span style={{ color: WF_GRAY_400 }}>VERGLEICH</span>
          <span style={{ color: WF_GRAY_400 }}>MEHR</span>
        </div>
      </WfBox>
    </WfPhone>
  );
}

function WfScanner() {
  return (
    <WfPhone label="S2 — Kamera / Scan" annotations={[
      'Vollbild-Kamera im Hintergrund',
      'Scan-Frame zentriert mit animierter Linie',
      'Torch-Toggle für schlechte Lichtverhältnisse',
      'Manuell-eingeben Fallback unten',
      'Abbrechen-Button immer erreichbar',
    ]}>
      <div style={{
        position: 'absolute', inset: 0, background: WF_GRAY_900, opacity: 0.85,
        margin: 0,
      }}/>
      <div style={{ position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', height: '100%', gap: 12, padding: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 0 0 0' }}>
          <WfBox height={32} fill="rgba(255,255,255,0.15)" style={{ width: 80, border: '1px solid rgba(255,255,255,0.3)', color: '#fff' }}>← ABBR.</WfBox>
          <WfBox height={32} fill="rgba(255,255,255,0.15)" style={{ width: 50, border: '1px solid rgba(255,255,255,0.3)', color: '#fff' }}>💡</WfBox>
        </div>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{
            width: 240, height: 180, border: '2px solid rgba(255,255,255,0.7)',
            borderRadius: 12, position: 'relative',
          }}>
            <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: 1.5, background: '#fff', transform: 'translateY(-50%)' }}/>
            {/* corner brackets */}
            {[
              {top: -1, left: -1, borderTop: '4px solid #fff', borderLeft: '4px solid #fff'},
              {top: -1, right: -1, borderTop: '4px solid #fff', borderRight: '4px solid #fff'},
              {bottom: -1, left: -1, borderBottom: '4px solid #fff', borderLeft: '4px solid #fff'},
              {bottom: -1, right: -1, borderBottom: '4px solid #fff', borderRight: '4px solid #fff'},
            ].map((s, i) => <div key={i} style={{ position: 'absolute', width: 24, height: 24, ...s }}/>)}
          </div>
        </div>
        <WfBox height={36} fill="rgba(255,255,255,0.15)" style={{ border: '1px solid rgba(255,255,255,0.3)', color: '#fff' }}>RICHTE BARCODE IM RAHMEN AUS</WfBox>
        <WfBox height={42} fill="rgba(255,255,255,0.95)" style={{ color: WF_GRAY_900 }}>⌨ MANUELL EINGEBEN</WfBox>
      </div>
    </WfPhone>
  );
}

function WfScoreResult() {
  return (
    <WfPhone label="S3 — Score-Ergebnis ⭐ HERO-SCREEN" annotations={[
      'Ist DAS Herz der App — größter Designaufwand in Phase 2',
      'Score-Kreis: groß, sofort erfassbar, Ampel-Farbe',
      'Vertrauens-Badge: "Hohe Datenqualität · 85%" zusätzlich zur Score-Ampel',
      'Drei E/S/G-Tiles als sekundäre Info',
      'Kategorie-Vergleich als sozialer Anker',
      'Tap auf Tiles → Details (S4)',
    ]}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <WfBox height={28} fill="transparent" style={{ width: 30, border: 'none' }}>←</WfBox>
        <WfBox height={28} fill="transparent" style={{ width: 30, border: 'none' }}>♡</WfBox>
        <WfBox height={28} fill="transparent" style={{ width: 30, border: 'none' }}>↗</WfBox>
      </div>
      <div style={{ display: 'flex', gap: 10 }}>
        <WfBox height={70} fill={WF_GRAY_200} style={{ width: 70, flex: 'none' }}>IMG</WfBox>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4, justifyContent: 'center' }}>
          <WfBox height={20} label="Produktname" fill="transparent" style={{ border: 'none', justifyContent: 'flex-start', fontSize: 14, color: WF_GRAY_900 }}/>
          <WfBox height={14} label="Marke · Kategorie" fill="transparent" style={{ border: 'none', justifyContent: 'flex-start', fontSize: 10 }}/>
        </div>
      </div>
      <WfBox height={170} dashed style={{ flexDirection: 'column', gap: 6 }}>
        <div style={{ width: 110, height: 110, borderRadius: '50%', border: `4px solid ${WF_GRAY_700}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28, fontWeight: 700, color: WF_GRAY_900 }}>7.4</div>
        <div style={{ fontSize: 10, fontWeight: 600 }}>GESAMT-SCORE · 🟢 GUT</div>
      </WfBox>
      <WfBox height={28} dashed fill={WF_GRAY_50} style={{ fontSize: 9, textTransform: 'none' }}>
        🛡  Hohe Datenqualität · 85% Datenpunkte vorhanden
      </WfBox>
      <div style={{ display: 'flex', gap: 8 }}>
        <WfBox height={70} label={<div style={{textAlign:'center'}}>🌱<br/>E: 7.4</div>} />
        <WfBox height={70} label={<div style={{textAlign:'center'}}>👥<br/>S: 4.5</div>} />
        <WfBox height={70} label={<div style={{textAlign:'center'}}>🏛<br/>G: --</div>} dashed />
      </div>
      <WfBox height={36} fill={WF_GRAY_100} style={{ fontSize: 9, textTransform: 'none' }}>
        ↗ Besser als 68% der Kategorie „Pflanzendrinks"
      </WfBox>
      <WfBox height={42} label="DETAILS ANSEHEN →" fill={WF_GRAY_700} style={{ color: '#fff', fontSize: 11 }}/>
    </WfPhone>
  );
}

function WfScoreDetails() {
  return (
    <WfPhone label="S4 — Score-Details (lange Scrollseite)" annotations={[
      'Scrollbar — alles auf einer Seite (deine Wahl)',
      'Reihenfolge: E (40%) → S (35%) → G (25%) → Quellen',
      'Pro Sub-Score: Balken + Punkte + Gewichtung + Quellenangabe',
      'Fehlende Daten = gepunkteter Balken + „Keine Daten"',
    ]}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <WfBox height={28} fill="transparent" style={{ width: 30, border: 'none' }}>←</WfBox>
        <WfBox height={28} fill="transparent" style={{ width: 60, border: 'none', fontSize: 9 }}>METHODIK</WfBox>
      </div>
      <WfBox height={28} fill={WF_GRAY_200} style={{ fontSize: 12, fontWeight: 700, color: WF_GRAY_900 }}>🌱 E-SCORE: 7.4 / 10 (40%)</WfBox>
      <WfBox height={20} label="Eco-Score B (40%) ━━━━━━━━ 8.0" />
      <WfBox height={20} label="CO₂ 0.94kg (25%) ━━━━━━━━ 10" />
      <WfBox height={20} label="Verpackung (15%) ━━ 1.0" dashed/>
      <WfBox height={20} label="Herkunft DE (10%) ━━━━━━━━ 8.0" />
      <WfBox height={20} label="Bio-Siegel (10%) ━━━━━━ 7.0" />
      <WfBox height={28} fill={WF_GRAY_200} style={{ fontSize: 12, fontWeight: 700, color: WF_GRAY_900 }}>👥 S-SCORE: 4.5 / 10 (35%)</WfBox>
      <WfBox height={20} label="Soziale Siegel — keine" dashed/>
      <WfBox height={20} label="Herkunftsland-Risiko: Niedrig" />
      <WfBox height={28} fill={WF_GRAY_100} style={{ fontSize: 11, fontWeight: 600 }}>🏛 G-SCORE — Phase 2</WfBox>
      <WfBox height={36} dashed fill={WF_GRAY_50} style={{ fontSize: 9, textTransform: 'none' }}>
        Quellen: Open Food Facts · ADEME · BAFA · Fairtrade Int.
      </WfBox>
    </WfPhone>
  );
}

function WfNotFound() {
  return (
    <WfPhone label="S5 — Produkt nicht gefunden" annotations={[
      'Empathisch, nicht wie eine Fehlermeldung',
      '3 klare Aktionsmöglichkeiten',
      'Community-Ansatz: User können Produkte melden',
    ]}>
      <div style={{ display: 'flex', justifyContent: 'flex-start' }}>
        <WfBox height={28} fill="transparent" style={{ width: 30, border: 'none' }}>←</WfBox>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 16 }}>
        <WfBox height={100} label="🔍❓ Illustration" />
        <div style={{ textAlign: 'center', ...wfFont }}>
          <div style={{ fontSize: 16, fontWeight: 700, color: WF_GRAY_900, marginBottom: 6 }}>Produkt nicht gefunden</div>
          <div style={{ fontSize: 11, color: WF_GRAY_500, lineHeight: 1.4, padding: '0 20px' }}>Dieser Barcode ist noch nicht in unserer Datenbank — gemeinsam machen wir Lieferketten transparent.</div>
        </div>
      </div>
      <WfBox height={42} label="🔄 ERNEUT SCANNEN" fill={WF_GRAY_700} style={{ color: '#fff', fontSize: 11 }}/>
      <WfBox height={42} label="🔍 MANUELL SUCHEN" fill="transparent" style={{ border: `1.5px solid ${WF_GRAY_700}`, color: WF_GRAY_900, fontSize: 11 }}/>
      <WfBox height={42} label="📨 PRODUKT MELDEN" fill="transparent" style={{ border: `1.5px solid ${WF_GRAY_700}`, color: WF_GRAY_900, fontSize: 11 }}/>
    </WfPhone>
  );
}

function WfPermission() {
  return (
    <WfPhone label="Edge — Kamera-Permission" annotations={[
      'Vor dem nativen iOS-Permission-Dialog erklären WARUM',
      'Dramatisch erhöht Akzeptanzrate (Standard-Pattern)',
    ]}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 16 }}>
        <WfBox height={100} label="📷 Kamera-Icon" />
        <div style={{ textAlign: 'center', ...wfFont }}>
          <div style={{ fontSize: 16, fontWeight: 700, color: WF_GRAY_900, marginBottom: 6 }}>Kamera-Zugriff erlauben</div>
          <div style={{ fontSize: 11, color: WF_GRAY_500, lineHeight: 1.4, padding: '0 20px' }}>Wir brauchen die Kamera nur zum Scannen von Barcodes. Keine Bilder werden gespeichert.</div>
        </div>
      </div>
      <WfBox height={42} label="ERLAUBEN" fill={WF_GRAY_700} style={{ color: '#fff', fontSize: 11 }}/>
      <WfBox height={42} label="NICHT JETZT" fill="transparent" style={{ border: 'none', color: WF_GRAY_500, fontSize: 11 }}/>
    </WfPhone>
  );
}

function WfOffline() {
  return (
    <WfPhone label="Edge — Offline-Modus" annotations={[
      'Hive-Cache zeigt zuletzt gescannte Produkte auch offline',
      'Klare visuelle Sprache: „Du bist offline"',
    ]}>
      <WfBox height={36} fill={WF_GRAY_200} style={{ fontSize: 11, fontWeight: 600, color: WF_GRAY_900 }}>📡 OFFLINE — GESPEICHERTE SCANS VERFÜGBAR</WfBox>
      <WfBox height={36} label="🔍 Produkt suchen (offline)" fill={WF_GRAY_50} dashed/>
      <WfBox height={170} dashed>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
          <div style={{ width: 70, height: 70, borderRadius: '50%', border: `3px dashed ${WF_GRAY_400}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28, color: WF_GRAY_400 }}>📷</div>
          <div style={{ fontSize: 10 }}>SCAN ERFORDERT INTERNET</div>
        </div>
      </WfBox>
      <div style={{ ...wfFont, fontSize: 10, fontWeight: 600, color: WF_GRAY_700, padding: '4px 4px 0', letterSpacing: 0.5 }}>GESPEICHERTE SCANS (CACHE)</div>
      <WfBox height={50} label="Produkt 1 (offline)" />
      <WfBox height={50} label="Produkt 2 (offline)" />
      <WfBox height={50} label="Produkt 3 (offline)" />
    </WfPhone>
  );
}

// ═══════════════════════════════════════════════════════════════
// SITEMAP DIAGRAM (SVG)
// ═══════════════════════════════════════════════════════════════

function Sitemap() {
  const node = (x, y, w, h, label, type = 'screen') => {
    const fills = {
      entry: '#1A1A18',
      screen: '#fff',
      edge: '#FAFAF9',
      future: '#F4F4F2',
    };
    const strokes = {
      entry: '#1A1A18',
      screen: '#3E3E3B',
      edge: '#A8A8A0',
      future: '#A8A8A0',
    };
    const colors = {
      entry: '#fff',
      screen: '#1A1A18',
      edge: '#3E3E3B',
      future: '#737370',
    };
    return (
      <g key={`${x}-${y}`}>
        <rect x={x} y={y} width={w} height={h} rx={10}
          fill={fills[type]} stroke={strokes[type]}
          strokeWidth={type === 'entry' ? 2 : 1.5}
          strokeDasharray={type === 'edge' || type === 'future' ? '4 4' : 'none'}/>
        <foreignObject x={x} y={y} width={w} height={h}>
          <div style={{
            ...wfFont, width: '100%', height: '100%',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 11, fontWeight: 600, color: colors[type], textAlign: 'center',
            padding: 6, boxSizing: 'border-box', lineHeight: 1.3,
          }}>{label}</div>
        </foreignObject>
      </g>
    );
  };
  const arrow = (x1, y1, x2, y2, label) => {
    const mx = (x1 + x2) / 2;
    const my = (y1 + y2) / 2;
    return (
      <g key={`a-${x1}-${y1}-${x2}-${y2}`}>
        <line x1={x1} y1={y1} x2={x2} y2={y2} stroke="#737370" strokeWidth={1.5} markerEnd="url(#arrowhead)"/>
        {label && (
          <foreignObject x={mx - 50} y={my - 10} width={100} height={20}>
            <div style={{ ...wfFont, fontSize: 9, color: '#737370', textAlign: 'center', background: '#fff', padding: '1px 4px', borderRadius: 3 }}>{label}</div>
          </foreignObject>
        )}
      </g>
    );
  };

  return (
    <svg viewBox="0 0 1200 700" style={{ width: '100%', height: 'auto', display: 'block' }}>
      <defs>
        <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
          <polygon points="0 0, 10 3, 0 6" fill="#737370"/>
        </marker>
      </defs>
      {/* Entry */}
      {node(40, 40, 130, 50, 'App-Start', 'entry')}
      {/* Onboarding row */}
      {node(220, 20, 110, 50, 'Onboarding 1\nWas ist ESG?', 'screen')}
      {node(360, 20, 110, 50, 'Onboarding 2\nWie funktioniert?', 'screen')}
      {node(500, 20, 110, 50, 'Onboarding 3\nDatenschutz', 'screen')}
      {arrow(170, 65, 220, 45, 'Erstmalig')}
      {arrow(330, 45, 360, 45)}
      {arrow(470, 45, 500, 45)}
      {/* Home (S1) center */}
      {node(640, 50, 140, 70, 'S1 — Home\n(Scanner-Hero)', 'screen')}
      {arrow(610, 45, 640, 80)}
      {arrow(170, 80, 640, 80, 'Wiederkehrend')}
      {/* Scanner branch */}
      {node(640, 200, 140, 60, 'S2 — Kamera/Scan', 'screen')}
      {arrow(710, 120, 710, 200, 'Scan-Tap')}
      {/* Permission edge */}
      {node(820, 160, 140, 50, 'Kamera-Permission', 'edge')}
      {arrow(780, 215, 820, 190, '1. Mal')}
      {/* Score result S3 */}
      {node(640, 320, 160, 70, 'S3 — Score-Ergebnis\n⭐ HERO', 'screen')}
      {arrow(710, 260, 710, 320, 'gefunden')}
      {/* Not found S5 */}
      {node(420, 320, 160, 60, 'S5 — Produkt\nnicht gefunden', 'edge')}
      {arrow(640, 240, 500, 320, 'nicht gefunden')}
      {arrow(500, 320, 640, 90, 'zurück')}
      {/* Score details S4 */}
      {node(640, 440, 160, 70, 'S4 — Score-Details\n(Scroll)', 'screen')}
      {arrow(720, 390, 720, 440, 'Details ansehen')}
      {/* Stretch features (right side) */}
      {node(870, 320, 140, 50, 'Favoriten\n(Phase 2)', 'future')}
      {node(870, 390, 140, 50, 'Vergleich 2 Prod.\n(Phase 2)', 'future')}
      {node(870, 460, 140, 50, 'Bessere\nAlternative', 'future')}
      {node(870, 530, 140, 50, 'Eigene\nGewichtung', 'future')}
      {node(870, 600, 140, 50, 'Teilen\n(Share)', 'future')}
      {arrow(800, 355, 870, 345)}
      {arrow(800, 365, 870, 415)}
      {arrow(800, 375, 870, 485)}
      {/* Offline edge */}
      {node(220, 200, 140, 60, 'Offline-Modus\n(Hive-Cache)', 'edge')}
      {arrow(640, 75, 360, 220, 'kein Internet')}
      {/* Settings */}
      {node(420, 50, 130, 60, 'Einstellungen\n(Sprache, Info)', 'screen')}
      {arrow(640, 70, 550, 80)}
      {/* Legend */}
      <g>
        <rect x={40} y={580} width={460} height={100} rx={8} fill="#FAFAF9" stroke="#D4D4CE"/>
        <foreignObject x={50} y={585} width={440} height={90}>
          <div style={{ ...wfFont, fontSize: 11, color: '#3E3E3B', padding: 4, lineHeight: 1.6 }}>
            <div style={{ fontWeight: 700, marginBottom: 4 }}>LEGENDE</div>
            <div>⬛ Entry-Point  ·  ⬜ MVP-Screen (Phase 1)  ·  ⬜ Edge/Empty State (gestrichelt)  ·  ⬜ Phase-2-Feature (gepunktet)</div>
            <div style={{ marginTop: 4 }}>→ User-Navigation  ·  Scan-Hero im Zentrum, alles andere ist sekundär</div>
          </div>
        </foreignObject>
      </g>
    </svg>
  );
}

// ═══════════════════════════════════════════════════════════════
// USER FLOW (Decision-Tree)
// ═══════════════════════════════════════════════════════════════

function UserFlow() {
  return (
    <div style={{
      ...wfFont, padding: 24, background: '#fff', borderRadius: 16,
      border: `1px solid ${WF_GRAY_200}`, color: WF_GRAY_900,
    }}>
      <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4, letterSpacing: 0.3 }}>USER-FLOW: HAPPY PATH + EDGE CASES</div>
      <div style={{ fontSize: 12, color: WF_GRAY_500, marginBottom: 20 }}>Linear, mit Decision-Points und Fallbacks</div>
      <pre style={{
        ...wfFont, fontSize: 11, lineHeight: 1.7, color: WF_GRAY_700,
        whiteSpace: 'pre', overflow: 'auto', margin: 0, padding: 16,
        background: WF_GRAY_50, borderRadius: 10, border: `1px solid ${WF_GRAY_200}`,
      }}>
{`  ┌─ App-Start
  │
  ├─ [Erstmalig?] ── ja ──▶ Onboarding 1 → 2 → 3 (Skip möglich)
  │                          │
  └──────────────────────────┴──▶ S1 HOME ◀────────────────┐
                                  │                        │
                                  ├─ [Scan-Tap]            │
                                  │   │                    │
                                  │   ├─ [Kamera-Permission?]
                                  │   │   ├─ nicht gefragt ▶ Permission-Screen
                                  │   │   ├─ erlaubt ──────▶ S2 KAMERA
                                  │   │   └─ verweigert ──▶ Manuell-Eingabe-Sheet
                                  │   │
                                  │   ├─ [Barcode erkannt?]
                                  │   │   ├─ ja ─▶ [Internet?]
                                  │   │   │       ├─ ja ──▶ [API-Call]
                                  │   │   │       │        ├─ 200 + status=1 ──▶ S3 ERGEBNIS
                                  │   │   │       │        ├─ 200 + status=0 ──▶ S5 NICHT GEFUNDEN
                                  │   │   │       │        ├─ Timeout ─────────▶ Retry → ggf. Offline-Fallback
                                  │   │   │       │        └─ 429 Rate-Limit ──▶ Retry × 3, dann Fehler-Toast
                                  │   │   │       └─ nein ─▶ [Cache-Hit?]
                                  │   │   │                ├─ ja ──▶ S3 (Cache-Badge sichtbar)
                                  │   │   │                └─ nein ▶ Offline-Hinweis
                                  │   │   └─ nein/timeout ─▶ Bleibt in S2 mit Hinweis
                                  │
                                  ├─ [Letzten Scan tippen]   ▶ S3 ERGEBNIS (aus Cache)
                                  │
                                  ├─ [Manuelle Suche]        ▶ Suchergebnis-Liste → S3
                                  │
                                  └─ [Settings ⚙]            ▶ Sprache · Methodik · Datenschutz · Über

  S3 ERGEBNIS ──▶ [Details-Tap] ──▶ S4 DETAILS (Scroll)
              │                     │
              ├─ [♡ Favorisieren]   └─ [Methodik-Link] ──▶ Web-View „So bewerten wir"
              ├─ [↗ Teilen]
              ├─ [Bessere Alternative] ──▶ S3 anderes Produkt
              └─ [← zurück]              ──▶ S1 HOME (Historie aktualisiert)`}
      </pre>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// MAIN APP — Compose into Design Canvas
// ═══════════════════════════════════════════════════════════════

function App() {
  return (
    <DesignCanvas
      title="ScanFair · Phase 1 — Wireframes"
      subtitle="Lo-Fi · Information Architecture · User Flow · Mock-Data · 12 Screens"
    >
      <DCSection id="overview" title="00 — Strategischer Überblick">
        <DCArtboard id="ov-info" label="Was du gerade ansiehst" width={920} height={520}>
          <div style={{
            ...wfFont, padding: 40, background: '#fff', height: '100%',
            color: WF_GRAY_900, boxSizing: 'border-box', overflow: 'hidden',
          }}>
            <div style={{ display: 'inline-block', padding: '4px 10px', background: WF_GRAY_900, color: '#fff', fontSize: 10, fontWeight: 700, letterSpacing: 1, borderRadius: 4, marginBottom: 16 }}>PHASE 1 / 4</div>
            <div style={{ fontSize: 36, fontWeight: 700, lineHeight: 1.1, marginBottom: 12, letterSpacing: -0.5 }}>ScanFair Wireframes</div>
            <div style={{ fontSize: 14, color: WF_GRAY_500, marginBottom: 24, lineHeight: 1.5 }}>Bewusst grau — keine Farben, keine Typografie-Spielereien.<br/>Wir klären erst die Struktur, dann die Optik.</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 24 }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: WF_GRAY_700, marginBottom: 8 }}>WAS DU FINDEN WIRST</div>
                <ul style={{ fontSize: 13, color: WF_GRAY_700, lineHeight: 1.7, paddingLeft: 18, margin: 0 }}>
                  <li>Sitemap — alle Screens als Flussdiagramm</li>
                  <li>User-Flow — Happy Path + Edge Cases</li>
                  <li>3× Onboarding-Screens (DSGVO)</li>
                  <li>5× Hauptscreens (S1–S5)</li>
                  <li>2× Edge-States (Permission, Offline)</li>
                  <li>Mock-Produktdatenbank (8 Produkte)</li>
                </ul>
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: WF_GRAY_700, marginBottom: 8 }}>WAS DU JETZT TUN SOLLTEST</div>
                <ul style={{ fontSize: 13, color: WF_GRAY_700, lineHeight: 1.7, paddingLeft: 18, margin: 0 }}>
                  <li><b>Sitemap prüfen</b> — fehlt ein Screen?</li>
                  <li><b>User-Flow lesen</b> — Edge-Case vergessen?</li>
                  <li><b>Wireframes durchklicken</b> — Layouts okay?</li>
                  <li><b>Annotations beachten</b> — rote Notes erklären Designentscheidungen</li>
                  <li><b>Feedback geben</b> — danach: Phase 2 (Hi-Fi Mockups)</li>
                </ul>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, fontSize: 11, color: WF_GRAY_500 }}>
              <span style={{ padding: '4px 8px', background: WF_GRAY_100, borderRadius: 4 }}>Branding: warm/naturnah (folgt in Phase 2)</span>
              <span style={{ padding: '4px 8px', background: WF_GRAY_100, borderRadius: 4 }}>DE/EN</span>
              <span style={{ padding: '4px 8px', background: WF_GRAY_100, borderRadius: 4 }}>Light Mode (MVP)</span>
              <span style={{ padding: '4px 8px', background: WF_GRAY_100, borderRadius: 4 }}>iOS-first</span>
            </div>
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="sitemap" title="01 — Sitemap & Information Architecture">
        <DCArtboard id="sm-1" label="Sitemap (Flussdiagramm)" width={1200} height={720}>
          <div style={{ background: '#fff', padding: 16, height: '100%', boxSizing: 'border-box' }}>
            <Sitemap/>
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="userflow" title="02 — User-Flow">
        <DCArtboard id="uf-1" label="User-Flow Happy Path + Edge Cases" width={920} height={780}>
          <div style={{ padding: 24, background: WF_GRAY_50, height: '100%', boxSizing: 'border-box', overflow: 'auto' }}>
            <UserFlow/>
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="onboarding" title="03 — Onboarding (3 Screens)">
        <DCArtboard id="ob-1" label="Onboarding 1 — Was ist ESG?" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfOnboarding1/></div>
        </DCArtboard>
        <DCArtboard id="ob-2" label="Onboarding 2 — Wie funktioniert's?" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfOnboarding2/></div>
        </DCArtboard>
        <DCArtboard id="ob-3" label="Onboarding 3 — Datenschutz" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfOnboarding3/></div>
        </DCArtboard>
      </DCSection>

      <DCSection id="main" title="04 — Hauptscreens (S1–S5)">
        <DCArtboard id="s1" label="S1 — Home / Scanner" width={400} height={880}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfHome/></div>
        </DCArtboard>
        <DCArtboard id="s2" label="S2 — Kamera / Scan" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfScanner/></div>
        </DCArtboard>
        <DCArtboard id="s3" label="S3 — Score-Ergebnis ⭐ HERO" width={400} height={920}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfScoreResult/></div>
        </DCArtboard>
        <DCArtboard id="s4" label="S4 — Score-Details" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfScoreDetails/></div>
        </DCArtboard>
        <DCArtboard id="s5" label="S5 — Nicht gefunden" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfNotFound/></div>
        </DCArtboard>
      </DCSection>

      <DCSection id="edges" title="05 — Edge States (oft vergessen!)">
        <DCArtboard id="ed-1" label="Kamera-Permission" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfPermission/></div>
        </DCArtboard>
        <DCArtboard id="ed-2" label="Offline-Modus" width={400} height={820}>
          <div style={{ padding: '20px 0', background: WF_GRAY_50, height: '100%' }}><WfOffline/></div>
        </DCArtboard>
      </DCSection>

      <DCSection id="next" title="06 — Wie geht's weiter?">
        <DCArtboard id="next-1" label="Roadmap nach Phase 1" width={920} height={520}>
          <div style={{
            ...wfFont, padding: 40, background: '#fff', height: '100%',
            color: WF_GRAY_900, boxSizing: 'border-box',
          }}>
            <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 24 }}>Was kommt jetzt?</div>
            <div style={{ display: 'grid', gridTemplateColumns: '40px 1fr', gap: '16px 16px', alignItems: 'start' }}>
              <div style={{ width: 32, height: 32, borderRadius: '50%', background: WF_GRAY_900, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: 14 }}>✓</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>Phase 1 — Wireframes (du bist hier)</div>
                <div style={{ fontSize: 12, color: WF_GRAY_500, marginTop: 2 }}>Struktur klären, bevor Design-Entscheidungen anstehen.</div>
              </div>
              <div style={{ width: 32, height: 32, borderRadius: '50%', background: WF_GRAY_300, color: WF_GRAY_900, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: 14 }}>2</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>Phase 2 — Hi-Fi Mockups</div>
                <div style={{ fontSize: 12, color: WF_GRAY_500, marginTop: 2 }}>Brand-Identity (warm/naturnah), Farbsystem, Typografie, alle Screens als pixelperfekte Mockups in iPhone-Frames. 2-3 Variationen für S3 (Hero).</div>
              </div>
              <div style={{ width: 32, height: 32, borderRadius: '50%', background: WF_GRAY_300, color: WF_GRAY_900, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: 14 }}>3</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>Phase 3 — Klickbarer Prototyp</div>
                <div style={{ fontSize: 12, color: WF_GRAY_500, marginTop: 2 }}>Echte Navigation, 8 Mock-Produkte, Tweaks: Score-Visualisierung · Farbschemata · Detail-Level. Du kannst die App durchklicken und Stakeholdern zeigen.</div>
              </div>
              <div style={{ width: 32, height: 32, borderRadius: '50%', background: WF_GRAY_300, color: WF_GRAY_900, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: 14 }}>4</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>Phase 4 — Developer-Handoff</div>
                <div style={{ fontSize: 12, color: WF_GRAY_500, marginTop: 2 }}>Dart-Tokens, State-Diagramme pro Screen, Edge-Case-Liste. Du übergibst das an Claude Code in deinem Repo.</div>
              </div>
            </div>
            <div style={{ marginTop: 28, padding: 16, background: WF_GRAY_50, borderRadius: 10, border: `1px solid ${WF_GRAY_200}` }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, marginBottom: 6 }}>👉 DEIN NÄCHSTER SCHRITT</div>
              <div style={{ fontSize: 13, color: WF_GRAY_700, lineHeight: 1.5 }}>Geh die Wireframes durch. Wenn die <b>Struktur</b> stimmt, sag mir „weiter zu Phase 2". Wenn etwas <b>fehlt</b>, sag's jetzt — Änderungen hier sind günstig, in Phase 2/3 teuer.</div>
            </div>
          </div>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
