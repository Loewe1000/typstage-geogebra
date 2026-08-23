#!/usr/bin/env bash
# =============================================================================
# build-site.sh — Handbücher und Beispiele für die eigene Seite
# =============================================================================
# Aufruf aus dem Repo-Wurzelverzeichnis:
#
#     AGGREGAT=/pfad/zu/Typst-Schule TYPSTAGE=/pfad/zu/typstage \
#       bash .github/scripts/build-site.sh
#
# Ergebnis in _site/:
#     index.html, docs.css, typstage-geogebra.pdf     das Handbuch
#     en.html, typstage-geogebra-en.pdf               das englische
#     beispiele/*.html, beispiele/index.html          die Decks zum Anklicken
#
# Zwei fremde Repos werden gebraucht: `schuldocs` für die Doku-Vorlage und den
# Erzeuger der Beispiel-Übersicht (beides im Aggregat), und `typstage` selbst,
# denn ohne den Kern gibt es weder Folien noch Brücke. Beide Abhängigkeiten
# bestehen ohnehin, hier werden sie nur nebeneinandergelegt.
# =============================================================================

set -euo pipefail

WURZEL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGGREGAT="${AGGREGAT:?AGGREGAT muss auf eine Kopie von Typst-Schule zeigen}"
TYPSTAGE="${TYPSTAGE:?TYPSTAGE muss auf eine Kopie von typstage zeigen}"
ZIEL="$WURZEL/_site"
VERSION="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$WURZEL/typst.toml" | head -1)"
TS_VERSION="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$TYPSTAGE/typst.toml" | head -1)"
PAKETPFAD="$(mktemp -d)"

trap 'rm -rf "$PAKETPFAD"' EXIT

# Paketpfad zusammenstellen. `typstage-geogebra` kommt aus *diesem* Stand und
# nicht aus dem Submodul des Aggregats, das älter sein kann; dasselbe gilt für
# den Kern, der als eigenes Repo danebengelegt wird.
mkdir -p "$PAKETPFAD/schule/typstage-geogebra" "$PAKETPFAD/schule/typstage"
cp -R "$AGGREGAT/schuldocs" "$PAKETPFAD/schule/schuldocs"
ln -s "$WURZEL" "$PAKETPFAD/schule/typstage-geogebra/$VERSION"
ln -s "$TYPSTAGE" "$PAKETPFAD/schule/typstage/$TS_VERSION"

rm -rf "$ZIEL"
mkdir -p "$ZIEL"
typst --version
echo "=== typstage-geogebra $VERSION (Kern $TS_VERSION) ==="

# --- Handbücher (Website, Stilvorlage und PDF in einem Bündel-Lauf) ----------
for einstieg in docs.typ manual-en.typ; do
  [[ -f "$WURZEL/docs/$einstieg" ]] || continue
  (
    cd "$WURZEL/docs"
    typst compile \
      --format bundle \
      --features bundle,html \
      --package-path "$PAKETPFAD" \
      --root "$WURZEL" \
      "$einstieg" \
      "$ZIEL" \
      2>&1 | awk '!/^ *warning: (bundle|html) export/ && !/^ *= hint:/ && NF { print }'
    exit "${PIPESTATUS[0]}"
  )
done
[[ -f "$ZIEL/index.html" ]] || { echo "FEHLER: Handbuch ohne index.html" >&2; exit 1; }
echo "  → Handbuch: index.html, docs.css, typstage-geogebra.pdf"
[[ -f "$ZIEL/en.html" ]] && echo "  → Manual (en): en.html, typstage-geogebra-en.pdf"

# --- Beispielpräsentationen -------------------------------------------------
namen=()
mkdir -p "$ZIEL/beispiele"
for bsp in "$WURZEL/examples"/*.typ; do
  [[ -e "$bsp" ]] || continue
  name="$(basename "${bsp%.typ}")"
  (
    cd "$WURZEL/examples"
    typst compile \
      --format html \
      --features html \
      --package-path "$PAKETPFAD" \
      --root "$WURZEL" \
      "$(basename "$bsp")" \
      "$ZIEL/beispiele/$name.html" \
      2>&1 | awk '!/^ *warning: html export/ && !/^ *= hint:/ && NF { print }'
    exit "${PIPESTATUS[0]}"
  ) && [[ -s "$ZIEL/beispiele/$name.html" ]] || {
    echo "FEHLER: Beispiel $name ließ sich nicht bauen" >&2
    exit 1
  }
  namen+=("$name")
done

[[ ${#namen[@]} -gt 0 ]] || { echo "FEHLER: keine Beispiele gebaut" >&2; exit 1; }
BSP_PAKET="typstage-geogebra" BSP_VERSION="$VERSION" BSP_NAMEN="${namen[*]}" \
  python3 "$AGGREGAT/.github/scripts/beispiele-index.py" "$ZIEL/beispiele/index.html"
echo "  → Beispiele: ${#namen[@]} Präsentationen (${namen[*]})"
echo "=== fertig in $ZIEL ==="
