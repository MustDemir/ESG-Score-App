// ScanFair Discovery — Personas-Karten (Hybrid: Übersicht + Detail)

const sfDiscoveryFont = { fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif' };
const SF_INK = '#1A1A18';
const SF_INK_60 = '#737370';
const SF_INK_40 = '#A8A8A0';
const SF_LINE = '#E7E7E2';
const SF_PAPER = '#FAFAF9';
const SF_TEAL = '#0F766E';   // primary accent (matches future hi-fi)
const SF_AMBER = '#B45309';
const SF_ROSE = '#BE185D';
const SF_BLUE = '#1E40AF';

// Compact persona card (overview)
function PersonaCardCompact({ persona, accent }) {
  return (
    <div style={{
      ...sfDiscoveryFont, width: 240, padding: 20,
      background: '#fff', border: `1px solid ${SF_LINE}`, borderRadius: 12,
      display: 'flex', flexDirection: 'column', gap: 12,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{
          width: 56, height: 56, borderRadius: 28, background: accent + '14',
          border: `2px solid ${accent}`, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 28,
        }}>{persona.avatar}</div>
        <div>
          <div style={{ fontSize: 18, fontWeight: 700, color: SF_INK, letterSpacing: -0.2 }}>
            {persona.name}, {persona.age}
          </div>
          <div style={{ fontSize: 12, color: SF_INK_60, marginTop: 2 }}>{persona.role}</div>
        </div>
      </div>
      <div style={{ fontSize: 12, color: SF_INK_60, lineHeight: 1.5, fontStyle: 'italic' }}>
        {persona.short}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <div style={{ fontSize: 10, fontWeight: 600, color: SF_INK_40, letterSpacing: 0.5, textTransform: 'uppercase' }}>
          Tech-Affinität
        </div>
        <div style={{ height: 6, background: SF_LINE, borderRadius: 3, overflow: 'hidden' }}>
          <div style={{ width: `${persona.techAffinity * 100}%`, height: '100%', background: accent }} />
        </div>
      </div>
      <div style={{
        padding: '8px 10px', background: accent + '08', borderLeft: `3px solid ${accent}`,
        fontSize: 11, fontStyle: 'italic', color: SF_INK, lineHeight: 1.5,
      }}>
        „{persona.quote}"
      </div>
    </div>
  );
}

// Detailed persona card (deep-dive)
function PersonaCardDetail({ persona, accent }) {
  return (
    <div style={{
      ...sfDiscoveryFont, width: 360, padding: 24,
      background: '#fff', border: `1px solid ${SF_LINE}`, borderRadius: 16,
      display: 'flex', flexDirection: 'column', gap: 16,
    }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 64, height: 64, borderRadius: 32, background: accent + '14',
          border: `2.5px solid ${accent}`, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 32,
        }}>{persona.avatar}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 20, fontWeight: 700, color: SF_INK, letterSpacing: -0.3 }}>
            {persona.name}, {persona.age}
          </div>
          <div style={{ fontSize: 13, color: accent, fontWeight: 600, marginTop: 2 }}>{persona.role}</div>
          <div style={{ fontSize: 12, color: SF_INK_60, marginTop: 2 }}>{persona.short}</div>
        </div>
      </div>

      {/* Bio */}
      <div style={{
        padding: 12, background: SF_PAPER, borderRadius: 8,
        fontSize: 12, color: SF_INK, lineHeight: 1.55,
      }}>{persona.bio}</div>

      {/* Quote */}
      <div style={{
        padding: '12px 14px', background: accent + '0A', borderLeft: `3px solid ${accent}`,
        fontSize: 13, fontStyle: 'italic', color: SF_INK, lineHeight: 1.5,
      }}>„{persona.quote}"</div>

      {/* Goals */}
      <div>
        <div style={{ fontSize: 10, fontWeight: 700, color: SF_INK_40, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 6 }}>
          🎯 Goals
        </div>
        <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12, color: SF_INK, lineHeight: 1.7 }}>
          {persona.goals.map((g, i) => <li key={i}>{g}</li>)}
        </ul>
      </div>

      {/* Pains */}
      <div>
        <div style={{ fontSize: 10, fontWeight: 700, color: '#BE185D', letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 6 }}>
          ⚠️ Pain Points
        </div>
        <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12, color: SF_INK, lineHeight: 1.7 }}>
          {persona.pains.map((p, i) => <li key={i}>{p}</li>)}
        </ul>
      </div>

      {/* Tech Affinity */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: SF_INK_40, letterSpacing: 0.6, textTransform: 'uppercase' }}>
            Tech-Affinität
          </div>
          <div style={{ fontSize: 11, color: SF_INK_60, fontWeight: 600 }}>
            {Math.round(persona.techAffinity * 100)}%
          </div>
        </div>
        <div style={{ height: 6, background: SF_LINE, borderRadius: 3, overflow: 'hidden' }}>
          <div style={{ width: `${persona.techAffinity * 100}%`, height: '100%', background: accent }} />
        </div>
      </div>

      {/* Primary CJM Phase */}
      <div style={{
        padding: '10px 12px', border: `1px dashed ${accent}`, borderRadius: 8,
        fontSize: 11, color: SF_INK_60,
      }}>
        <span style={{ color: SF_INK_40, fontWeight: 600 }}>Primärer Use Case: </span>
        <span style={{ color: SF_INK, fontWeight: 600 }}>{persona.primaryPhase}</span>
      </div>
    </div>
  );
}

// Full personas section: 3 compact + 3 detail
function PersonasSection() {
  const accents = { klaus: SF_BLUE, thomas: SF_TEAL, anna: SF_ROSE };
  return (
    <div style={{ ...sfDiscoveryFont, padding: '40px 60px', background: SF_PAPER }}>
      <div style={{ marginBottom: 32 }}>
        <div style={{ fontSize: 11, color: SF_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Übersicht
        </div>
        <div style={{ fontSize: 24, fontWeight: 700, color: SF_INK, letterSpacing: -0.3 }}>
          Drei Personas, drei Einkaufs-Kontexte
        </div>
        <div style={{ fontSize: 14, color: SF_INK_60, marginTop: 8, maxWidth: 720, lineHeight: 1.6 }}>
          ScanFair muss in drei sehr unterschiedlichen Lebensrealitäten funktionieren: tägliche Kleinkäufe (Klaus),
          wöchentliche Meal-Prep-Planung (Thomas) und Familieneinkäufe mit Budget-Druck (Anna).
        </div>
      </div>
      {/* Compact row */}
      <div style={{ display: 'flex', gap: 24, marginBottom: 48, flexWrap: 'wrap' }}>
        {window.SF_PERSONAS.map(p => (
          <PersonaCardCompact key={p.id} persona={p} accent={accents[p.id]} />
        ))}
      </div>

      <div style={{ marginBottom: 32 }}>
        <div style={{ fontSize: 11, color: SF_INK_40, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
          Tiefenprofile
        </div>
        <div style={{ fontSize: 24, fontWeight: 700, color: SF_INK, letterSpacing: -0.3 }}>
          Goals, Pains, Quotes — das volle Bild
        </div>
      </div>
      {/* Detail row */}
      <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
        {window.SF_PERSONAS.map(p => (
          <PersonaCardDetail key={p.id} persona={p} accent={accents[p.id]} />
        ))}
      </div>
    </div>
  );
}

window.PersonasSection = PersonasSection;
