// ScanFair Discovery — Daten aus Hausarbeit & PITCH.md
// Personas, CJM-Phasen, VPC, Conjoint-Daten, Epics

window.SF_PERSONAS = [
  {
    id: 'klaus',
    name: 'Klaus',
    age: 68,
    avatar: '👴🏻',
    role: 'Rentner',
    short: 'Tägliche kleine Einkäufe · ÖPNV oder zu Fuß',
    bio: 'Lebt allein im Stadtteil, kauft täglich frische Lebensmittel im nahen Supermarkt. Nutzt sein iPhone für WhatsApp und Online-Banking, ist mit Apps grundsätzlich vertraut, aber nicht techniknahe.',
    quote: 'Ich will einfach wissen, ob das, was ich kaufe, in Ordnung ist — ohne langes Suchen.',
    goals: [
      'Schnell und stressfrei einkaufen',
      'Geld sparen, aber nicht auf Kosten der Qualität',
      'Nichts vergessen'
    ],
    pains: [
      'Kleingedrucktes auf Etiketten ist schwer lesbar',
      'Zu viele Siegel, deren Bedeutung unklar ist',
      'Greenwashing-Verdacht bei „Bio"-Marken'
    ],
    techAffinity: 0.5,
    primaryPhase: 'Spontaner Einkauf vor Ort'
  },
  {
    id: 'thomas',
    name: 'Thomas',
    age: 28,
    avatar: '🧑🏻',
    role: 'Single, Spontankäufer',
    short: 'Kleine Einkäufe · zu Fuß oder Fahrrad',
    bio: 'Lebt in der Stadt, plant Mahlzeiten gerne im Voraus für Meal-Prep. Verfolgt Fitness-Ziele (Protein), legt Wert auf regionale und schnelle Rezepte. Nutzt Apps intensiv, ist Power-User.',
    quote: 'Ich plane Sonntagabend meinen Wocheneinkauf — und brauche dafür schnelle, smarte Filter.',
    goals: [
      'Wocheneinkauf effizient planen',
      'Fitness-Ziele (Protein, regional, vegan) berücksichtigen',
      'Aktuelle Angebote nicht verpassen'
    ],
    pains: [
      'Manuelle Pflege von Einkaufslisten kostet Zeit',
      'Vergleich zwischen Produkten schwierig',
      'Wenig Zeit, viele Optionen'
    ],
    techAffinity: 0.95,
    primaryPhase: 'Geplanter Wocheneinkauf zuhause'
  },
  {
    id: 'anna',
    name: 'Anna',
    age: 35,
    avatar: '👩🏻',
    role: 'Berufstätige Mutter',
    short: 'Wocheneinkauf mit Budget · fährt mit dem Auto',
    bio: 'Familie mit zwei Kindern, plant Wocheneinkauf am Wochenende mit dem Auto. Hat ein striktes Budget, will aber bewusst nachhaltig konsumieren. Wenig Zeit für tiefe Recherche.',
    quote: 'Ich will fürs gleiche Geld die bessere Wahl treffen — schnell und ohne schlechtes Gewissen.',
    goals: [
      'Familienfreundlich + nachhaltig + im Budget',
      'Schnelle Bewertung am Regal',
      'Kindgerechte Produkte mit klaren Kriterien'
    ],
    pains: [
      'Bio + Budget = Konflikt',
      'Lange Etiketten-Recherche unmöglich mit zwei Kindern im Wagen',
      'Mental Load durch Entscheidungsdruck'
    ],
    techAffinity: 0.75,
    primaryPhase: 'Wochenendeinkauf mit Familie'
  }
];

