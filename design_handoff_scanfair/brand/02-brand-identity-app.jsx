/* eslint-disable */
/* global React */
const { useState, useMemo } = React;

// ═══════════════════════════════════════════════════════════════
// SCANFAIR — BRAND IDENTITY SHEET (Phase 2.1)
// ═══════════════════════════════════════════════════════════════

// ────────────────────────────────────────────────────────────────
// SHARED PRIMITIVES
// ────────────────────────────────────────────────────────────────

function Card({ children, style, ...rest }) {
  return (
    <div style={{
      background: 'var(--sf-bg-card)',
      border: '1px solid var(--sf-border)',
      borderRadius: 'var(--sf-radius-lg)',
      padding: 28,
      boxShadow: 'var(--sf-shadow-sm)',
      ...style,
    }} {...rest}>{children}</div>
  );
}

function Eyebrow({ children, color = 'var(--sf-green-500)' }) {
  return <div className="sf-eyebrow" style={{ color, marginBottom: 8 }}>{children}</div>;
}

function Swatch({ name, hex, varName, fg = '#fff', size = 'md' }) {
  const heights = { sm: 56, md: 80, lg: 120 };
  return (
    <div style={{
      borderRadius: 12, overflow: 'hidden',
      border: '1px solid var(--sf-border)',
      background: '#fff',
    }}>
      <div style={{ background: hex, height: heights[size], display: 'flex', alignItems: 'flex-end', padding: 12 }}>
        <div style={{ color: fg, fontSize: 12, fontFamily: 'var(--sf-font-mono)', fontWeight: 600 }}>{hex}</div>
      </div>
      <div style={{ padding: '10px 12px' }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--sf-ink-1)', fontFamily: 'var(--sf-font-sans)' }}>{name}</div>
        {varName && <div style={{ fontSize: 11, color: 'var(--sf-ink-3)', fontFamily: 'var(--sf-font-mono)', marginTop: 2 }}>{varName}</div>}
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 01 — COVER
// ────────────────────────────────────────────────────────────────

function Cover() {
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: 'linear-gradient(140deg, #0F7B5C 0%, #074A36 60%, #042A1E 100%)',
      color: '#FBFAF6', overflow: 'hidden',
      fontFamily: 'var(--sf-font-sans)',
    }}>
      {/* Decorative grain */}
      <div style={{
        position: 'absolute', inset: 0, opacity: 0.06, mixBlendMode: 'overlay',
        backgroundImage: `radial-gradient(circle at 20% 30%, #fff 1px, transparent 1px), radial-gradient(circle at 70% 80%, #fff 1px, transparent 1px)`,
        backgroundSize: '80px 80px, 60px 60px',
      }}/>
      {/* Decorative leaf SVG */}
      <svg viewBox="0 0 600 600" style={{
        position: 'absolute', right: -100, top: -80, width: 540, height: 540, opacity: 0.10,
      }}>
        <path d="M300 50 C 180 80, 100 200, 100 320 C 100 460, 200 540, 300 540 C 400 540, 500 460, 500 320 C 500 200, 420 80, 300 50 Z M300 100 C 240 100, 180 220, 180 320"
          stroke="#fff" strokeWidth="2" fill="none"/>
      </svg>

      <div style={{ position: 'absolute', top: 60, left: 80, right: 80 }}>
        <div style={{
          display: 'inline-block', padding: '6px 12px',
          background: 'rgba(255,255,255,0.12)', borderRadius: 999,
          fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase',
        }}>Phase 2 · Brand Identity</div>
      </div>

      <div style={{ position: 'absolute', bottom: 80, left: 80, right: 80 }}>
        <div style={{
          fontFamily: 'var(--sf-font-display)', fontSize: 96, lineHeight: 1, letterSpacing: '-0.02em',
          fontWeight: 400, marginBottom: 16,
        }}>ScanFair<span style={{ fontStyle: 'italic', opacity: 0.7 }}>.</span></div>
        <div style={{ fontSize: 22, fontWeight: 300, opacity: 0.85, maxWidth: 600, lineHeight: 1.3 }}>
          Eine Designsprache für transparenten Konsum —<br/>
          warm, vertrauensvoll, sachlich.
        </div>
        <div style={{ marginTop: 40, display: 'flex', gap: 32, flexWrap: 'wrap', fontSize: 12, opacity: 0.7, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
          <span>Forest Green · #0F7B5C</span>
          <span>Instrument Serif + Inter</span>
          <span>Ampel + 0–10 · Hybrid-Score</span>
          <span>Light · iOS-first</span>
        </div>
        <div style={{ marginTop: 16, fontSize: 11, opacity: 0.5, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
          Datenfundiert · Werte aus Hausarbeit-Folien abgeleitet
        </div>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 02 — BRAND ESSENCE
// ────────────────────────────────────────────────────────────────

function BrandEssence() {
  // Werte direkt aus deiner Hausarbeit abgeleitet — keine erfundenen Wörter.
  const pillars = [
    { word: 'Transparenz', sub: '„Eine App, drei Dimensionen, unendlich viel Transparenz."', src: 'Folien-Headline · Kernfunktionen', icon: 'fa-eye' },
    { word: 'Vertrauen',   sub: '„Vertrauenswürdige Quellen" — Pain-Reliever gegen Greenwashing-Angst.', src: 'Value Proposition Canvas', icon: 'fa-shield-halved' },
    { word: 'Empowerment', sub: '„Informierte Entscheidungen treffen" — der Nutzer behält die Hoheit.', src: 'User Story · Klaus', icon: 'fa-hand-holding-heart' },
    { word: 'Einfachheit', sub: '„Einfach, intuitiv, nahtlos in die Customer Journey integriert."', src: 'Folien-Headline · UX', icon: 'fa-circle-check' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', padding: '60px 80px', boxSizing: 'border-box',
      background: 'var(--sf-bg)', fontFamily: 'var(--sf-font-sans)', overflow: 'hidden',
    }}>
      <Eyebrow>01 · Brand Essence</Eyebrow>
      <h1 className="sf-display" style={{ fontSize: 64, marginTop: 4, marginBottom: 12 }}>
        Vier Werte, <span className="sf-display-italic">aus deiner Hausarbeit</span> abgeleitet.
      </h1>
      <p className="sf-body-md" style={{ fontSize: 18, maxWidth: 760, color: 'var(--sf-ink-2)', marginBottom: 40 }}>
        Keine erfundenen Brand-Pillars. Jeder Wert ist eine direkte Antwort auf eine Aussage aus
        deinen Folien — Customer Journey, Value Proposition Canvas oder User Stories.
        Diese vier tragen jede UX-, Copy- und Designentscheidung.
      </p>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 20 }}>
        {pillars.map((p, i) => (
          <div key={p.word} style={{
            background: '#fff', border: '1px solid var(--sf-border)', borderRadius: 16,
            padding: 28, boxShadow: 'var(--sf-shadow-sm)', minHeight: 220,
            display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
            position: 'relative', overflow: 'hidden',
          }}>
            <div style={{
              position: 'absolute', top: -20, right: -20, width: 80, height: 80,
              borderRadius: '50%', background: 'var(--sf-green-50)',
            }}/>
            <div style={{
              width: 48, height: 48, borderRadius: 12, background: 'var(--sf-green-50)',
              color: 'var(--sf-green-500)', display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative', zIndex: 1,
            }}>
              <i className={`fa-solid ${p.icon}`} style={{ fontSize: 20 }}></i>
            </div>
            <div style={{ position: 'relative', zIndex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: '0.08em', color: 'var(--sf-ink-3)', marginBottom: 4 }}>0{i+1}</div>
              <div className="sf-display" style={{ fontSize: 32, marginBottom: 8, lineHeight: 1 }}>{p.word}</div>
              <div style={{ fontSize: 12, color: 'var(--sf-ink-2)', lineHeight: 1.5, marginBottom: 8 }}>{p.sub}</div>
              <div style={{ fontSize: 10, color: 'var(--sf-green-600)', fontWeight: 600, letterSpacing: '0.04em', textTransform: 'uppercase', borderTop: '1px solid var(--sf-border-soft)', paddingTop: 8 }}>
                <i className="fa-solid fa-link" style={{fontSize: 8, marginRight: 4}}/>Quelle: {p.src}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Voice & Tone — Beispiel direkt aus Hausarbeit */}
      <div style={{ marginTop: 28, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <div style={{ background: 'var(--sf-green-500)', color: '#fff', borderRadius: 16, padding: 24 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12, opacity: 0.7 }}>So sprechen wir ✓</div>
          <ul style={{ margin: 0, paddingLeft: 18, fontSize: 14, lineHeight: 1.7 }}>
            <li>„Dieses Produkt hat Score 6/10. Probieren Sie Alternative X mit Score 9/10." <em style={{opacity: 0.7, fontSize: 11}}>— Hausarbeit, Funktion 2</em></li>
            <li>„Wir konnten keine Daten zur Lieferkette finden."</li>
            <li>„Möchtest du eine Alternative sehen?"</li>
          </ul>
        </div>
        <div style={{ background: '#FEF3C7', color: '#78350F', borderRadius: 16, padding: 24, border: '1px solid #FBBF24' }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12, opacity: 0.7 }}>So nicht ✗</div>
          <ul style={{ margin: 0, paddingLeft: 18, fontSize: 14, lineHeight: 1.7 }}>
            <li>„Dieses Produkt ist schädlich!" <em style={{opacity: 0.7, fontSize: 11}}>(belehrend)</em></li>
            <li>„🚨 ALARM: Hoher CO₂-Wert!" <em style={{opacity: 0.7, fontSize: 11}}>(emotional manipulativ)</em></li>
            <li>„Nachhaltigkeits-Champion freigeschaltet 🏆" <em style={{opacity: 0.7, fontSize: 11}}>(Gamification ohne Substanz)</em></li>
          </ul>
        </div>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 03 — COLOR SYSTEM
// ────────────────────────────────────────────────────────────────

function ColorSystem() {
  return (
    <div style={{
      width: '100%', height: '100%', padding: '60px 80px', boxSizing: 'border-box',
      background: 'var(--sf-bg)', fontFamily: 'var(--sf-font-sans)', overflow: 'auto',
    }}>
      <Eyebrow>02 · Color</Eyebrow>
      <h1 className="sf-display" style={{ fontSize: 64, marginTop: 4, marginBottom: 12 }}>
        Eine Farbe, die <span className="sf-display-italic">Vertrauen</span> trägt.
      </h1>
      <p className="sf-body-md" style={{ fontSize: 18, maxWidth: 760, marginBottom: 40 }}>
        Forest Green ist tief, ruhig, ohne Öko-Klischee. Daneben: drei Pillar-Farben (E·S·G) aus deiner Hausarbeit-Folie,
        ein Hybrid-Score-System (Ampel + 0–10 Zahl), eine warme Erdpalette als Fundament und Status-Farben für UI-Feedback.
      </p>

      {/* Primary */}
      <div style={{ marginBottom: 40 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 16, marginBottom: 16 }}>
          <h2 className="sf-h3" style={{ margin: 0 }}>Primary — Forest Green</h2>
          <div className="sf-meta">9-Stufen-Skala für UI · Hover · Background</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: 8 }}>
          <Swatch name="50"  hex="#E8F2EE" varName="--sf-green-50"  fg="#0F7B5C" size="sm"/>
          <Swatch name="100" hex="#C5DFD3" varName="--sf-green-100" fg="#0F7B5C" size="sm"/>
          <Swatch name="200" hex="#8FC2A8" varName="--sf-green-200" fg="#fff" size="sm"/>
          <Swatch name="400" hex="#3D9B76" varName="--sf-green-400" fg="#fff" size="sm"/>
          <Swatch name="500 ⭐" hex="#0F7B5C" varName="--sf-green-500" size="sm"/>
          <Swatch name="600" hex="#0A6248" varName="--sf-green-600" size="sm"/>
          <Swatch name="700" hex="#074A36" varName="--sf-green-700" size="sm"/>
          <Swatch name="900" hex="#042A1E" varName="--sf-green-900" size="sm"/>
        </div>
      </div>

      {/* Score-System: Ampel + 0-10 Hybrid (aus Hausarbeit) */}
      <div style={{ marginBottom: 40 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 16, marginBottom: 8 }}>
          <h2 className="sf-h3" style={{ margin: 0 }}>Score-System — Ampel + Zahl</h2>
          <div className="sf-meta">Hybrid: 3 Ampelfarben sofort lesbar · 0–10 für Präzision</div>
        </div>
        <p className="sf-meta" style={{ marginBottom: 16, maxWidth: 720 }}>
          Aus deiner Hausarbeit-Folie „User Experience": <em>„ESG Score erscheint (Ampelsystem: Grün/Gelb/Rot)"</em>.
          Wir kombinieren das mit der präziseren 0–10-Skala (z.B. „Score 6/10 → Alternative mit 9/10"),
          damit Klaus eine schnelle Entscheidung trifft <strong>und</strong> Anna nuanciert vergleichen kann.
        </p>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
          <TrafficTier
            color="#0F7B5C"
            light="#E8F2EE"
            dark="#074A36"
            label="Empfehlung"
            range="7.0 – 10"
            sample="9.1"
            desc="Bewusste Wahl. Lieferkette transparent, Bio-/Fair-zertifiziert, niedriger CO₂-Fußabdruck."
          />
          <TrafficTier
            color="#D97706"
            light="#FEF3C7"
            dark="#92400E"
            label="Mit Bedacht"
            range="4.0 – 6.9"
            sample="5.4"
            desc="Brauchbar, aber: bessere Alternativen verfügbar. App schlägt automatisch Optionen vor."
          />
          <TrafficTier
            color="#C2410C"
            light="#FFEDD5"
            dark="#7C2D12"
            label="Vermeiden"
            range="0 – 3.9"
            sample="2.8"
            desc="Hoher Impact oder fehlende Transparenz. Klare Alternativen-Empfehlung Pflicht."
          />
        </div>
      </div>

      {/* E-S-G + Neutrals */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 32 }}>
        <div>
          <h2 className="sf-h3" style={{ marginBottom: 8 }}>E · S · G — Pillar-Farben</h2>
          <div className="sf-meta" style={{ marginBottom: 16 }}>
            Übernommen aus deiner Hausarbeit-Folie „Kernfunktionen — E/S/G-Triangel". Inhalte (CO₂ · Fair Trade · Compliance) folgen in den Hi-Fi-Mockups.
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
            <Swatch name="Environment" hex="#0F7B5C" varName="--sf-score-e" fg="#fff"/>
            <Swatch name="Social"      hex="#C97B5C" varName="--sf-score-s" fg="#fff"/>
            <Swatch name="Governance"  hex="#4F46E5" varName="--sf-score-g" fg="#fff"/>
          </div>
          <div className="sf-meta" style={{ marginTop: 12, lineHeight: 1.5 }}>
            <strong style={{color: 'var(--sf-ink-1)'}}>Hausarbeit-Folie:</strong> E grün, S rot/warm, G blau — wir spiegeln die Logik mit präzisen Werten:
            E = Forest, S = Clay/Terracotta, G = Indigo.
          </div>
        </div>
        <div>
          <h2 className="sf-h3" style={{ marginBottom: 16 }}>Neutrals — Warm Sand</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
            <Swatch name="BG"      hex="#FBFAF6" varName="--sf-bg" fg="#1A2622" size="sm"/>
            <Swatch name="BG Alt"  hex="#F4F2EB" varName="--sf-bg-alt" fg="#1A2622" size="sm"/>
            <Swatch name="Border"  hex="#E5E2D8" varName="--sf-border" fg="#1A2622" size="sm"/>
            <Swatch name="Card"    hex="#FFFFFF" varName="--sf-bg-card" fg="#1A2622" size="sm"/>
            <Swatch name="Ink 3"   hex="#7A857F" varName="--sf-ink-3" fg="#fff" size="sm"/>
            <Swatch name="Ink 2"   hex="#4A5650" varName="--sf-ink-2" fg="#fff" size="sm"/>
            <Swatch name="Ink 1"   hex="#1A2622" varName="--sf-ink-1" fg="#fff" size="sm"/>
            <Swatch name="Deep"    hex="#0E1B17" varName="--sf-bg-deep" fg="#fff" size="sm"/>
          </div>
          <div className="sf-meta" style={{ marginTop: 12 }}>
            Crème- statt reines Weiß. Slate mit Forest-Tint statt neutral grau.
            Warm. Vertrauensvoll. Ohne klinische Sterilität.
          </div>
        </div>
      </div>

      {/* Status */}
      <div style={{ marginTop: 32 }}>
        <h2 className="sf-h3" style={{ marginBottom: 16 }}>Status</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          <StatusChip bg="#DCFCE7" fg="#15803D" label="Success"/>
          <StatusChip bg="#FEF3C7" fg="#B45309" label="Warning"/>
          <StatusChip bg="#FEE2E2" fg="#991B1B" label="Danger"/>
          <StatusChip bg="#DBEAFE" fg="#1E40AF" label="Info"/>
        </div>
      </div>
    </div>
  );
}

function TrafficTier({ color, light, dark, label, range, sample, desc }) {
  return (
    <div style={{
      borderRadius: 16, border: `1px solid ${light}`, overflow: 'hidden', background: '#fff',
      boxShadow: 'var(--sf-shadow-sm)',
    }}>
      {/* Header mit Ampel-Lampe + Score-Zahl */}
      <div style={{
        background: `linear-gradient(135deg, ${color} 0%, ${dark} 100%)`,
        padding: '20px 20px 18px', color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', opacity: 0.85 }}>{label}</div>
          <div style={{ fontFamily: 'var(--sf-font-mono)', fontSize: 12, opacity: 0.85, marginTop: 2 }}>Score {range}</div>
        </div>
        <div style={{ fontFamily: 'var(--sf-font-display)', fontSize: 44, lineHeight: 1, fontWeight: 400 }}>{sample}</div>
      </div>
      {/* Body */}
      <div style={{ padding: '14px 16px', background: '#fff' }}>
        <div style={{ fontSize: 12, color: 'var(--sf-ink-2)', lineHeight: 1.5 }}>{desc}</div>
      </div>
    </div>
  );
}

// (Alte ScoreTier-Komponente entfernt — ersetzt durch TrafficTier oben.)

function StatusChip({ bg, fg, label }) {
  return (
    <div style={{ background: bg, color: fg, borderRadius: 8, padding: '12px 16px', fontSize: 14, fontWeight: 600 }}>
      <i className="fa-solid fa-circle-check" style={{ marginRight: 8 }}></i>{label}
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 04 — TYPOGRAPHY
// ────────────────────────────────────────────────────────────────

function Typography() {
  return (
    <div style={{
      width: '100%', height: '100%', padding: '60px 80px', boxSizing: 'border-box',
      background: 'var(--sf-bg)', fontFamily: 'var(--sf-font-sans)', overflow: 'auto',
    }}>
      <Eyebrow>03 · Typography</Eyebrow>
      <h1 className="sf-display" style={{ fontSize: 64, marginTop: 4, marginBottom: 12 }}>
        Eine <span className="sf-display-italic">Stimme</span>, zwei Schriften.
      </h1>
      <p className="sf-body-md" style={{ fontSize: 18, maxWidth: 720, marginBottom: 40 }}>
        Instrument Serif für Wärme und redaktionellen Charakter. Inter für alles, was funktional sein muss — UI, Daten, Buttons.
      </p>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 40 }}>
        {/* Display */}
        <Card style={{ padding: 36 }}>
          <Eyebrow color="var(--sf-clay)">Display</Eyebrow>
          <div className="sf-display" style={{ fontSize: 88, lineHeight: 1, marginTop: 8, marginBottom: 12 }}>Aa</div>
          <div style={{ fontSize: 22, fontWeight: 600, fontFamily: 'var(--sf-font-display)', color: 'var(--sf-ink-1)' }}>Instrument Serif</div>
          <div className="sf-meta" style={{ marginTop: 8 }}>Variable · 400 Regular · 400 Italic</div>
          <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid var(--sf-border)' }}>
            <div className="sf-display" style={{ fontSize: 32 }}>Transparent.</div>
            <div className="sf-display sf-display-italic" style={{ fontSize: 32, color: 'var(--sf-green-500)' }}>Verständlich.</div>
            <div className="sf-display" style={{ fontSize: 32 }}>Ehrlich.</div>
          </div>
          <div className="sf-meta" style={{ marginTop: 16, lineHeight: 1.5 }}>
            <strong style={{color: 'var(--sf-ink-1)'}}>Einsatz:</strong> Hero-Headlines, Score-Zahlen, Onboarding-Kapitel, redaktionelle Zitate.
            <br/><strong style={{color: 'var(--sf-ink-1)'}}>Nicht für:</strong> Buttons, Forms, Body-Copy, Listen.
          </div>
        </Card>

        {/* Sans */}
        <Card style={{ padding: 36 }}>
          <Eyebrow color="var(--sf-green-500)">UI / Body</Eyebrow>
          <div style={{ fontFamily: 'var(--sf-font-sans)', fontSize: 88, fontWeight: 700, lineHeight: 1, marginTop: 8, marginBottom: 12, color: 'var(--sf-ink-1)', letterSpacing: '-0.02em' }}>Aa</div>
          <div style={{ fontSize: 22, fontWeight: 600, color: 'var(--sf-ink-1)' }}>Inter</div>
          <div className="sf-meta" style={{ marginTop: 8 }}>Variable · 300 / 400 / 500 / 600 / 700</div>
          <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid var(--sf-border)' }}>
            <div style={{ fontSize: 14, fontWeight: 300, color: 'var(--sf-ink-2)' }}>Light — selten, nur Display-Subtitle</div>
            <div style={{ fontSize: 14, fontWeight: 400, color: 'var(--sf-ink-1)' }}>Regular — Body-Copy, Lists</div>
            <div style={{ fontSize: 14, fontWeight: 500, color: 'var(--sf-ink-1)' }}>Medium — Captions, Pills, Meta</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--sf-ink-1)' }}>Semibold — Section-Titles</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--sf-ink-1)' }}>Bold — Buttons, H1-H3</div>
          </div>
        </Card>
      </div>

      {/* Type Scale */}
      <h2 className="sf-h3" style={{ marginBottom: 16 }}>Type Scale (390px iPhone-Frame)</h2>
      <Card style={{ padding: 0, overflow: 'hidden' }}>
        <TypeRow size={48} weight="display" name="Display" usage="Onboarding-Hero" sample="Scanne dein Produkt." font="serif"/>
        <TypeRow size={34} weight={700} name="Large Title" usage="Screen-Titel" sample="Score-Ergebnis"/>
        <TypeRow size={28} weight={700} name="Title 1" usage="S1 Section" sample="Letzte Scans"/>
        <TypeRow size={24} weight={700} name="Title 2" usage="Card-Header" sample="Bio Hafer-Drink"/>
        <TypeRow size={20} weight={600} name="Title 3" usage="Sub-Section" sample="E-Score 7.4"/>
        <TypeRow size={17} weight={600} name="Callout" usage="Buttons · Tab-Bar" sample="Scannen starten"/>
        <TypeRow size={17} weight={400} name="Body MD" usage="Lead-Paragraph" sample="Wir analysieren Lieferkette und Inhaltsstoffe."/>
        <TypeRow size={15} weight={400} name="Body" usage="Standard-Text" sample="Marke · Kategorie · Herkunft"/>
        <TypeRow size={13} weight={500} name="Footnote" usage="Captions · Meta" sample="Datenstand · Quelle: ADEME"/>
        <TypeRow size={11} weight={700} name="Caption / Eyebrow" usage="Über Titeln" sample="HEUTE · 14:32"/>
      </Card>
    </div>
  );
}

function TypeRow({ size, weight, name, usage, sample, font = 'sans' }) {
  const fontFamily = font === 'serif' ? 'var(--sf-font-display)' : 'var(--sf-font-sans)';
  const fontWeight = font === 'serif' ? 400 : weight;
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '120px 80px 1fr 1fr', alignItems: 'center', gap: 16,
      padding: '16px 24px', borderBottom: '1px solid var(--sf-border-soft)',
    }}>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--sf-ink-1)' }}>{name}</div>
        <div style={{ fontSize: 11, fontFamily: 'var(--sf-font-mono)', color: 'var(--sf-ink-3)' }}>{size}px / {weight === 'display' ? '400' : weight}</div>
      </div>
      <div className="sf-meta">{usage}</div>
      <div style={{ fontFamily, fontSize: size, fontWeight, color: 'var(--sf-ink-1)', lineHeight: 1.2, fontStyle: font === 'serif' ? 'normal' : 'normal' }}>
        {sample}
      </div>
      <div className="sf-meta" style={{ fontFamily: 'var(--sf-font-mono)', fontSize: 10 }}>
        {font === 'serif' ? 'Instrument Serif' : 'Inter'}
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 05 — SPACING / RADII / SHADOWS
// ────────────────────────────────────────────────────────────────

function SpacingShadows() {
  return (
    <div style={{
      width: '100%', height: '100%', padding: '60px 80px', boxSizing: 'border-box',
      background: 'var(--sf-bg)', fontFamily: 'var(--sf-font-sans)', overflow: 'auto',
    }}>
      <Eyebrow>04 · Spacing · Radii · Elevation</Eyebrow>
      <h1 className="sf-display" style={{ fontSize: 64, marginTop: 4, marginBottom: 32 }}>
        Die <span className="sf-display-italic">Geometrie</span> der App.
      </h1>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 24 }}>
        <Card>
          <Eyebrow>Spacing — 4pt-Grid</Eyebrow>
          <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              ['1', 4],['2',8],['3',12],['4',16],['5',24],['6',32],['7',40],['8',64],
            ].map(([n, px]) => (
              <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ fontSize: 11, fontFamily: 'var(--sf-font-mono)', color: 'var(--sf-ink-3)', width: 60 }}>--space-{n}</div>
                <div style={{ background: 'var(--sf-green-500)', height: 16, width: px, borderRadius: 2 }}/>
                <div style={{ fontSize: 12, color: 'var(--sf-ink-2)' }}>{px}px</div>
              </div>
            ))}
          </div>
        </Card>

        <Card>
          <Eyebrow>Radii</Eyebrow>
          <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {[
              ['xs', 4], ['sm', 8], ['md', 12], ['lg', 16], ['xl', 20], ['2xl', 28],
            ].map(([n, r]) => (
              <div key={n} style={{ background: 'var(--sf-bg-alt)', borderRadius: r, padding: 16, border: '1px solid var(--sf-border)' }}>
                <div style={{ fontSize: 11, fontFamily: 'var(--sf-font-mono)', color: 'var(--sf-ink-3)' }}>--radius-{n}</div>
                <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--sf-ink-1)', marginTop: 4 }}>{r}px</div>
              </div>
            ))}
          </div>
          <div className="sf-meta" style={{ marginTop: 12, lineHeight: 1.5 }}>
            <strong style={{color:'var(--sf-ink-1)'}}>Cards:</strong> 16/20px<br/>
            <strong style={{color:'var(--sf-ink-1)'}}>Buttons:</strong> 12px<br/>
            <strong style={{color:'var(--sf-ink-1)'}}>Pills:</strong> 999px
          </div>
        </Card>

        <Card>
          <Eyebrow>Elevation — 5 Schichten</Eyebrow>
          <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 16 }}>
            {[
              ['xs', '0 1px 2px rgba(26,38,34,0.04)'],
              ['sm', '0 2px 8px rgba(26,38,34,0.06)'],
              ['md', '0 4px 16px rgba(26,38,34,0.08)'],
              ['lg', '0 12px 32px rgba(26,38,34,0.10)'],
              ['xl', '0 24px 48px rgba(26,38,34,0.14)'],
            ].map(([n, sh]) => (
              <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ background: '#fff', width: 50, height: 36, borderRadius: 8, boxShadow: sh, flexShrink: 0 }}/>
                <div>
                  <div style={{ fontSize: 12, fontFamily: 'var(--sf-font-mono)', color: 'var(--sf-ink-1)', fontWeight: 600 }}>shadow-{n}</div>
                  <div style={{ fontSize: 10, fontFamily: 'var(--sf-font-mono)', color: 'var(--sf-ink-3)' }}>{sh.split('rgba')[0].trim()}</div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 06 — COMPONENT PREVIEW
// ────────────────────────────────────────────────────────────────

function ComponentPreview() {
  return (
    <div style={{
      width: '100%', height: '100%', padding: '60px 80px', boxSizing: 'border-box',
      background: 'var(--sf-bg)', fontFamily: 'var(--sf-font-sans)', overflow: 'auto',
    }}>
      <Eyebrow>05 · Components</Eyebrow>
      <h1 className="sf-display" style={{ fontSize: 64, marginTop: 4, marginBottom: 32 }}>
        Bausteine in <span className="sf-display-italic">Aktion</span>.
      </h1>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        {/* Buttons */}
        <Card>
          <Eyebrow>Buttons</Eyebrow>
          <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 12, alignItems: 'flex-start' }}>
            <button style={btnPrimary}>Scannen starten</button>
            <button style={btnSecondary}>Details ansehen</button>
            <button style={btnGhost}>Überspringen</button>
            <button style={{...btnPrimary, opacity: 0.5, cursor: 'not-allowed'}}>Disabled</button>
          </div>
        </Card>

        {/* Pills + Tags */}
        <Card>
          <Eyebrow>Pills · Tags · Badges</Eyebrow>
          <div style={{ marginTop: 16, display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            <Pill bg="var(--sf-green-50)" fg="var(--sf-green-600)" icon="fa-leaf">Bio</Pill>
            <Pill bg="#FEF3C7" fg="#B45309" icon="fa-clock">In Prüfung</Pill>
            <Pill bg="var(--sf-bg-alt)" fg="var(--sf-ink-2)">Pflanzendrink</Pill>
            <Pill bg="var(--sf-traffic-green)" fg="#fff">Empfehlung · 9.1</Pill>
            <Pill bg="var(--sf-traffic-yellow)" fg="#fff">Mit Bedacht · 5.4</Pill>
            <Pill bg="var(--sf-traffic-red)" fg="#fff">Vermeiden · 2.8</Pill>
            <Pill bg="#DBEAFE" fg="#1E40AF" icon="fa-shield-halved">Fairtrade</Pill>
          </div>
        </Card>

        {/* Score Ring */}
        <Card>
          <Eyebrow>Score-Ring (Hero-Komponente)</Eyebrow>
          <div style={{ marginTop: 24, display: 'flex', justifyContent: 'center' }}>
            <ScoreRing score={7.4} size={180}/>
          </div>
          <div className="sf-meta" style={{ marginTop: 16, lineHeight: 1.5, textAlign: 'center' }}>
            Die <strong style={{color:'var(--sf-ink-1)'}}>zentrale Score-Visualisierung</strong>.<br/>
            3 Varianten kommen in Phase 2.2.
          </div>
        </Card>

        {/* Bottom Nav */}
        <Card>
          <Eyebrow>Bottom Navigation</Eyebrow>
          <div style={{ marginTop: 16, background: '#fff', border: '1px solid var(--sf-border)', borderRadius: 16, padding: '16px 8px', display: 'flex', justifyContent: 'space-around' }}>
            <NavItem icon="fa-house" label="Home" active/>
            <NavItem icon="fa-utensils" label="Planung"/>
            <NavItem icon="fa-chart-line" label="Impact"/>
            <NavItem icon="fa-user" label="Profil"/>
          </div>
          <div className="sf-meta" style={{ marginTop: 12, lineHeight: 1.5 }}>
            4 Reiter — abgestimmt auf Klaus + Thomas + Anna.
          </div>
        </Card>

        {/* Card / List Item */}
        <Card style={{ gridColumn: 'span 2' }}>
          <Eyebrow>Product Card · List Item</Eyebrow>
          <div className="sf-meta" style={{ marginBottom: 12 }}>
            Drei Score-Tiers im Einsatz — Ampel-Farbe + 0–10 Zahl. Sortiert nach Score.
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <ProductRow name="Linsen Beluga Bio" sub="Davert · Hülsenfrüchte" score={9.1}/>
            <ProductRow name="Bio Hafer-Drink" sub="alnatura · Pflanzendrinks" score={7.4}/>
            <ProductRow name="Klassische Vollmilch" sub="Weihenstephan · Milch" score={5.4}/>
            <ProductRow name="Avocado-Hass" sub="Edeka · Frischgemüse" score={2.8}/>
          </div>
        </Card>
      </div>
    </div>
  );
}

const btnPrimary = {
  background: 'var(--sf-green-500)', color: '#fff', border: 'none',
  padding: '14px 24px', borderRadius: 12, fontSize: 15, fontWeight: 600,
  fontFamily: 'var(--sf-font-sans)', cursor: 'pointer',
  boxShadow: '0 4px 12px rgba(15,123,92,0.25)',
};
const btnSecondary = {
  background: 'transparent', color: 'var(--sf-ink-1)', border: '1.5px solid var(--sf-ink-1)',
  padding: '12px 22px', borderRadius: 12, fontSize: 15, fontWeight: 600,
  fontFamily: 'var(--sf-font-sans)', cursor: 'pointer',
};
const btnGhost = {
  background: 'transparent', color: 'var(--sf-ink-3)', border: 'none',
  padding: '12px 8px', fontSize: 14, fontWeight: 500,
  fontFamily: 'var(--sf-font-sans)', cursor: 'pointer',
};

function Pill({ children, bg, fg, icon }) {
  return (
    <span style={{
      background: bg, color: fg, fontFamily: 'var(--sf-font-sans)',
      fontSize: 12, fontWeight: 600, padding: '6px 12px', borderRadius: 999,
      display: 'inline-flex', alignItems: 'center', gap: 6,
    }}>
      {icon && <i className={`fa-solid ${icon}`} style={{ fontSize: 10 }}/>}
      {children}
    </span>
  );
}

function NavItem({ icon, label, active }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
      color: active ? 'var(--sf-green-500)' : 'var(--sf-ink-3)',
      padding: '4px 8px',
    }}>
      <i className={`fa-solid ${icon}`} style={{ fontSize: 18 }}/>
      <span style={{ fontSize: 11, fontWeight: active ? 600 : 500 }}>{label}</span>
    </div>
  );
}

