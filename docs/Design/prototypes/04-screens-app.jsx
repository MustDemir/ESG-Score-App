/* =============================================================
   ScanFair — Phase 2.4 App
   Multi-Kategorie: 3 Result-Screens (food/clothing/cosmetics) auf Canvas
   Tweak: Demo-Produkt umschalten + Secondary-Bar-Variante
   ============================================================= */

const { useState } = React;

const APP24_TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "secondaryVariant": "linear",
  "demoProduct": "all"
}/*EDITMODE-END*/;

const FOOD = window.SCANFAIR_DEMO_BY_TYPE.food;
const CLOTHING = window.SCANFAIR_DEMO_BY_TYPE.clothing;
const COSMETICS = window.SCANFAIR_DEMO_BY_TYPE.cosmetics;

function PhoneFrame({ children }) {
  return (
    <IOSDevice width={400} height={840}>
      <IOSStatusBar/>
      <div style={{ height: 'calc(100% - 50px)', overflow: 'hidden' }}>
        {children}
      </div>
    </IOSDevice>
  );
}

function PhoneFrameDark({ children }) {
  return (
    <IOSDevice width={400} height={840} dark>
      <IOSStatusBar dark/>
      <div style={{ height: 'calc(100% - 50px)', overflow: 'hidden' }}>
        {children}
      </div>
    </IOSDevice>
  );
}

