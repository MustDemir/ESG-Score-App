/* =============================================================
   ScanFair — Phase 3: Klickbarer Prototyp
   - Screen-Router mit Hotspots (transparente Overlays)
   - Onboarding → Home → Scanner → Detection → Result → Details
   - Tweaks: Demo-Produkt · Secondary-Variante · Start-Screen · Reset
   ============================================================= */

const { useState, useEffect, useRef } = React;

const PROTO_TWEAKS = /*EDITMODE-BEGIN*/{
  "demoProduct": "food",
  "secondaryVariant": "linear",
  "startScreen": "o1",
  "showHotspots": false
}/*EDITMODE-END*/;

const PRODUCT_BY_KEY = {
  food:      window.SCANFAIR_DEMO_BY_TYPE.food,
  clothing:  window.SCANFAIR_DEMO_BY_TYPE.clothing,
  cosmetics: window.SCANFAIR_DEMO_BY_TYPE.cosmetics,
};

// ─────────────────────────────────────────────────────────────
// Hotspot overlay — transparente Klick-Region
// ─────────────────────────────────────────────────────────────
function Hotspot({ top, left, width, height, onClick, label, show }) {
  return (
    <div
      onClick={onClick}
      style={{
        position: 'absolute',
        top, left, width, height,
        cursor: 'pointer',
        zIndex: 50,
        background: show ? 'rgba(15,123,92,0.18)' : 'transparent',
        border: show ? '2px dashed rgba(15,123,92,0.7)' : 'none',
        borderRadius: 12,
        display: show ? 'flex' : 'block',
        alignItems: 'center', justifyContent: 'center',
        color: '#0F7B5C', fontSize: 11, fontWeight: 700,
        textTransform: 'uppercase', letterSpacing: '0.06em',
        pointerEvents: 'auto',
      }}
    >{show && label}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// Auto-advance helper (für Scanner & Detection)
// ─────────────────────────────────────────────────────────────
function useAutoAdvance(ms, fn, deps = []) {
  useEffect(() => {
    const t = setTimeout(fn, ms);
    return () => clearTimeout(t);
    // eslint-disable-next-line
  }, deps);
}

// Keyboard shortcuts: ← back, → forward (best-effort), ESC = home
function useKeyboardNav(onBack) {
  useEffect(() => {
    const h = (e) => {
      if (e.key === 'Escape' || e.key === 'Backspace' || e.key === 'ArrowLeft') {
        onBack();
      }
    };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [onBack]);
}

// ─────────────────────────────────────────────────────────────
// Per-screen hotspot configurations
// Coords sind relativ zum Inhaltsbereich (innerhalb IOS-Frame, unterhalb Statusbar)
// ─────────────────────────────────────────────────────────────
function HotspotsFor({ screen, go, back, show, productKey }) {
  const product = PRODUCT_BY_KEY[productKey];
  const detectedType = product.productType; // 'food' | 'clothing' | 'cosmetics'

  switch (screen) {
    case 'o1':
      return (
        <>
          <Hotspot show={show} label="Loslegen" top={690} left={22} width={356} height={56} onClick={() => go('o2')}/>
          <Hotspot show={show} label="Skip" top={760} left={120} width={160} height={28} onClick={() => go('home')}/>
        </>
      );
    case 'o2':
      return (
        <>
          <Hotspot show={show} label="Weiter" top={690} left={22} width={356} height={56} onClick={() => go('o3')}/>
          <Hotspot show={show} label="Skip" top={760} left={120} width={160} height={28} onClick={() => go('home')}/>
        </>
      );
    case 'o3':
      return (
        <Hotspot show={show} label="Ersten Scan starten" top={710} left={22} width={356} height={56} onClick={() => go('home')}/>
      );
    case 'home':
      return (
        <>
          <Hotspot show={show} label="Barcode scannen" top={170} left={24} width={352} height={88} onClick={() => go('scanner')}/>
          <Hotspot show={show} label="Recent Scans (zum Result)" top={510} left={24} width={352} height={170} onClick={() => go('result')}/>
        </>
      );
    case 'scanner':
      return null; // auto-advance handled in render
    case 'detection':
      return null; // auto-advance handled in render
    case 'result':
      return (
        <>
          <Hotspot show={show} label="Details & Quellen" top={420} left={24} width={352} height={56} onClick={() => go('details')}/>
          <Hotspot show={show} label="Alternativen" top={680} left={24} width={352} height={56} onClick={() => go('result')}/>
          <Hotspot show={show} label="Zurück" top={6} left={6} width={86} height={36} onClick={back}/>
        </>
      );
    case 'details':
      return (
        <Hotspot show={show} label="Zurück" top={6} left={6} width={86} height={36} onClick={back}/>
      );
    case 'notfound':
    case 'offline':
    case 'lowdata':
      return (
        <Hotspot show={show} label="Zurück" top={6} left={6} width={86} height={36} onClick={back}/>
      );
    default:
      return null;
  }
}

// ─────────────────────────────────────────────────────────────
// Screen renderer
// ─────────────────────────────────────────────────────────────
function ScreenRender({ screen, productKey, secondaryVariant, go }) {
  const product = PRODUCT_BY_KEY[productKey];

  // Auto-advance flow stages
  if (screen === 'scanner') {
    return <AutoAdvanceScreen key="scanner" ms={1600} onAdvance={() => go('detection')} render={() => <S2_ScannerLight/>}/>;
  }
  if (screen === 'detection') {
    return <AutoAdvanceScreen key="detection" ms={1400} onAdvance={() => go('result')} render={() => <S25_Detection detectedType={product.productType}/>}/>;
  }

  switch (screen) {
    case 'o1':       return <O1_Welcome/>;
    case 'o2':       return <O2_How/>;
    case 'o3':       return <O3_Trust/>;
    case 'home':     return <S1_HomeLight/>;
    case 'result':   return <S3_Result product={product} secondaryVariant={secondaryVariant}/>;
    case 'details':  return <S4_Details product={product} secondaryVariant={secondaryVariant}/>;
    case 'notfound': return <S5_NotFound/>;
    case 'offline':  return <E1_Offline/>;
    case 'lowdata':  return <E2_LowData product={product}/>;
    default:         return <O1_Welcome/>;
  }
}

function AutoAdvanceScreen({ ms, onAdvance, render }) {
  useAutoAdvance(ms, onAdvance, []);
  return render();
}

// ─────────────────────────────────────────────────────────────
// Phone shell with screen + hotspot overlay
// ─────────────────────────────────────────────────────────────
function PrototypePhone({ screen, productKey, secondaryVariant, showHotspots, go, back }) {
  const dark = screen === 'scanner';
  return (
    <IOSDevice width={400} height={840} dark={dark}>
      <IOSStatusBar dark={dark}/>
      <div style={{ position: 'relative', height: 'calc(100% - 50px)', overflow: 'hidden' }}>
        <ScreenRender screen={screen} productKey={productKey} secondaryVariant={secondaryVariant} go={go}/>
        <HotspotsFor screen={screen} go={go} back={back} show={showHotspots} productKey={productKey}/>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Flow-Map (Sidebar — zeigt aktuellen Screen + History)
// ─────────────────────────────────────────────────────────────
const SCREEN_LABELS = {
  o1: 'O1 · Willkommen',
  o2: 'O2 · Wie funktioniert\'s',
  o3: 'O3 · Datenquellen',
  home: 'S1 · Home',
  scanner: 'S2 · Scanner',
  detection: 'S2.5 · Erkennung',
  result: 'S3 · Result',
  details: 'S4 · Details',
  notfound: 'S5 · Nicht gefunden',
  offline: 'E1 · Offline',
  lowdata: 'E2 · Datengrundlage',
};

const FLOW_GROUPS = [
  { title: 'Onboarding', keys: ['o1', 'o2', 'o3'] },
  { title: 'Scan-Flow',  keys: ['home', 'scanner', 'detection', 'result', 'details'] },
  { title: 'Edge-States', keys: ['notfound', 'offline', 'lowdata'] },
];

function FlowSidebar({ current, history, onJump }) {
  return (
    <div style={{
      background: '#fff',
      borderRadius: 16,
      padding: '20px 22px',
      width: 260,
      border: '1px solid #EFEDE5',
      fontFamily: "'Inter', sans-serif",
      color: '#1A2622',
    }}>
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#0F7B5C', marginBottom: 8 }}>
        Prototyp · Flow
      </div>
      <div style={{ fontFamily: "'Instrument Serif', serif", fontSize: 22, lineHeight: 1.1, letterSpacing: '-0.02em', marginBottom: 4 }}>
        Tippe Hotspots,<br/>
        <em style={{ color: '#0F7B5C' }}>folge dem Flow.</em>
      </div>
      <div style={{ fontSize: 11.5, color: '#7A857F', lineHeight: 1.5, marginBottom: 18 }}>
        ESC oder ← für Zurück. Hotspots sichtbar machen via Tweaks.
      </div>

      {FLOW_GROUPS.map(g => (
        <div key={g.title} style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', color: '#7A857F', marginBottom: 6 }}>
            {g.title}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            {g.keys.map(k => {
              const active = k === current;
              const visited = history.includes(k);
              return (
                <button key={k}
                  onClick={() => onJump(k)}
                  style={{
                    textAlign: 'left',
                    padding: '8px 10px',
                    border: 'none',
                    borderRadius: 8,
                    background: active ? '#E8F2EE' : visited ? '#F4F2EB' : 'transparent',
                    color: active ? '#0A6248' : '#1A2622',
                    fontSize: 12.5, fontWeight: active ? 700 : 500,
                    fontFamily: 'inherit',
                    cursor: 'pointer',
                    display: 'flex', alignItems: 'center', gap: 8,
                  }}>
                  <div style={{
                    width: 6, height: 6, borderRadius: '50%',
                    background: active ? '#0F7B5C' : visited ? '#94B864' : '#E5E2D8',
                    flexShrink: 0,
                  }}/>
                  {SCREEN_LABELS[k]}
                </button>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Header strip
// ─────────────────────────────────────────────────────────────
function ProtoHeader({ current, productKey, onReset }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '20px 32px',
      borderBottom: '1px solid #EFEDE5',
      background: 'rgba(251,250,246,0.94)',
      backdropFilter: 'blur(12px)',
      position: 'sticky', top: 0, zIndex: 100,
    }}>
      <div>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#0F7B5C', marginBottom: 2 }}>
          Phase 3 · Klickbarer Prototyp
        </div>
        <div style={{ fontFamily: "'Instrument Serif', serif", fontSize: 22, color: '#1A2622', letterSpacing: '-0.01em' }}>
          ScanFair — Flow-Test
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ fontSize: 11, color: '#7A857F', fontWeight: 600 }}>
          {SCREEN_LABELS[current]} · Demo: <span style={{ color: '#1A2622' }}>{productKey}</span>
        </div>
        <button onClick={onReset} style={{
          padding: '8px 14px',
          background: '#fff', border: '1px solid #EFEDE5',
          borderRadius: 10,
          fontSize: 12, fontWeight: 600,
          fontFamily: 'inherit',
          color: '#1A2622', cursor: 'pointer',
        }}>↻ Reset</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Tweaks Panel
// ─────────────────────────────────────────────────────────────
function ProtoTweaks({ tweaks, setTweak }) {
  return (
    <TweaksPanel title="ScanFair · Prototyp">
      <TweakSection label="Demo-Produkt">
        <TweakRadio
          label="Kategorie"
          value={tweaks.demoProduct}
          options={[
            { label: 'Food',     value: 'food' },
            { label: 'Kleidung', value: 'clothing' },
            { label: 'Kosmetik', value: 'cosmetics' },
          ]}
          onChange={(v) => setTweak('demoProduct', v)}
        />
      </TweakSection>

      <TweakSection label="Secondary-Bar">
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

      <TweakSection label="Start-Screen">
        <TweakSelect
          label="Beim Reset starten bei"
          value={tweaks.startScreen}
          options={Object.keys(SCREEN_LABELS).map(k => ({ label: SCREEN_LABELS[k], value: k }))}
          onChange={(v) => setTweak('startScreen', v)}
        />
      </TweakSection>

      <TweakSection label="Hotspots">
        <TweakToggle
          label="Klick-Regionen anzeigen"
          value={tweaks.showHotspots}
          onChange={(v) => setTweak('showHotspots', v)}
        />
      </TweakSection>
    </TweaksPanel>
  );
}

// ─────────────────────────────────────────────────────────────
// Root
// ─────────────────────────────────────────────────────────────
function PrototypeApp() {
  const [tweaks, setTweak] = useTweaks(PROTO_TWEAKS);
  const [current, setCurrent] = useState(tweaks.startScreen || 'o1');
  const [history, setHistory] = useState([tweaks.startScreen || 'o1']);

  const go = (screen) => {
    setHistory(h => [...h, screen]);
    setCurrent(screen);
  };
  const back = () => {
    setHistory(h => {
      if (h.length <= 1) return h;
      const next = h.slice(0, -1);
      setCurrent(next[next.length - 1]);
      return next;
    });
  };
  const reset = () => {
    const s = tweaks.startScreen || 'o1';
    setCurrent(s);
    setHistory([s]);
  };
  const jump = (k) => {
    setCurrent(k);
    setHistory(h => [...h, k]);
  };

  useKeyboardNav(back);

  return (
    <div style={{ minHeight: '100vh', background: '#F4F2EB' }}>
      <ProtoHeader current={current} productKey={tweaks.demoProduct} onReset={reset}/>

      <div style={{
        display: 'flex', gap: 32,
        justifyContent: 'center', alignItems: 'flex-start',
        padding: '40px 32px 80px',
      }}>
        <FlowSidebar current={current} history={history} onJump={jump}/>

        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
          <PrototypePhone
            screen={current}
            productKey={tweaks.demoProduct}
            secondaryVariant={tweaks.secondaryVariant}
            showHotspots={tweaks.showHotspots}
            go={go}
            back={back}
          />
          <div style={{
            display: 'flex', gap: 8,
            fontSize: 11.5, color: '#7A857F', fontFamily: "'Inter', sans-serif",
          }}>
            <kbd style={{ padding: '3px 8px', background: '#fff', border: '1px solid #EFEDE5', borderRadius: 6, fontFamily: 'inherit', fontWeight: 600 }}>ESC</kbd>
            <span>oder</span>
            <kbd style={{ padding: '3px 8px', background: '#fff', border: '1px solid #EFEDE5', borderRadius: 6, fontFamily: 'inherit', fontWeight: 600 }}>←</kbd>
            <span>Zurück</span>
          </div>
        </div>

        <div style={{ width: 260 }}/>
      </div>

      <ProtoTweaks tweaks={tweaks} setTweak={setTweak}/>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<PrototypeApp/>);
