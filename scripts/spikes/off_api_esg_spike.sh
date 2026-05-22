#!/usr/bin/env bash
# =============================================================================
# Open Food Facts API — ESG-Feld-Coverage-Spike
# =============================================================================
# Zweck: Pro EAN prüfen, welche ESG-relevanten Felder befüllt sind.
# Ziel:  Belastbare Aussage ob OFF-Daten für unseren ESG-Score reichen.
#
# Ausgabe: Markdown-Report unter docs/project/spikes/off-api-YYYY-MM-DD.md
#
# Bezug: TODO-001, RISK-001, ADR 0003
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${REPO_ROOT}/docs/project/spikes/off-api-$(date +%Y-%m-%d).md"
UA="${OPENFOODFACTS_USER_AGENT:-ScanFair-Spike/0.1 (business.demir@gmail.com)}"
API="https://world.openfoodfacts.org/api/v2/product"

# Wir holen alle ESG-relevanten Felder
FIELDS=$(cat <<'EOF' | tr -d '\n '
code,product_name,brands,countries_tags,
ecoscore_grade,ecoscore_score,ecoscore_data,
nutriscore_grade,
labels_tags,categories_tags,origins,origins_tags,
packaging,packaging_tags,packagings,
manufacturing_places,manufacturing_places_tags,
agribalyse,
ingredients_text_de,ingredients_text,
nutriments,
nova_group,
data_quality_tags,states_tags
EOF
)

# 20 VERIFIZIERTE reale EANs aus OFF (via Search-API geprüft am 2026-05-19)
# Mix: Mainstream (Coca-Cola, Milka, Nutella), DE-Eigenmarken (Edeka Bio, Aldi),
# Spezialprodukte (Club-Mate, Philadelphia, Müller Kefir).
EANS=(
  "5449000000996:Coca-Cola Original"
  "5449000054227:Coca-Cola 500ml"
  "5449000214799:Coke Zero"
  "5449000147417:Cappy Pulpy (Coca-Cola)"
  "4029764001807:Club-Mate Original"
  "4008400401621:Nutella"
  "4008400404127:Nutella Nuss-Nugat-Creme"
  "7622300315733:Philadelphia Original"
  "4025500287955:Müller Kefir"
  "3045140105502:Milka Chocolat au lait"
  "7622210100917:Milka Galette Choco"
  "7622300784751:Milka Cake & Choc"
  "2006050050833:Aldi Erdnussbutter Crunchy"
  "4068262073381:Aldi Erdnussbutter"
  "4088600184197:Aldi Malted Bread"
  "2006050102860:Aldi Tartines Bio"
  "4311501748367:Edeka Bio Hummus Natur"
  "4311501635773:Edeka Bio Olivenöl"
  "4311501694121:Edeka Bio Soja Natur"
  "4311501672464:Edeka Veggie Erdnussmus"
)

mkdir -p "$(dirname "$OUT")"

# --- Markdown-Header ---
{
  echo "# Open Food Facts ESG-Feld-Coverage Spike"
  echo
  echo "**Datum:** $(date +%Y-%m-%d)  "
  echo "**Bezug:** TODO-001, RISK-001, ADR 0003  "
  echo "**Ziel:** Belastbare Aussage ob OFF-Daten für unseren ESG-Score reichen."
  echo
  echo "## Methodik"
  echo
  echo "Pro EAN wird die OFF-API v2 abgefragt. Geprüft werden ESG-relevante Felder:"
  echo
  echo "| Säule | OFF-Felder |"
  echo "|---|---|"
  echo "| **E** (Environment) | ecoscore_grade, ecoscore_data, agribalyse, packaging, origins |"
  echo "| **S** (Social)      | labels_tags (Fair-Trade, Bio), manufacturing_places |"
  echo "| **G** (Governance)  | data_quality_tags, states_tags (Vollständigkeit) |"
  echo
  echo "## Ergebnis je Produkt"
  echo
  echo "| EAN | Produkt | Eco | Nutri | Bio | Fair | Origins | Packaging | E-Score? | S-Score? |"
  echo "|---|---|---|---|---|---|---|---|---|---|"
} > "$OUT"

# Zähler
total=0; in_off=0; missing=0
have_eco=0; have_origins=0; have_packaging=0; have_labels=0
have_e_ok=0; have_s_ok=0

