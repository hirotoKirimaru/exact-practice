#!/usr/bin/env bash
# EXACT_REV を expo/exact の main の最新コミットに更新する（Exact はリリース・タグを持たず毎日変わる）。
#
#   scripts/bump-exact.sh          main の先頭へ
#   scripts/bump-exact.sh <sha>    指定コミットへ
#
# 更新後は scripts/bootstrap.sh → 各アプリで `bun exact.mjs update` → scripts/verify.sh の順に実行する。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${EXACT_REPO:-https://github.com/expo/exact.git}"
old="$(tr -d '[:space:]' < "$ROOT/EXACT_REV")"
new="${1:-$(git ls-remote "$REPO" refs/heads/main | cut -f1)}"

[[ "$new" =~ ^[0-9a-f]{40}$ ]] || { echo "bump-exact: 40 桁のコミット SHA を指定してください: $new" >&2; exit 1; }
if [ "$old" = "$new" ]; then echo "bump-exact: すでに $new です"; exit 0; fi

echo "$new" > "$ROOT/EXACT_REV"
echo "bump-exact: $old -> $new"
echo "  差分: https://github.com/expo/exact/compare/$old...$new"
