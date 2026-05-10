// ScanFair Mock-Produktdatenbank
// MVP: 3 Kategorien — Lebensmittel, Kleidung, Kosmetik
// Two-Score-Modell:
//   esg.* = Hauptscore (3 Säulen E/S/G), Zahl + Verdict
//   secondaryInfo.* = Kategorie-spezifischer Begleithinweis (kein Score)
//                     Einheitliche Skala 0–10 (links=ungünstig=rot → rechts=günstig=grün)
//   secondaryChecklist.* = Diskrete ✓/✗-Items mit Quellen — nur in S4 Details
//
// productType: "food" | "clothing" | "cosmetics"
// secondaryInfo.title: Header-Label des Balkens ("Gesundheit" / "Material & Pflege" / "Inhaltsstoffe")
// secondaryInfo.position (0–10): Position auf der Skala — INTERN, nicht angezeigt.
// secondaryInfo.barLeft / barRight: Beschriftungen der Skala-Enden
// secondaryInfo.label: das Wort, das angezeigt wird
// secondaryInfo.facts: knappe Faktenzeile unter dem Balken

window.SCANFAIR_PRODUCTS = [
  // ───────── LEBENSMITTEL ─────────
  {
    barcode: "4006381333924",
    productType: "food",
    product_name: "Hafermilch Bio Barista",
    brand: "Oatly",
    category: "Pflanzendrinks",
    image_emoji: "🥛",
    ecoscore_grade: "B",
    co2_total: 0.94,
    packaging: "Tetra Pak (Verbund)",
    origin: "Deutschland",
    labels: ["EU-Bio"],
    social_labels: [],
    esg: {
      e: 7.4, s: 4.5, g: 5.0, total: 5.9,
      verdict: "yellow", verdict_label: "Mit Bedacht",
      tagline: "Bio, aber Tetra Pak und unklare Lieferkette."
    },
    secondaryInfo: {
      title: "Gesundheit",
      position: 6.0,
      barLeft: "ungünstig",
      barRight: "nährstoffreich",
      label: "ausgewogen",
      facts: "Nutri-Score B · Zucker 7g/100ml · NOVA 4 (verarbeitet)"
    },
    secondaryChecklist: [
      { ok: true,  label: "Nutri-Score B",         note: "Source: Open Food Facts" },
      { ok: true,  label: "Wenig zugesetzter Zucker", note: "7g/100ml — unter Schnitt" },
      { ok: false, label: "Stark verarbeitet",       note: "NOVA-Klasse 4" },
      { ok: true,  label: "Bio-Hafer",               note: "EU-Bio-zertifiziert" },
    ],
    data_completeness: 0.85, data_quality: "high"
  },
  {
    barcode: "4000417025005",
    productType: "food",
    product_name: "Bio Edelbitter Schokolade",
    brand: "GEPA",
    category: "Schokolade",
    image_emoji: "🍫",
    ecoscore_grade: "C",
    co2_total: 5.8,
    packaging: "Papier + Aluminium",
    origin: "Ghana",
    labels: ["EU-Bio", "Demeter"],
    social_labels: ["Fairtrade", "GEPA fair+"],
    esg: {
      e: 6.2, s: 8.7, g: 7.5, total: 7.4,
      verdict: "green", verdict_label: "Empfehlung",
      tagline: "Fairtrade & Demeter — ethisch vorbildlich."
    },
    secondaryInfo: {
      title: "Gesundheit",
      position: 2.8,
      barLeft: "ungünstig",
      barRight: "nährstoffreich",
      label: "gehaltvoll",
      facts: "Nutri-Score D · Zucker 47g/100g · NOVA 4 (verarbeitet)"
    },
    secondaryChecklist: [
      { ok: false, label: "Hoher Zuckergehalt",   note: "47g / 100g" },
      { ok: false, label: "Stark verarbeitet",    note: "NOVA-Klasse 4" },
      { ok: true,  label: "Hoher Kakaoanteil",    note: "70% — wenig Milchpulver/Zusätze" },
      { ok: true,  label: "Bio-Zutaten",          note: "EU-Bio + Demeter" },
    ],
    data_completeness: 0.95, data_quality: "high"
  },
  {
    barcode: "4337185353659",
    productType: "food",
    product_name: "Coca-Cola Original 1.5L",
    brand: "Coca-Cola",
    category: "Erfrischungsgetränke",
    image_emoji: "🥤",
    ecoscore_grade: "E",
    co2_total: 0.4,
    packaging: "PET-Plastik",
    origin: "Deutschland",
    labels: [], social_labels: [],
    esg: {
      e: 2.8, s: 3.0, g: 4.2, total: 3.3,
      verdict: "red", verdict_label: "Vermeiden",
      tagline: "PET-Plastik, problematische Lieferkette."
    },
    secondaryInfo: {
      title: "Gesundheit",
      position: 1.5,
      barLeft: "ungünstig",
      barRight: "nährstoffreich",
      label: "süß",
      facts: "Nutri-Score E · Zucker 10.6g/100ml · NOVA 4 (stark verarbeitet)"
    },
    secondaryChecklist: [
      { ok: false, label: "Sehr hoher Zuckergehalt", note: "10.6g/100ml — 35g pro Glas" },
      { ok: false, label: "Phosphorsäure",           note: "Säureregulator E338" },
      { ok: false, label: "Koffein",                 note: "10mg/100ml" },
      { ok: false, label: "Stark verarbeitet",       note: "NOVA-Klasse 4" },
    ],
    data_completeness: 0.75, data_quality: "medium"
  },
  {
    barcode: "4316268476546",
    productType: "food",
    product_name: "Bananen Bio Fairtrade",
    brand: "Edeka Bio",
    category: "Obst",
    image_emoji: "🍌",
    ecoscore_grade: "A",
    co2_total: 0.85,
    packaging: "Unverpackt",
    origin: "Ecuador",
    labels: ["EU-Bio"], social_labels: ["Fairtrade"],
    esg: {
      e: 8.2, s: 8.5, g: 5.0, total: 7.5,
      verdict: "green", verdict_label: "Empfehlung",
      tagline: "Bio + Fairtrade — solide Wahl."
    },
    secondaryInfo: {
      title: "Gesundheit",
      position: 8.5,
      barLeft: "ungünstig",
      barRight: "nährstoffreich",
      label: "nährstoffreich",
      facts: "Nutri-Score A · Zucker 12g/100g (natürlich) · NOVA 1 (unverarbeitet)"
    },
    secondaryChecklist: [
      { ok: true, label: "Unverarbeitet",         note: "NOVA-Klasse 1" },
      { ok: true, label: "Reich an Kalium",       note: "358mg/100g" },
      { ok: true, label: "Ballaststoffe",         note: "2.6g/100g" },
      { ok: true, label: "Keine Zusätze",         note: "Reines Naturprodukt" },
    ],
    data_completeness: 0.90, data_quality: "high"
  },

  // ───────── KLEIDUNG ─────────
  {
    barcode: "4099969712001",
    productType: "clothing",
    product_name: "Basic T-Shirt Bio-Baumwolle",
    brand: "Armedangels",
    category: "T-Shirts",
    image_emoji: "👕",
    packaging: "Kompostierbarer Versand",
    origin: "Portugal (Bio-Baumwolle: Türkei)",
    labels: ["GOTS", "Fair Wear Foundation"],
    social_labels: ["Fair Wear Foundation"],
    esg: {
      e: 7.8, s: 8.2, g: 8.0, total: 8.0,
      verdict: "green", verdict_label: "Empfehlung",
      tagline: "Bio-Baumwolle, faire Produktion in Europa."
    },
    secondaryInfo: {
      title: "Material & Pflege",
      position: 8.2,
      barLeft: "problematisch",
      barRight: "natürlich & langlebig",
      label: "natürlich",
      facts: "100% GOTS-Bio-Baumwolle · kein Mikroplastik · 30°C waschbar"
    },
    secondaryChecklist: [
      { ok: true,  label: "Naturfaser",                 note: "100% Bio-Baumwolle (GOTS)" },
      { ok: true,  label: "Kein Mikroplastik",          note: "Keine synthetischen Anteile" },
      { ok: true,  label: "Reparierbar",                note: "Standardnähte, kein Verbund" },
      { ok: true,  label: "Färbeverfahren offengelegt", note: "GOTS-Auflage erfüllt" },
      { ok: false, label: "Lieferkette transparent",    note: "Stoff-Herkunft, aber Garn-Quelle unklar" },
    ],
    data_completeness: 0.88, data_quality: "high"
  },
  {
    barcode: "5051091001234",
    productType: "clothing",
    product_name: "Slim-Fit Stretch Jeans",
    brand: "H&M",
    category: "Jeans",
    image_emoji: "👖",
    packaging: "Plastik-Polybeutel",
    origin: "Bangladesch",
    labels: [],
    social_labels: [],
    esg: {
      e: 3.5, s: 2.8, g: 3.2, total: 3.2,
      verdict: "red", verdict_label: "Vermeiden",
      tagline: "Mischgewebe, intransparente Lieferkette."
    },
    secondaryInfo: {
      title: "Material & Pflege",
      position: 2.2,
      barLeft: "problematisch",
      barRight: "natürlich & langlebig",
      label: "synthetisch",
      facts: "78% Baumwolle / 20% Polyester / 2% Elasthan · Mikroplastik beim Waschen"
    },
    secondaryChecklist: [
      { ok: false, label: "Mischgewebe",               note: "20% Polyester + 2% Elasthan" },
      { ok: false, label: "Mikroplastik beim Waschen", note: "Synthetische Fasern lösen sich" },
      { ok: false, label: "Lieferkette intransparent", note: "Färberei & Stoffquelle nicht ausgewiesen" },
      { ok: false, label: "Reparatur erschwert",       note: "Stretch-Naht, Reißverschluss vernietet" },
      { ok: true,  label: "Standardgrößen",            note: "Tausch unkompliziert" },
    ],
    data_completeness: 0.65, data_quality: "low"
  },
  {
    barcode: "4099969811112",
    productType: "clothing",
    product_name: "Wollpullover Merino",
    brand: "Hessnatur",
    category: "Pullover",
    image_emoji: "🧶",
    packaging: "Recycelter Karton",
    origin: "Deutschland (Wolle: Patagonien)",
    labels: ["IVN BEST", "RWS"],
    social_labels: ["RWS (Responsible Wool Standard)"],
    esg: {
      e: 6.5, s: 7.0, g: 7.8, total: 7.1,
      verdict: "green", verdict_label: "Empfehlung",
      tagline: "Reine Wolle, zertifizierte Tierhaltung."
    },
    secondaryInfo: {
      title: "Material & Pflege",
      position: 7.5,
      barLeft: "problematisch",
      barRight: "natürlich & langlebig",
      label: "langlebig",
      facts: "100% Schurwolle (RWS) · langlebig · Handwäsche / Wollwaschgang"
    },
    secondaryChecklist: [
      { ok: true,  label: "Naturfaser",          note: "100% Merinowolle (RWS-zertifiziert)" },
      { ok: true,  label: "Kein Mikroplastik",   note: "Tierfaser, biologisch abbaubar" },
      { ok: true,  label: "Sehr langlebig",      note: "Bei Pflege 10+ Jahre" },
      { ok: true,  label: "Reparierbar",         note: "Wolle ist gut stopfbar" },
      { ok: false, label: "Aufwendige Pflege",   note: "Handwäsche oder Wollprogramm nötig" },
    ],
    data_completeness: 0.92, data_quality: "high"
  },

  // ───────── KOSMETIK ─────────
  {
    barcode: "4015000940634",
    productType: "cosmetics",
    product_name: "Wild Rose Naturshampoo",
    brand: "Weleda",
    category: "Shampoo",
    image_emoji: "🧴",
    packaging: "PET-Flasche (recycelt 100%)",
    origin: "Deutschland",
    labels: ["NATRUE", "vegan"],
    social_labels: [],
    esg: {
      e: 7.0, s: 7.2, g: 8.0, total: 7.4,
      verdict: "green", verdict_label: "Empfehlung",
      tagline: "Naturkosmetik, vegan, recycelte Verpackung."
    },
    secondaryInfo: {
      title: "Inhaltsstoffe",
      position: 7.8,
      barLeft: "kritisch",
      barRight: "unbedenklich",
      label: "unbedenklich",
      facts: "NATRUE-zertifiziert · keine Mikroplastik · keine Silikone · kein SLS/SLES"
    },
    secondaryChecklist: [
      { ok: true,  label: "Frei von Mikroplastik",      note: "INCI-Check bestanden" },
      { ok: true,  label: "Frei von Silikonen",         note: "Keine -cone/-conol-Endungen" },
      { ok: true,  label: "Frei von SLS/SLES",          note: "Milde Zuckertenside" },
      { ok: true,  label: "Keine Tierversuche",         note: "EU-Verbot + NATRUE-Auflage" },
      { ok: false, label: "Nicht für sehr trockenes Haar", note: "Reinigend, weniger pflegend" },
    ],
    data_completeness: 0.93, data_quality: "high"
  },
  {
    barcode: "4084500120532",
    productType: "cosmetics",
    product_name: "Anti-Schuppen-Shampoo Classic",
    brand: "Head & Shoulders",
    category: "Shampoo",
    image_emoji: "🧴",
    packaging: "PET-Flasche (Neuplastik)",
    origin: "Polen",
    labels: [],
    social_labels: [],
    esg: {
      e: 3.0, s: 4.0, g: 4.5, total: 3.8,
      verdict: "red", verdict_label: "Vermeiden",
      tagline: "Konventionell, kritische Inhaltsstoffe."
    },
    secondaryInfo: {
      title: "Inhaltsstoffe",
      position: 2.5,
      barLeft: "kritisch",
      barRight: "unbedenklich",
      label: "kritisch",
      facts: "Enthält SLES · Silikone · Mikroplastik (Acrylates Copolymer)"
    },
    secondaryChecklist: [
      { ok: false, label: "Mikroplastik enthalten", note: "Acrylates Crosspolymer" },
      { ok: false, label: "Silikone",               note: "Dimethicone (Position 5 INCI)" },
      { ok: false, label: "SLES",                   note: "Sodium Laureth Sulfate" },
      { ok: true,  label: "Antischuppen-Wirkstoff", note: "Zink-Pyrithion klinisch belegt" },
      { ok: false, label: "Konservierungsstoffe",   note: "Methylisothiazolinon (Allergiepotenzial)" },
    ],
    data_completeness: 0.78, data_quality: "medium"
  },

  // ───────── NOT FOUND ─────────
  {
    barcode: "0000000000000",
    productType: null,
    product_name: null,
    brand: null,
    category: null,
    image_emoji: null,
    notFound: true
  }
];