// CJM Ist-Zustand: Traditioneller Supermarkt (aus Folie der Hausarbeit)
window.SF_CJM_IST = {
  title: 'Customer Journey Map — Traditioneller Supermarkt (Ist-Zustand)',
  phases: [
    {
      id: 1, name: 'Vorbereitung', icon: '📝',
      actions: ['Einkaufsliste erstellen', 'Angebote prüfen', 'Budget planen'],
      goals: ['Zeit sparen', 'Geld sparen', 'Nichts vergessen'],
      touchpoints: ['App/Website', 'Prospekte', 'Kundenkarte'],
      emotion: 'neutral', emotionLabel: 'Planend, vorfreudig',
      stakeholders: ['Familie', 'Supermarkt', 'App-Anbieter']
    },
    {
      id: 2, name: 'Anreise', icon: '🚗',
      actions: ['Transport wählen', 'Parkplatz suchen', 'Tasche mitnehmen'],
      goals: ['Schnell ankommen', 'Parkplatz finden', 'Stressfrei'],
      touchpoints: ['Parkplatz', 'Außenbereich', 'Wagen-Station'],
      emotion: 'mild-stress', emotionLabel: 'Leicht gestresst, genervt',
      stakeholders: ['Andere Kunden', 'Parkplatzbetreiber']
    },
    {
      id: 3, name: 'Eingang', icon: '🚪',
      actions: ['Einkaufswagen holen', 'Desinfektion', 'Orientierung'],
      goals: ['Hygiene', 'Übersicht', 'Funktionierender Wagen'],
      touchpoints: ['Eingangsbereich', 'Desinfektionsspender', 'Hinweisschilder'],
      emotion: 'neutral', emotionLabel: 'Neutral, orientiert',
      stakeholders: ['Andere Kunden', 'Reinigungspersonal']
    },
    {
      id: 4, name: 'Einkauf', icon: '🛒',
      actions: ['Produkte suchen', 'Preise vergleichen', 'Qualität prüfen', 'In Wagen legen'],
      goals: ['Alles finden', 'Frische Produkte', 'Gutes Preis-Leistung'],
      touchpoints: ['Regale', 'Preisschilder', 'Personal', 'Sonderangebote'],
      emotion: 'mixed', emotionLabel: 'Fokussiert, zufrieden bei Funden, frustriert wenn nicht gefunden',
      stakeholders: ['Verkaufspersonal', 'Andere Kunden', 'Marken/Hersteller'],
      isPainHotspot: true
    },
    {
      id: 5, name: 'Kasse', icon: '💳',
      actions: ['Anstehen', 'Aufs Band legen', 'Bezahlen', 'Einpacken'],
      goals: ['Schnell durchkommen', 'Korrekte Abrechnung', 'Freundlicher Service'],
      touchpoints: ['Kasse', 'Kassierer', 'EC-Terminal', 'Kassenbon'],
      emotion: 'high-stress', emotionLabel: 'Ungeduldig, gestresst (Schlange), erleichtert',
      stakeholders: ['Kassenpersonal', 'Andere Kunden', 'Zahlungsanbieter'],
      isPainHotspot: true
    },
    {
      id: 6, name: 'Abreise', icon: '🚗',
      actions: ['Zum Auto gehen', 'Einladen', 'Wagen zurück'],
      goals: ['Schnell weg', 'Nichts vergessen', 'Sicher transportieren'],
      touchpoints: ['Parkplatz', 'Wagen-Rückgabe', 'Ladebereich'],
      emotion: 'mild-stress', emotionLabel: 'Erschöpft, erleichtert',
      stakeholders: ['Personal', 'Andere Kunden']
    },
    {
      id: 7, name: 'Nachbereitung', icon: '🏠',
      actions: ['Auspacken', 'Verstauen', 'Bon aufheben'],
      goals: ['Zufriedenheit', 'Qualität bestätigt', 'Gut organisiert'],
      touchpoints: ['Produkte', 'Kassenbon', 'Feedback-Kanäle'],
      emotion: 'mixed', emotionLabel: 'Zufrieden, manchmal enttäuscht',
      stakeholders: ['Familie', 'Supermarkt', 'Kundenservice']
    }
  ]
};

