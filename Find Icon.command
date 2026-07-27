#!/usr/bin/env bash
#
# Find Icon.command — DOUBLE-CLICK ME from Finder.
#
# You have a spellID but cannot find its artwork, because the spellID appears
# nowhere in the icon's filename. This asks for the spellID, finds the real icon
# file, copies it into IconsHD/ already named correctly, and opens the folder so
# you can drag it straight into Photoshop.

cd "$(dirname "$0")" || exit 1

echo "Gloom's Bars — find an icon by spellID"
echo "======================================"
echo

printf "SpellID (from the tooltip): "
read -r spell
echo

case "$spell" in
  ''|*[!0-9]*)
    echo "That isn't a number. Copy the SpellID line from the in-game tooltip."
    echo
    echo "Press return to close."
    read -r _
    exit 1
    ;;
esac

# First pass: show what it found, without copying anything. The helper's closing
# hint tells you to run it from a terminal, which is not this flow — drop it.
out="$(./tools/find-icon.sh "$spell" 2>&1)"; st=$?
printf '%s\n' "$out" | grep -v 'give a label to copy it in'
if [ $st -ne 0 ]; then
  echo
  echo "Press return to close."
  read -r _
  exit 1
fi

echo
echo "Name it. Use  class_spec_spellname  — the spellID gets added for you."
echo "  e.g.  hunter_mm_fetcheagle"
printf "Name: "
read -r label
echo

if [ -z "$label" ]; then
  echo "No name given, so nothing was copied."
  echo
  echo "Press return to close."
  read -r _
  exit 1
fi

# Spaces and odd characters would break the manifest scan; normalise quietly.
label="$(printf '%s' "$label" | tr ' ' '_' | tr -cd '[:alnum:]_-')"

# Second pass copies it. Filter the lookup lines already shown above.
out="$(./tools/find-icon.sh "$spell" "$label" 2>&1)"; st=$?
printf '%s\n' "$out" | grep -vE '^(looking up|  spell :|  icon  :|  file  :)$|^looking up|^  (spell|icon|file) '
if [ $st -eq 0 ]; then
  echo
  echo "Opening the folder — drag the file into Photoshop from there."
  open IconsHD 2>/dev/null
  echo
  echo "When you've finished editing it:"
  echo "  1. double-click  \"Rebuild Icons.command\""
  echo "  2. type  /reload  in WoW"
fi

echo
echo "Press return to close."
read -r _