function ScoreRing({ score, size = 180 }) {
  // Hybrid-Ampel: 3 Stufen aus Hausarbeit
  const tier = score >= 7 ? '#0F7B5C' : score >= 4 ? '#D97706' : '#C2410C';
  const tierLabel = score >= 7 ? 'Empfehlung' : score >= 4 ? 'Mit Bedacht' : 'Vermeiden';
  const stroke = 14;
  const radius = (size - stroke) / 2;
  const circ = 2 * Math.PI * radius;
  const dash = (score / 10) * circ;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={radius} stroke="var(--sf-border)" strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={radius} stroke={tier} strokeWidth={stroke} fill="none"
          strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"/>
      </svg>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ fontFamily: 'var(--sf-font-display)', fontSize: size * 0.31, lineHeight: 1, color: 'var(--sf-ink-1)' }}>{score.toFixed(1)}</div>
        <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.08em', color: 'var(--sf-ink-3)', textTransform: 'uppercase', marginTop: 4 }}>von 10</div>
        <div style={{ fontSize: 10, fontWeight: 600, color: tier, marginTop: 4, letterSpacing: '0.04em' }}>{tierLabel}</div>
      </div>
    </div>
  );
}

function ProductRow({ name, sub, score }) {
  const c = score >= 7 ? '#0F7B5C' : score >= 4 ? '#D97706' : '#C2410C';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: 14, background: '#fff', borderRadius: 12, border: '1px solid var(--sf-border)',
    }}>
      <div style={{ width: 48, height: 48, borderRadius: 10, background: 'var(--sf-bg-alt)', flexShrink: 0 }}/>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--sf-ink-1)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{name}</div>
        <div style={{ fontSize: 12, color: 'var(--sf-ink-3)', marginTop: 2 }}>{sub}</div>
      </div>
      <div style={{
        width: 44, height: 44, borderRadius: '50%', background: c,
        color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontWeight: 700, fontSize: 15, flexShrink: 0,
      }}>{score.toFixed(1)}</div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// 07 — APP PREVIEW (Hi-Fi-Vorgeschmack auf S3)