// CJM Soll-Zustand mit ScanFair (aus Hausarbeit + ScanFair-Technologien)
window.SF_CJM_SOLL = {
  title: 'Customer Journey Map — Mit ScanFair (Soll-Zustand)',
  phases: [
    {
      id: 1, name: 'Vorbereitung', icon: '📝',
      sfFeature: 'Digitale Einkaufsliste · Personalisierte Angebote',
      sfScreen: 'S6 Planung',
      sfStatus: 'mvp',
      improvement: 'Smart-Anpassung lädt letzte Liste, schlägt Angebote + Alternativen vor',
      emotion: 'positive', emotionLabel: 'Vorfreudig, kompetent',
      painSolved: 'Manuelle Listenpflege entfällt'
    },
    {
      id: 2, name: 'Anreise', icon: '🚗',
      sfFeature: '—',
      sfScreen: null,
      sfStatus: 'none',
      improvement: 'Keine direkte ScanFair-Funktion (außer Liste mitnehmen)',
      emotion: 'neutral', emotionLabel: 'Unverändert',
      painSolved: null
    },
    {
      id: 3, name: 'Eingang', icon: '🚪',
      sfFeature: 'App-Check-In (Phase 3 mit Supermarkt-Integration)',
      sfScreen: null,
      sfStatus: 'phase3',
      improvement: 'Filiale wird in App registriert, Standort-spezifische Angebote',
      emotion: 'neutral', emotionLabel: 'Orientiert, vorbereitet',
      painSolved: null
    },
    {
      id: 4, name: 'Einkauf', icon: '🛒',
      sfFeature: 'Scan & Go · Echtzeit-ESG-Score · Alternativen-Empfehlung',
      sfScreen: 'S2 + S3 + S4',
      sfStatus: 'mvp',
      improvement: 'Barcode scannen → Score in 2 Sek. → bessere Alternative wenn gewünscht',
      emotion: 'very-positive', emotionLabel: 'Informiert, sicher, in Kontrolle',
      painSolved: 'Greenwashing-Angst, Informationsmangel, Zeitdruck',
      isHero: true
    },
    {
      id: 5, name: 'Kasse', icon: '💳',
      sfFeature: 'Mobile Payment (Phase 3 mit Supermarkt-Integration)',
      sfScreen: null,
      sfStatus: 'phase3',
      improvement: 'Direkt aus App bezahlen, keine Schlange',
      emotion: 'positive', emotionLabel: 'Schnell, entspannt',
      painSolved: 'Wartezeit'
    },
    {
      id: 6, name: 'Abreise', icon: '🚗',
      sfFeature: '—',
      sfScreen: null,
      sfStatus: 'none',
      improvement: 'Unverändert',
      emotion: 'neutral', emotionLabel: 'Unverändert',
      painSolved: null
    },
    {
      id: 7, name: 'Nachbereitung', icon: '🏠',
      sfFeature: 'Digital-Bon · Impact-Tracker · Treue-Belohnungen',
      sfScreen: 'S7 Impact',
      sfStatus: 'phase2',
      improvement: 'Sieht aggregierten ESG-Impact des Einkaufs, Fortschritt über Zeit',
      emotion: 'very-positive', emotionLabel: 'Stolz, motiviert, gewohnt',
      painSolved: 'Gefühl, ob es „etwas gebracht hat"'
    }
  ]
};

// Value Proposition Canvas (aus Hausarbeit)
window.SF_VPC = {
  customer: {
    jobs: [
      'Nachhaltig einkaufen ohne Aufwand',
      'Bewusste Konsumentscheidungen treffen',
      'Familie mit gutem Gewissen versorgen'
    ],
    pains: [
      'Informationsmangel am POS',
      'Zeitdruck im Alltag',
      'Greenwashing-Angst',
      'Komplexe Siegel-Vielfalt'
    ],
    gains: [
      'Gutes Gewissen',
      'Zeitersparnis',
      'Orientierung',
      'Selbstwirksamkeit'
    ]
  },
  product: {
    products: [
      'ScanFair App',
      'ESG-Datenbank (E + S + G)',
      'Empfehlungs-Engine'
    ],
    relievers: [
      'Transparenz in Sekunden',
      'Vertrauenswürdige Quellen (OFF · ADEME · Fairtrade)',
      'Datenqualitäts-Badge bei jedem Score',
      'Kein Account, kein Tracking'
    ],
    creators: [
      'Gamification (Impact-Tracker)',
      'Community-Features (Phase 2)',
      'Persönliche Gewichtung E/S/G',
      'Bessere Alternativen sofort sichtbar'
    ]
  }
};

// Conjoint-Analyse Feature-Priorität (aus Hausarbeit S. 4)
window.SF_CONJOINT = [
  { feature: 'Echtzeit-ESG-Scores', weight: 35, screen: 'S3 Score-Ergebnis', status: 'mvp' },
  { feature: 'Personalisierte Empfehlungen', weight: 25, screen: 'S3 Alternativen', status: 'mvp' },
  { feature: 'Lieferketten-Transparenz', weight: 20, screen: 'S4 Details', status: 'mvp' },
  { feature: 'Gamification / Impact-Tracker', weight: 12, screen: 'S7 Impact', status: 'phase2' },
  { feature: 'Community-Features', weight: 8, screen: '—', status: 'phase2' }
];

// Marktdaten (aus Hausarbeit + PITCH.md)
window.SF_MARKET = {
  killerStat: { ready: 73, find: 12, source: 'Nielsen 2024' },
  growth: [
    { label: 'ESG-Produkte vs. Standard', value: '+40%', period: '2017–2022', source: 'McKinsey/NielsenIQ 2023' },
    { label: 'Eigenmarken mit ESG-Transparenz', value: '88%', period: 'der Kategorien überproportional', source: 'McKinsey/NielsenIQ 2023' },
    { label: 'Multi-Claim-Effekt', value: '2,5×', period: 'schnelleres Wachstum', source: 'McKinsey/NielsenIQ 2023' }
  ],
  roi: [
    { metric: 'Umsatzsteigerung (umweltbew. Zielgr.)', value: '+15%' },
    { metric: 'Kundenzufriedenheit (Jahr 1)', value: '+22%' },
    { metric: 'Amortisationszeit', value: '18 Monate' },
    { metric: 'Pilot-Budget (3 Filialen)', value: '250.000 €' }
  ]
};