// ───────────────────────────────────────────────────────────────
// Backwards-Compat
// — Top-Level: e_score / s_score / g_score / total_score / traffic_light
// — health.* (Alias für secondaryInfo, damit alte HealthBar-Komponente
//   weiterhin direkt mit health-Feld arbeiten kann)
// ───────────────────────────────────────────────────────────────
window.SCANFAIR_PRODUCTS.forEach(p => {
  if (p.notFound) return;
  p.e_score = p.esg.e;
  p.s_score = p.esg.s;
  p.g_score = p.esg.g;
  p.total_score = p.esg.total;
  p.traffic_light = p.esg.verdict;
  // Alias für alte Komponenten (S3/S4 v1)
  p.health = p.secondaryInfo;
});

// Kategorie-Durchschnitte (für 'Vergleich mit Kategorie' Feature)
window.SCANFAIR_CATEGORY_AVERAGES = {
  "Pflanzendrinks":          { e: 6.8, s: 5.0, g: 5.0, total: 5.8 },
  "Schokolade":              { e: 4.5, s: 4.8, g: 5.5, total: 4.9 },
  "Erfrischungsgetränke":    { e: 3.2, s: 4.0, g: 5.0, total: 3.9 },
  "Obst":                    { e: 7.5, s: 6.0, g: 5.0, total: 6.4 },
  "T-Shirts":                { e: 4.5, s: 4.0, g: 4.5, total: 4.3 },
  "Jeans":                   { e: 3.8, s: 3.5, g: 4.0, total: 3.8 },
  "Pullover":                { e: 5.5, s: 5.0, g: 5.5, total: 5.3 },
  "Shampoo":                 { e: 5.0, s: 5.5, g: 6.0, total: 5.5 },
};

// Hilfs-Lookup: 1 Demo-Produkt je Kategorie für die Tweak-Auswahl auf S3/S4
window.SCANFAIR_DEMO_BY_TYPE = {
  food:      window.SCANFAIR_PRODUCTS[1],  // GEPA-Schoko
  clothing:  window.SCANFAIR_PRODUCTS[4],  // Armedangels T-Shirt
  cosmetics: window.SCANFAIR_PRODUCTS[7],  // Weleda Shampoo
};