// ────────────────────────────────────────────────────────────────

function AppPreview() {
  return (
    <div style={{
      width: '100%', height: '100%', padding: '40px 80px', boxSizing: 'border-box',
      background: 'linear-gradient(180deg, var(--sf-bg) 0%, var(--sf-bg-alt) 100%)',
      fontFamily: 'var(--sf-font-sans)', overflow: 'hidden', position: 'relative',
    }}>
      <Eyebrow>06 · App-Preview</Eyebrow>
      <h1 className="sf-display" style={{ fontSize: 56, marginTop: 4, marginBottom: 16 }}>
        So fühlt sich <span className="sf-display-italic">ScanFair</span> an.
      </h1>
      <p className="sf-body-md" style={{ fontSize: 16, maxWidth: 480, marginBottom: 0 }}>
        Ein Vorgeschmack: das Score-Ergebnis (S3) — Hero-Screen der App.
        Vollständige Hi-Fi-Mockups aller Screens kommen als Nächstes.
      </p>

      {/* iPhone Mockup */}
      <div style={{ position: 'absolute', right: 80, top: 60, bottom: 60 }}>
        <PhoneMockup/>
      </div>
    </div>
  );
}

function PhoneMockup() {
  return (
    <div style={{
      width: 320, height: 660, background: '#0E1B17', borderRadius: 44,
      padding: 8, boxShadow: '0 40px 80px rgba(14,27,23,0.30)',
    }}>
      <div style={{
        width: '100%', height: '100%', background: 'var(--sf-bg)', borderRadius: 36,
        overflow: 'hidden', position: 'relative', display: 'flex', flexDirection: 'column',
      }}>
        {/* Status bar */}
        <div style={{ padding: '14px 24px 8px', display: 'flex', justifyContent: 'space-between', fontSize: 12, fontWeight: 600, color: 'var(--sf-ink-1)' }}>
          <span>14:32</span>
          <span><i className="fa-solid fa-signal" style={{marginRight: 6}}/><i className="fa-solid fa-wifi" style={{marginRight: 6}}/><i className="fa-solid fa-battery-full"/></span>
        </div>
        {/* Header */}
        <div style={{ padding: '12px 20px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <i className="fa-solid fa-arrow-left" style={{ fontSize: 18, color: 'var(--sf-ink-1)' }}/>
          <i className="fa-regular fa-heart" style={{ fontSize: 18, color: 'var(--sf-ink-1)' }}/>
        </div>
        {/* Product info */}
        <div style={{ padding: '20px 20px 0', textAlign: 'center' }}>
          <div style={{
            width: 80, height: 80, borderRadius: 16, background: 'var(--sf-bg-alt)',
            margin: '0 auto 12px', border: '1px solid var(--sf-border)',
          }}/>
          <div style={{ fontFamily: 'var(--sf-font-display)', fontSize: 22, lineHeight: 1.1, color: 'var(--sf-ink-1)' }}>Bio Hafer-Drink</div>
          <div style={{ fontSize: 12, color: 'var(--sf-ink-3)', marginTop: 4 }}>alnatura · Pflanzendrinks</div>
        </div>
        {/* Score */}
        <div style={{ padding: '24px 0', display: 'flex', justifyContent: 'center' }}>
          <ScoreRing score={7.4} size={150}/>
        </div>
        {/* E/S/G */}
        <div style={{ padding: '0 20px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <MiniScore label="E" score="7.4" color="#0F7B5C"/>
          <MiniScore label="S" score="4.5" color="#C97B5C"/>
          <MiniScore label="G" score="—"   color="#7A857F" muted/>
        </div>
        {/* Insight */}
        <div style={{ margin: '16px 20px 0', padding: 12, background: 'var(--sf-green-50)', borderRadius: 10, fontSize: 11, color: 'var(--sf-green-700)', fontWeight: 600, textAlign: 'center' }}>
          ↗ Besser als 68 % der Kategorie
        </div>
        {/* CTA */}
        <div style={{ padding: '16px 20px' }}>
          <div style={{
            background: 'var(--sf-green-500)', color: '#fff', textAlign: 'center',
            padding: 14, borderRadius: 12, fontSize: 14, fontWeight: 600,
            boxShadow: '0 4px 12px rgba(15,123,92,0.25)',
          }}>Details ansehen</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ width: 100, height: 4, background: 'var(--sf-ink-1)', borderRadius: 2, margin: '0 auto 8px' }}/>
      </div>
    </div>
  );
}

function MiniScore({ label, score, color, muted }) {
  return (
    <div style={{
      background: '#fff', border: '1px solid var(--sf-border)', borderRadius: 10,
      padding: '10px 6px', textAlign: 'center',
    }}>
      <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--sf-ink-3)', letterSpacing: '0.1em' }}>{label}</div>
      <div style={{ fontFamily: 'var(--sf-font-display)', fontSize: 22, color: muted ? 'var(--sf-ink-3)' : color, marginTop: 2, lineHeight: 1 }}>{score}</div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// MAIN APP
// ────────────────────────────────────────────────────────────────

function App() {
  return (
    <DesignCanvas
      title="ScanFair · Phase 2.1 — Brand Identity"
      subtitle="Forest Green · Instrument Serif + Inter · Light · iOS-first"
    >
      <DCSection id="cover" title="00 — Cover">
        <DCArtboard id="cover-1" label="ScanFair Brand Cover" width={1280} height={720}>
          <Cover/>
        </DCArtboard>
      </DCSection>

      <DCSection id="essence" title="01 — Brand Essence">
        <DCArtboard id="essence-1" label="Vier Werte · Voice & Tone" width={1280} height={920}>
          <BrandEssence/>
        </DCArtboard>
      </DCSection>

      <DCSection id="color" title="02 — Color System">
        <DCArtboard id="color-1" label="Primary · Ampel-Score · E/S/G · Neutrals · Status" width={1280} height={1180}>
          <ColorSystem/>
        </DCArtboard>
      </DCSection>

      <DCSection id="type" title="03 — Typography">
        <DCArtboard id="type-1" label="Instrument Serif + Inter · Type Scale" width={1280} height={1280}>
          <Typography/>
        </DCArtboard>
      </DCSection>

      <DCSection id="spacing" title="04 — Spacing · Radii · Elevation">
        <DCArtboard id="spacing-1" label="4pt-Grid · 6 Radii · 5 Shadows" width={1280} height={680}>
          <SpacingShadows/>
        </DCArtboard>
      </DCSection>

      <DCSection id="components" title="05 — Components">
        <DCArtboard id="comp-1" label="Buttons · Pills · Score-Ring · Nav · Cards" width={1280} height={1100}>
          <ComponentPreview/>
        </DCArtboard>
      </DCSection>

      <DCSection id="preview" title="06 — App-Preview">
        <DCArtboard id="prev-1" label="Hi-Fi Vorgeschmack: S3 Score-Ergebnis" width={1280} height={780}>
          <AppPreview/>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