// Stakeholder-Map nach Freeman
window.SF_STAKEHOLDERS = {
  primary: {
    label: 'Primär (direkt betroffen)',
    items: [
      { name: 'Konsumenten / End-User', role: 'Nutzen die App täglich', personas: ['Klaus', 'Thomas', 'Anna'] },
      { name: 'Produzenten / Marken', role: 'Werden bewertet, profitieren von Transparenz' }
    ]
  },
  secondary: {
    label: 'Sekundär (indirekt beteiligt)',
    items: [
      { name: 'Lieferanten', role: 'Liefern Datenbasis für Lieferkettentransparenz' },
      { name: 'Zertifizierungsorganisationen', role: 'Liefern Siegel-Daten (Fairtrade, EU-Bio, Demeter)' },
      { name: 'Datenquellen', role: 'Open Food Facts, ADEME, BAFA' }
    ]
  },
  tertiary: {
    label: 'Tertiär (Rahmenbedingungen)',
    items: [
      { name: 'Wettbewerber', role: 'Yuka, OFF-App, CodeCheck' },
      { name: 'Regulierungsbehörden', role: 'DSGVO, EU-Lieferkettengesetz, CSRD' },
      { name: 'Supermärkte (Pilot-Partner)', role: 'B2B-Kooperation für Filial-Integration' }
    ]
  }
};

// 4 Epics aus Hausarbeit (Folie 5)
window.SF_EPICS = [
  {
    id: 'epic1', name: 'KI-Service-Integration',
    description: 'Integration und Orchestrierung verschiedener KI-Dienste zu einer kohärenten Lösung.',
    stories: [
      'Als Entwickler möchte ich eine flexible Middleware erstellen, die verschiedene KI-Dienste nahtlos integriert.',
      'Als Produktmanager möchte ich Kosten und Leistung verschiedener KI-Dienste vergleichen können.',
      'Als Nutzer möchte ich eine reibungslose Erfahrung haben, ohne zu merken, dass im Hintergrund verschiedene KI-Dienste zusammenarbeiten.'
    ],
    status: 'phase2'
  },
  {
    id: 'epic2', name: 'Personalisierte ESG-Bewertung',
    description: 'System, das externe ESG-Daten mit KI-Diensten kombiniert für personalisierte Bewertungen.',
    stories: [
      'Als Nutzer möchte ich Produkte scannen und sofort eine auf meine Präferenzen zugeschnittene ESG-Bewertung erhalten.',
      'Als Nutzer möchte ich verstehen, wie meine persönlichen Präferenzen die ESG-Bewertung beeinflussen.',
      'Als Nutzer möchte ich Feedback geben können, wenn ich mit einer Bewertung nicht einverstanden bin.'
    ],
    status: 'mvp'
  },
  {
    id: 'epic3', name: 'Produkterkennung & Informationsextraktion',
    description: 'Bilderkennungs- und OCR-Dienste für Produktidentifikation und Informationsextraktion.',
    stories: [
      'Als Nutzer möchte ich Produkte mit der Kamera scannen und sofort alle relevanten Informationen erhalten.',
      'Als Nutzer möchte ich Kassenbons scannen können und eine automatische Analyse meines gesamten Einkaufs erhalten.',
      'Als Nutzer möchte ich auch bei schlechten Lichtverhältnissen oder teilweise verdeckten Produkten eine zuverlässige Erkennung haben.'
    ],
    status: 'mvp'
  },
  {
    id: 'epic4', name: 'Intelligentes Nutzerprofilmanagement',
    description: 'System zur Erstellung und Pflege personalisierter Nutzerprofile mit Hilfe von MLaaS-Diensten.',
    stories: [
      'Als Nutzer möchte ich ein initiales Profil mit meinen Präferenzen erstellen können, das dann automatisch durch mein Nutzungsverhalten verfeinert wird.',
      'Als Nutzer möchte ich, dass die App aus meinen Einkäufen lernt und immer bessere Empfehlungen gibt.',
      'Als Nutzer mit sich ändernden Präferenzen möchte ich, dass die App diese Veränderungen erkennt und ihre Empfehlungen entsprechend anpasst.'
    ],
    status: 'phase2'
  }
];

