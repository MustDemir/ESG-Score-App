/* =============================================================
   ScanFair — Phase 2.4: Result Screens (Multi-Kategorie)
   S3 Result + S4 Details — generisch für food / clothing / cosmetics
   Datenquelle: product.productType, product.secondaryInfo, product.secondaryChecklist
   ============================================================= */

const PROD_DETAILS_BY_TYPE = {
  food: {
    e: [
      { label: 'CO₂-Fußabdruck',     value: '5.8 kg / 100g · ⌀ Kategorie 6.4 kg' },
      { label: 'Bio-Zertifizierung', value: 'EU-Bio + Demeter' },
      { label: 'Verpackung',         value: 'Papier + Aluminium-Inlay' },
      { label: 'Transportweg',       value: 'Ghana → DE · Schiff' },
    ],
    s: [
      { label: 'Faire Löhne',        value: 'Fairtrade + GEPA fair+' },
      { label: 'Lieferkette',        value: 'Direkt aus Kuapa Kokoo Kooperative' },
      { label: 'Arbeitsbedingungen', value: 'Audits jährlich · keine Kinderarbeit' },
    ],
    g: [
      { label: 'Datenqualität',     value: '95% komplett · GEPA-Nachhaltigkeitsbericht' },
      { label: 'Audits',            value: 'FLOCERT · letzte Prüfung 2024' },
      { label: 'Herkunftsnachweis', value: 'Trace-Code auf Verpackung' },
    ],
  },
  clothing: {
    e: [
      { label: 'CO₂-Fußabdruck',     value: '4.2 kg pro Shirt · ⌀ Kategorie 7.5 kg' },
      { label: 'Wasserverbrauch',    value: '900 L (Bio reduziert ~91%)' },
      { label: 'Bio-Baumwolle',      value: 'GOTS-zertifiziert' },
      { label: 'Färbeverfahren',     value: 'GOTS-konform, schadstoffarm' },
    ],
    s: [
      { label: 'Faire Löhne',        value: 'Fair Wear Foundation Mitglied' },
      { label: 'Produktion',         value: 'Portugal — EU-Arbeitsstandards' },
      { label: 'Lieferkette',        value: 'Stoff Türkei (transparent), Garn unklar' },
    ],
    g: [
      { label: 'Datenqualität',     value: '88% komplett · Armedangels Tracker' },
      { label: 'Zertifikate',       value: 'GOTS ✓ · FWF ✓' },
      { label: 'Herkunftsnachweis', value: 'Style-ID-Lookup auf Website' },
    ],
  },
  cosmetics: {
    e: [
      { label: 'CO₂-Fußabdruck',     value: '0.4 kg pro Flasche' },
      { label: 'Verpackung',         value: '100% recyceltes PET' },
      { label: 'Wasser-Footprint',   value: 'Niedrig (Naturkosmetik-Auflagen)' },
    ],
    s: [
      { label: 'Lieferkette',        value: 'Wildrose-Anbau Bulgarien · fair' },
      { label: 'Produktion',         value: 'Schweiz/Deutschland' },
      { label: 'Tierversuche',       value: 'Frei (NATRUE + EU-Verbot)' },
    ],
    g: [
      { label: 'Datenqualität',     value: '93% komplett · Weleda Transparenzbericht' },
      { label: 'Zertifikate',       value: 'NATRUE ✓ · vegan ✓' },
      { label: 'INCI-Liste',        value: 'Vollständig veröffentlicht' },
    ],
  },
};

// ─────────────────────────────────────────────────────────────
// S3 — Score-Result (universell für alle Kategorien)
// ─────────────────────────────────────────────────────────────
function S3_Result({ product, secondaryVariant = 'linear' }) {
  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      overflow: 'auto',
    }}>
      <ScreenNav title="Ergebnis"/>
      <ProductCard product={product}/>
      <ScoreHero esg={product.esg}/>
      <ScoreBars esg={product.esg}/>
      <SecondaryBar info={product.secondaryInfo} variant={secondaryVariant}/>
      <ScoreCTAs/>
      <MethodFootnote product={product}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// S4 — Score-Details (universell)
// ─────────────────────────────────────────────────────────────
function S4_Details({ product, secondaryVariant = 'linear' }) {
  const details = PROD_DETAILS_BY_TYPE[product.productType] || PROD_DETAILS_BY_TYPE.food;
  return (
    <div style={{
      background: SF_C.bg,
      height: '100%',
      display: 'flex', flexDirection: 'column',
      fontFamily: "'Inter', sans-serif",
      overflow: 'auto',
    }}>
      <ScreenNav title="Details &amp; Quellen"/>
      <ProductCard product={product} compact/>

      {/* Tab switch */}
      <div style={{ padding: '4px 20px 12px' }}>
        <div style={{
          display: 'flex',
          background: SF_C.bgAlt,
          padding: 4, borderRadius: 12, gap: 4,
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

      <ScoreBars esg={product.esg} expandable defaultExpanded="e" productDetails={details}/>
      <SecondaryBar info={product.secondaryInfo} variant={secondaryVariant}/>
      <SecondaryChecklist title={`${product.secondaryInfo.title} im Detail`} items={product.secondaryChecklist}/>
      <MethodFootnote product={product}/>
    </div>
  );
}

Object.assign(window, { S3_Result, S4_Details, PROD_DETAILS_BY_TYPE });
