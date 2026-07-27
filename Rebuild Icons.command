#!/usr/bin/env bash
#
# Rebuild Icons.command — DOUBLE-CLICK ME from Finder.
#
# Rescans IconsHD/ and rewrites IconsManifest.lua so GB can see any icons you
# added. WoW cannot list files on disk, so something outside the game has to
# build that index — this is it.
#
# After it runs: type /reload in WoW. That's the whole workflow.

cd "$(dirname "$0")" || exit 1

echo "Gloom's Bars — rebuilding the icon manifest"
echo

./tools/build-icon-manifest.sh
status=$?

echo
if [ $status -eq 0 ]; then
  echo "Done. Now type  /reload  in WoW."
else
  echo "Something went wrong (exit $status). Nothing was changed in the game."
fi
echo "You can close this window."