// Risiken & Mitigation (aus Hausarbeit)
window.SF_RISKS = [
  {
    risk: 'Datenverfügbarkeit & -qualität',
    severity: 'high',
    impact: 'Score basiert auf lückenhaften OFF-Daten → unzuverlässige Bewertungen',
    mitigation: 'Datenqualitäts-Badge transparent kommunizieren · Vertrauens-Ampel · multiple Quellen aggregieren'
  },
  {
    risk: 'Lieferantenakzeptanz',
    severity: 'medium',
    impact: 'Marken könnten Bewertungen anfechten, Daten verweigern',
    mitigation: 'Schrittweise Integration mit Pilot-Partnern · Transparente Methodik · Beschwerde-Prozess'
  },
  {
    risk: 'Technische Integration in Bestandssysteme',
    severity: 'medium',
    impact: 'Filial-Integration mit POS-Systemen aufwändig',
    mitigation: 'API-First-Ansatz · Phase 1 standalone Consumer-App · Phase 3 erst Supermarkt-Integration'
  },
  {
    risk: 'DSGVO & Datenschutz',
    severity: 'high',
    impact: 'Personalisierung erfordert Nutzerdaten — DSGVO-Konflikt',
    mitigation: 'Privacy-by-Design · Lokale Speicherung (Hive) · Kein Tracking, kein Login im MVP · EU-Hosting'
  },
  {
    risk: 'Greenwashing-Vorwurf',
    severity: 'medium',
    impact: 'App selbst könnte als Greenwashing-Tool wahrgenommen werden',
    mitigation: 'Quellen-Transparenz · Methodik-Link · Kritische Bewertungen (auch Rot-Scores) · Open-Source-Methodik'
  }
];

// Roadmap (aus Hausarbeit Pilot-Plan)
window.SF_ROADMAP = [
  {
    phase: 'MVP', timeline: 'Q1–Q2 2026', label: 'Phase 1 — Pilot',
    scope: '3 Filialen (Pilot-Region) · Standalone Consumer-App',
    features: ['Barcode-Scan', 'E-Score (vollständig)', 'S-Score (Basis)', 'Alternativen-Vorschlag', 'Persona-Personalisierung'],
    budget: '250.000 €',
    metrics: ['1.000 aktive Nutzer', 'Score-Genauigkeit > 80%', 'NPS > 30']
  },
  {
    phase: 'Phase 2', timeline: 'Q3 2026 – Q1 2027', label: 'Regionale Expansion',
    scope: 'Region erweitert · Erste Supermarkt-Kooperationen',
    features: ['G-Score (vollständig)', 'Impact-Tracker', 'Meal-Prep-Planung', 'Persönliche Gewichtung', 'Community-Features'],
    budget: '750.000 €',
    metrics: ['10.000 aktive Nutzer', '+15% Umsatz bei Pilot-Partnern']
  },
  {
    phase: 'Phase 3', timeline: 'ab Q2 2027', label: 'Nationale Skalierung',
    scope: 'Bundesweit · Tiefe Supermarkt-Integration',
    features: ['App-Check-In', 'Mobile Payment', 'AR-Produktinfo', 'Treue-Belohnungen', 'KI-Service-Integration'],
    budget: 'open',
    metrics: ['100.000+ Nutzer', '+22% Kundenzufriedenheit', 'Amortisation nach 18 Mon.']
  }
];

// Methodischer Rahmen (aus Hausarbeit)
window.SF_METHODOLOGY = {
  frameworks: [
    { name: 'Design Thinking', purpose: 'Nutzerzentrierte, kreative Lösungsfindung', source: 'Schallmo (2017)' },
    { name: 'Requirements Engineering', purpose: 'Systematische Erfassung & Strukturierung von Anforderungen', source: 'Pohl & Rupp (2021)' },
    { name: 'Customer Journey Mapping', purpose: 'Pain Points entlang der User-Reise identifizieren', source: 'Stickdorn & Schneider (2012)' },
    { name: 'Value Proposition Canvas', purpose: 'Product-Market-Fit sicherstellen', source: 'Osterwalder et al. (2014)' },
    { name: 'Conjoint-Analyse', purpose: 'Feature-Präferenzen quantifizieren', source: 'Green & Srinivasan (1990)' },
    { name: 'Lean Startup', purpose: 'Iterative Validierung mit MVP', source: 'Ries (2011)' },
    { name: 'Kotter 8-Stufen', purpose: 'Change Management beim Rollout', source: 'Kotter (2014)' }
  ],
  phases: ['Verstehen', 'Beobachten', 'Synthese', 'Ideen', 'Prototyp', 'Test']
};
