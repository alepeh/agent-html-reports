#!/usr/bin/env bash
#
# Fetch exemplar HTML files from ThariqS/html-effectiveness into references/.
# Upstream currently ships without a LICENSE, so we do NOT vendor these files
# — each user pulls them from upstream on install. See references/NOTICE.md
# for attribution and the legal rationale.

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --quiet https://github.com/ThariqS/html-effectiveness.git "$TMP/upstream"
mkdir -p "$SKILL_DIR/references"
rm -f "$SKILL_DIR/references"/*.html
# Skip the upstream landing page (index.html) — not part of the routing table.
for f in "$TMP/upstream"/*.html; do
  [ "$(basename "$f")" = "index.html" ] && continue
  cp "$f" "$SKILL_DIR/references/"
done
echo "Fetched $(ls "$SKILL_DIR/references"/*.html | wc -l | tr -d ' ') exemplar files from ThariqS/html-effectiveness."