function OverviewBoard() {
  return (
    <div style={{
      background: '#fff', height: '100%',
      padding: '40px 48px',
      fontFamily: "'Inter', sans-serif", color: SF_C.ink1, boxSizing: 'border-box',
    }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: SF_C.green500, marginBottom: 12 }}>
        Phase 2.4 · Multi-Kategorie-Architektur
      </div>
      <div style={{
        fontFamily: "'Instrument Serif', serif",
        fontSize: 48, lineHeight: 1.1, letterSpacing: '-0.025em',
        color: SF_C.ink1, marginBottom: 16, maxWidth: 760,
      }}>
        Scan → Erkennung → der richtige Result-Screen.
      </div>
      <div style={{ fontSize: 15, color: SF_C.ink2, lineHeight: 1.55, maxWidth: 720, marginBottom: 24 }}>
        Drei Kategorien für MVP: <strong>Lebensmittel</strong>, <strong>Kleidung</strong>, <strong>Kosmetik</strong>.
        Nach dem Scan erkennt die App automatisch die Kategorie (S2.5) und routet zum passenden Result-Screen.
        Der Begleitbalken hat dieselbe Skala-Logik (rot links → grün rechts), aber kategorie-spezifischen Inhalt:
        Gesundheit / Material &amp; Pflege / Inhaltsstoffe. In Details-Screen kommt eine Checkliste mit ✓/✗-Items dazu.
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
        {[
          { ico: '🥕', t: 'Lebensmittel', s: 'GEPA Bio-Schoko', bar: 'Gesundheit',         d: 'Nutri-Score · Zucker · NOVA' },
          { ico: '👕', t: 'Kleidung',     s: 'Armedangels T-Shirt', bar: 'Material & Pflege', d: 'Naturfaser · Mikroplastik · Reparierbar' },
          { ico: '🧴', t: 'Kosmetik',     s: 'Weleda Shampoo',   bar: 'Inhaltsstoffe',     d: 'Mikroplastik · Silikone · Tierversuche' },
        ].map((c, i) => (
          <div key={i} style={{
            padding: '18px 18px 16px',
            border: `1px solid ${SF_C.borderSoft}`,
            borderRadius: 14,
            background: SF_C.bg,
          }}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>{c.ico}</div>
            <div style={{ fontSize: 15, fontWeight: 700, color: SF_C.ink1, marginBottom: 4 }}>{c.t}</div>
            <div style={{ fontSize: 12, color: SF_C.ink3, marginBottom: 10 }}>Demo: {c.s}</div>
            <div style={{ display: 'inline-block', padding: '4px 8px', background: SF_C.green50, color: SF_C.green600, borderRadius: 6, fontSize: 11, fontWeight: 700, marginBottom: 8 }}>
              {c.bar}
            </div>
            <div style={{ fontSize: 11, color: SF_C.ink2, lineHeight: 1.5 }}>{c.d}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function AppTweaks({ tweaks, setTweak }) {
  return (
    <TweaksPanel title="ScanFair Tweaks">
      <TweakSection label="Secondary-Bar (Health/Material/Inhaltsstoffe)">
        <TweakRadio
          label="Variante"
          value={tweaks.secondaryVariant}
          options={[
            { label: 'Linear',  value: 'linear' },
            { label: 'Diskret', value: 'discrete' },
            { label: 'Minimal', value: 'minimal' },
          ]}
          onChange={(v) => setTweak('secondaryVariant', v)}
        />
      </TweakSection>
    </TweaksPanel>
  );
}

function App() {
  const [tweaks, setTweak] = useTweaks(APP24_TWEAK_DEFAULTS);
  const sv = tweaks.secondaryVariant;

  return (
    <>
      <DesignCanvas
        title="ScanFair · Phase 2.4 — Multi-Kategorie"
        subtitle="Helle Theme · 3 Result-Screens (Food/Clothing/Cosmetics) · Erkennungsscreen"
        defaultTool="hand"
      >
        <DCSection id="overview" title="Überblick — Multi-Kategorie für MVP">
          <DCArtboard id="ov" label="Phase 2.4 — Drei Kategorien, ein einheitliches Score-System" width={920} height={520}>
            <OverviewBoard/>
          </DCArtboard>
        </DCSection>

        <DCSection id="flow" title="Kern-Flow: Scan → Erkennung → Ergebnis">
          <DCArtboard id="s1" data-screen-label="S1 Home (hell)" label="S1 — Home (hell)" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S1_HomeLight/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s2" data-screen-label="S2 Scanner" label="S2 — Kamera-Scan" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrameDark><S2_ScannerLight/></PhoneFrameDark>
            </div>
          </DCArtboard>
          <DCArtboard id="s25-food" data-screen-label="S2.5 Erkennung Food" label="S2.5 — Erkennung: Lebensmittel" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S25_Detection detectedType="food"/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s25-clothing" data-screen-label="S2.5 Erkennung Clothing" label="S2.5 — Erkennung: Kleidung" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S25_Detection detectedType="clothing"/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s25-cosmetics" data-screen-label="S2.5 Erkennung Cosmetics" label="S2.5 — Erkennung: Kosmetik" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S25_Detection detectedType="cosmetics"/></PhoneFrame>
            </div>
          </DCArtboard>
        </DCSection>

        <DCSection id="results" title="Result-Screens — Eine Logik, drei Inhalte">
          <DCArtboard id="s3a" data-screen-label="S3a Food Result" label="S3a — Lebensmittel · GEPA Bio-Schoko" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S3_Result product={FOOD} secondaryVariant={sv}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s3b" data-screen-label="S3b Clothing Result" label="S3b — Kleidung · Armedangels T-Shirt" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S3_Result product={CLOTHING} secondaryVariant={sv}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s3c" data-screen-label="S3c Cosmetics Result" label="S3c — Kosmetik · Weleda Shampoo" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S3_Result product={COSMETICS} secondaryVariant={sv}/></PhoneFrame>
            </div>
          </DCArtboard>
        </DCSection>

        <DCSection id="details" title="Detail-Screens — mit Checkliste">
          <DCArtboard id="s4a" data-screen-label="S4a Food Details" label="S4a — Lebensmittel · Details" width={420} height={1000}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S4_Details product={FOOD} secondaryVariant={sv}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s4b" data-screen-label="S4b Clothing Details" label="S4b — Kleidung · Details" width={420} height={1000}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S4_Details product={CLOTHING} secondaryVariant={sv}/></PhoneFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="s4c" data-screen-label="S4c Cosmetics Details" label="S4c — Kosmetik · Details" width={420} height={1000}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S4_Details product={COSMETICS} secondaryVariant={sv}/></PhoneFrame>
            </div>
          </DCArtboard>
        </DCSection>

        <DCSection id="edge" title="Edge-State">
          <DCArtboard id="s5" data-screen-label="S5 Not Found" label="S5 — Nicht gefunden" width={420} height={880}>
            <div style={{ background: SF_C.bgAlt, height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PhoneFrame><S5_NotFound/></PhoneFrame>
            </div>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>
      <AppTweaks tweaks={tweaks} setTweak={setTweak}/>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
