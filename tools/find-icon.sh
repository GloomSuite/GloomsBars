#!/usr/bin/env bash
#
# find-icon.sh — given a spellID, find the icon art the game uses for it, and
# optionally copy it into IconsHD/ already named for the manifest.
#
#   ./tools/find-icon.sh 1232995                          just tell me the file
#   ./tools/find-icon.sh 1232995 hunter_mm_fetcheagle      ...and copy it in
#
# WHY THIS EXISTS: a spellID appears nowhere in an icon's filename. The game maps
# spellID -> fileDataID -> interface/icons/<name>.blp, and a loose .tga at that
# path overrides it. So "which file is Fetch: Eagle?" is unanswerable from the
# folder alone — its icon is called inv_111_hunter_ability_featheredfrenzy.
#
# The lookup scrapes Wowhead, which is the practical source for the fileDataID
# listfile the mapping comes from. That makes it FRAGILE BY NATURE: if Wowhead
# changes its markup this stops working, and it is not something to run in bulk.
# It reports and stops rather than guessing whenever the page gives it anything
# other than exactly one icon.

set -euo pipefail
cd "$(dirname "$0")/.."

ICONS_DIR="${GB_ICONS_DIR:-/Applications/World of Warcraft/_retail_/Interface/ICONS}"
DEST="IconsHD"

spell="${1:-}"
label="${2:-}"

if ! [[ "$spell" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 <spellID> [label]" >&2
  echo "  e.g. $0 1232995 hunter_mm_fetcheagle" >&2
  exit 2
fi

echo "looking up spell $spell ..."
html="$(curl -sfL -A "Mozilla/5.0" "https://www.wowhead.com/spell=$spell" || true)"
if [ -z "$html" ]; then
  echo "  could not reach Wowhead (offline, or the spell page does not exist)." >&2
  exit 1
fi

# The page's OWN icon is the one rendered at icons/large/. Related-spell icons
# appear only as bare "icon":"name" keys, so this pattern avoids them.
# NB: read-loop, not `mapfile` — macOS ships bash 3.2, where mapfile does not exist.
names=()
while IFS= read -r n; do
  [ -n "$n" ] && names+=("$n")
done < <(printf '%s' "$html" | grep -oE 'icons/large/[a-z0-9_]+\.jpg' | sed 's|.*/||; s|\.jpg$||' | sort -u)

if [ "${#names[@]}" -eq 0 ]; then
  echo "  no icon found on the page. Wowhead's markup may have changed — check by hand." >&2
  exit 1
fi
if [ "${#names[@]}" -gt 1 ]; then
  echo "  AMBIGUOUS — the page offered ${#names[@]} icons, not guessing:" >&2
  printf '    %s\n' "${names[@]}" >&2
  exit 1
fi

name="${names[0]}"
spellname="$(printf '%s' "$html" | grep -oE '<title>[^<]*' | sed 's|<title>||; s| - Spell.*||' | head -1)"
echo "  spell : ${spellname:-?}"
echo "  icon  : $name"

src="$ICONS_DIR/$name.tga"
if [ ! -f "$src" ]; then
  echo "  NOT in your pack: $src" >&2
  echo "  (the icon exists in-game, but your custom pack has no .tga by that name)" >&2
  exit 1
fi
echo "  file  : $src"

if [ -z "$label" ]; then
  echo
  echo "give a label to copy it in, e.g.:  $0 $spell hunter_mm_something"
  exit 0
fi

mkdir -p "$DEST"
out="$DEST/${label}_${spell}.tga"
if [ -e "$out" ]; then
  echo "  refusing to overwrite existing $out" >&2
  exit 1
fi
cp "$src" "$out"
echo "  copied -> $out"
echo
echo "Now edit it, then double-click \"Rebuild Icons.command\" and /reload."