for entry in "${EANS[@]}"; do
  total=$((total+1))
  ean="${entry%%:*}"
  label="${entry#*:}"

  url="${API}/${ean}?fields=${FIELDS}"
  # Retry-Loop: bei Rate-Limit oder Netzfehler 2× warten und neu versuchen
  for attempt in 1 2 3; do
    resp=$(curl -sS -H "User-Agent: ${UA}" "${url}" 2>/dev/null || echo "")
    if echo "$resp" | jq -e . >/dev/null 2>&1; then
      break
    fi
    sleep $((attempt * 2))
  done
  if ! echo "$resp" | jq -e . >/dev/null 2>&1; then
    resp='{"status":0}'
  fi
  status=$(echo "$resp" | jq -r '.status // 0')

  if [[ "$status" -eq 0 ]]; then
    missing=$((missing+1))
    echo "| \`${ean}\` | _${label}_ | ❌ nicht in OFF | | | | | | | |" >> "$OUT"
    continue
  fi

  in_off=$((in_off+1))

  name=$(echo "$resp" | jq -r '.product.product_name // "?"' | head -c 40)
  eco=$(echo "$resp" | jq -r '.product.ecoscore_grade // "-"')
  nutri=$(echo "$resp" | jq -r '.product.nutriscore_grade // "-"')
  has_bio=$(echo "$resp" | jq -r '[.product.labels_tags[]? | select(test("bio|organic"))] | length > 0')
  has_fair=$(echo "$resp" | jq -r '[.product.labels_tags[]? | select(test("fair"))] | length > 0')
  origins=$(echo "$resp" | jq -r '.product.origins // "-"' | head -c 20)
  packaging=$(echo "$resp" | jq -r '.product.packaging // "-"' | head -c 20)

  # E-Score brauchbar? Mindestens ecoscore_grade ODER agribalyse-Daten
  e_ok=$(echo "$resp" | jq -r 'if (.product.ecoscore_grade // empty) != "" or (.product.agribalyse // empty) != null then "✅" else "❌" end')
  # S-Score brauchbar? Mindestens labels ODER origins
  s_ok=$(echo "$resp" | jq -r 'if ((.product.labels_tags // []) | length) > 0 or ((.product.origins // "") | length) > 0 then "✅" else "❌" end')

  [[ "$eco" != "-" && "$eco" != "unknown" && "$eco" != "not-applicable" ]] && have_eco=$((have_eco+1))
  [[ "$origins" != "-" && -n "$origins" ]] && have_origins=$((have_origins+1))
  [[ "$packaging" != "-" && -n "$packaging" ]] && have_packaging=$((have_packaging+1))
  [[ "$has_bio" == "true" || "$has_fair" == "true" ]] && have_labels=$((have_labels+1))
  [[ "$e_ok" == "✅" ]] && have_e_ok=$((have_e_ok+1))
  [[ "$s_ok" == "✅" ]] && have_s_ok=$((have_s_ok+1))

  bio_icon=$([ "$has_bio" = "true" ] && echo "🌱" || echo "—")
  fair_icon=$([ "$has_fair" = "true" ] && echo "🤝" || echo "—")

  printf "| \`%s\` | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
    "$ean" "$name" "$eco" "$nutri" "$bio_icon" "$fair_icon" \
    "${origins:--}" "${packaging:--}" "$e_ok" "$s_ok" >> "$OUT"

  sleep 1.0  # freundlich gegenüber OFF (rate limit safety)
done

# --- Zusammenfassung ---
pct() { awk -v a="$1" -v b="$2" 'BEGIN { if (b==0) print "0"; else printf "%.0f", a*100/b }'; }

{
  echo
  echo "## Zusammenfassung Coverage ($total Produkte)"
  echo
  echo "| Metrik | Anzahl | % |"
  echo "|---|---|---|"
  echo "| In OFF gelistet                | $in_off | $(pct $in_off $total)% |"
  echo "| Nicht in OFF                   | $missing | $(pct $missing $total)% |"
  echo "| Eco-Score vorhanden            | $have_eco | $(pct $have_eco $total)% |"
  echo "| Origins befüllt                | $have_origins | $(pct $have_origins $total)% |"
  echo "| Packaging befüllt              | $have_packaging | $(pct $have_packaging $total)% |"
  echo "| Bio/Fair-Trade-Label vorhanden | $have_labels | $(pct $have_labels $total)% |"
  echo "| **E-Säule berechenbar**        | **$have_e_ok** | **$(pct $have_e_ok $total)%** |"
  echo "| **S-Säule berechenbar**        | **$have_s_ok** | **$(pct $have_s_ok $total)%** |"
  echo
  echo "## Interpretation"
  echo
  e_pct=$(pct $have_e_ok $total)
  s_pct=$(pct $have_s_ok $total)

  if [[ $e_pct -ge 70 && $s_pct -ge 70 ]]; then
    echo "✅ **GO** — OFF-Coverage reicht für MVP. ESG-Formel auf E + S aufbauen."
  elif [[ $e_pct -ge 50 ]]; then
    echo "⚠️ **GO mit Edge-Case-UX** — OFF reicht für die Mehrheit, aber:"
    echo "- ESG-Formel braucht Fallback-Logik (Score nur wenn genug Daten)"
    echo "- UI muss \"Daten unvollständig\" sauber zeigen können"
    echo "- User-Beitrag-Flow (Daten ergänzen) bald nachziehen"
  else
    echo "🚨 **PLAN B nötig** — OFF-Coverage zu dünn:"
    echo "- Eigene DE-Datenbank für Top-100-Produkte aufbauen"
    echo "- Oder: GS1-Lizenz prüfen"
    echo "- Oder: Crowdsource via App-User (Risiko: Daten-Qualität)"
  fi
  echo
  echo "## Nächste Schritte"
  echo
  echo "1. Diese Datei reviewen, Auffälligkeiten markieren"
  echo "2. TODO-002 (ESG-Score-Formel) auf Basis verfügbarer Felder definieren"
  echo "3. RISK-001 Status updaten (mitigated / open)"
} >> "$OUT"

echo "Spike fertig → $OUT"
echo
echo "Quick-Stats:"
echo "  In OFF:          ${in_off}/${total}"
echo "  E berechenbar:   ${have_e_ok}/${total}"
echo "  S berechenbar:   ${have_s_ok}/${total}"
