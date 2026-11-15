#!/usr/bin/env bash
# expo/exact を EXACT_REV の版で vendor/exact に取得し、`exact setup` を実行する。
#
#   scripts/bootstrap.sh            取得 + Web 用 setup（Rust/wasm-bindgen/Binaryen/Chromium 等。初回 10 分前後）
#   scripts/bootstrap.sh --check    取得 + Web 用 setup --check（何も変更せず不足を表示）
#   scripts/bootstrap.sh --full     取得 + setup（ネイティブ用 Hermes 等も含む全部）
#   EXACT_REV=<sha> scripts/bootstrap.sh   別の版を一時的に試す
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/vendor/exact"
REPO="${EXACT_REPO:-https://github.com/expo/exact.git}"
REV="${EXACT_REV:-$(tr -d '[:space:]' < "$ROOT/EXACT_REV")}"

for tool in git bun rustup; do
  command -v "$tool" >/dev/null || { echo "bootstrap: $tool が見つかりません（README の「必要なもの」を参照）" >&2; exit 1; }
done

if [ ! -d "$DIR/.git" ]; then
  mkdir -p "$DIR"
  git -C "$DIR" init -q
  git -C "$DIR" remote add origin "$REPO"
fi

if [ "$(git -C "$DIR" rev-parse HEAD 2>/dev/null || true)" != "$REV" ]; then
  if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
    echo "bootstrap: vendor/exact に未コミットの変更があるため版を切り替えません" >&2
    exit 1
  fi
  echo "bootstrap: expo/exact@$REV を取得します"
  git -C "$DIR" fetch --depth 1 origin "$REV"
  git -C "$DIR" -c advice.detachedHead=false checkout -q --detach FETCH_HEAD
fi
echo "bootstrap: vendor/exact = $(git -C "$DIR" log -1 --format='%h %cs %s')"

case "${1:-}" in
  --full) shift; args=("$@") ;;
  --check) shift; args=(--check --platform web "$@") ;;
  *) args=(--platform web "$@") ;;
esac
cd "$DIR"
exec bun scripts/exact.mjs setup "${args[@]}"
