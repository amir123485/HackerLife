#!/usr/bin/env bash
# Publish HackerLife to GitHub in one command.
#
# WHY THIS EXISTS: the build environment's token lacked the
# `administration=write` permission required to CREATE a repository,
# so publishing was left to this script.
#
# USAGE:
#   export GITHUB_TOKEN=github_pat_xxx   # needs administration=write (repo creation)
#   ./publish_github.sh [your-username]  # default: amir123485
#
# The script creates the repo, pushes the clean history, and creates the
# v0.1.0 release with build artifacts if they are present.
set -euo pipefail

TOKEN="${GITHUB_TOKEN:?Set GITHUB_TOKEN env var first}"
USER="${1:-amir123485}"
REPO="HackerLife"
API="https://api.github.com"

auth=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json")

echo "== creating repo $USER/$REPO (if missing) =="
code=$(curl -s -o /dev/null -w "%{http_code}" "${auth[@]}" "$API/repos/$USER/$REPO")
if [ "$code" = "404" ]; then
  curl -s -X POST "${auth[@]}" "$API/user/repos" \
    -d "{\"name\":\"$REPO\",\"description\":\"An original 3D hacker-life simulation prototype built with Godot 4.7. All cyber targets are fictional simulations.\",\"private\":false}" \
    | grep -o '"html_url": *"[^"]*"' | head -1
fi

echo "== pushing =="
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:${TOKEN}@github.com/${USER}/${REPO}.git"
git push -u origin HEAD --tags

echo "== release v0.1.0 =="
tag="v0.1.0"
curl -s -X POST "${auth[@]}" "$API/repos/$USER/$REPO/releases" \
  -d "{\"tag_name\":\"$tag\",\"name\":\"$tag — First Playable Slice\",\"body\":\"Initial playable vertical slice. See README.md. All cyber targets are fictional simulations.\",\"draft\":false,\"prerelease\":false}" \
  | grep -o '"id": *[0-9]*' | head -1 > release_id.txt
RID=$(tr -dc '0-9' < release_id.txt)
for f in /path/to/HackerLife_Windows.zip /path/to/HackerLife_Gameplay.mp4 /path/to/HackerLife_Source.zip; do
  [ -f "$f" ] && curl -s -X POST "${auth[@]}" -H "Content-Type: application/zip" \
    --data-binary @"$f" "$API/repos/$USER/$REPO/releases/$RID/assets?name=$(basename "$f")" > /dev/null \
    && echo "uploaded $(basename "$f")"
done
rm -f release_id.txt
echo "== done: https://github.com/$USER/$REPO =="
