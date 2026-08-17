#!/usr/bin/env bash
# Open Food Facts API Smoke-Test mit 20 DE-Produkten.
# Prüft pro EAN: product_name, brands, nutriments, ecoscore, nutriscore.
# Usage: ./scripts/test_off_api.sh
#
# Lizenz-Hinweis: OFF-Daten sind CC BY-SA — Attribution in der App pflicht.

set -euo pipefail

UA="${OPENFOODFACTS_USER_AGENT:-ScanFair-Smoketest/0.1 (https://github.com/MustDemir/ESG-Score-App)}"
API="https://world.openfoodfacts.org/api/v2/product"
FIELDS="product_name,brands,nutriments,ecoscore_grade,nutriscore_grade,categories_tags,ingredients_text_de,countries_tags"

# 20 reale DE-Supermarkt-Barcodes (Mix: GEPA, Alnatura, Rewe Bio, Mainstream)
EANS=(
  4013189046504  # GEPA Bio Kaffee
  4029764001807  # Club-Mate
  4008258005880  # Alnatura Haferflocken
  4337185513574  # Rewe Bio Hafermilch
  4337256055802  # Rewe Bio Apfelsaft
  4002971022001  # Bionade
  4014721402145  # Alnatura Olivenöl
  4008426010026  # Hipp Bio
  4000400111143  # Milka Schokolade
  5449000000996  # Coca-Cola
  4061458000031  # ja! Wasser
  4337185513543  # Rewe Bio Linsen
  4000539761006  # Rittersport
  4002359005107  # Iglo
  4008208242000  # Maggi
  4008258002001  # Alnatura Reis
  4014500003459  # Frosta
  4017100009129  # Knorr
  4002971008005  # Bionade Holunder
  4000539001253  # Storck
)

ok=0; missing=0; nodata=0
declare -a OK_NAMES
declare -a MISSING_LIST
declare -a NODATA_LIST

for ean in "${EANS[@]}"; do
  url="${API}/${ean}?fields=${FIELDS}"
  resp=$(curl -sS -H "User-Agent: ${UA}" "${url}")
  status=$(echo "$resp" | jq -r '.status // 0')
  name=$(echo "$resp" | jq -r '.product.product_name // empty')

  if [[ "$status" -eq 0 ]]; then
    missing=$((missing+1)); MISSING_LIST+=("$ean"); printf "  ❌ %s   (nicht in OFF)\n" "$ean"
  elif [[ -z "$name" ]]; then
    nodata=$((nodata+1)); NODATA_LIST+=("$ean"); printf "  ⚠️  %s   (gefunden, aber kein Name)\n" "$ean"
  else
    ok=$((ok+1)); OK_NAMES+=("$ean → $name")
    eco=$(echo "$resp" | jq -r '.product.ecoscore_grade // "-"')
    nut=$(echo "$resp" | jq -r '.product.nutriscore_grade // "-"')
    printf "  ✅ %s   eco=%s nutri=%s   %s\n" "$ean" "$eco" "$nut" "$name"
  fi
  sleep 0.2  # rate limit höflich
done

echo
echo "Ergebnis: ${ok}/${#EANS[@]} mit Name · ${nodata} ohne Name · ${missing} nicht gelistet"
echo
echo "→ Wenn ok < ~12: Plan B nötig (eigene DE-Datenbank, Crowdsource via App, GS1)."
