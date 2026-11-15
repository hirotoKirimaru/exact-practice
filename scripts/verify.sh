#!/usr/bin/env bash
# apps/ 以下の Exact アプリを Web ホストで検証する。
#
#   scripts/verify.sh               全アプリ: contract build（型・エラー検査）+ verify web
#   scripts/verify.sh --quick       全アプリ: contract build + test web（*.test.contract のみ）
#   scripts/verify.sh apps/todo     指定したアプリだけ
#   scripts/verify.sh --sdk         Exact 同梱の Caltrain も Web でビルドしてテストする（初回ビルド 8 分前後）
#
# 事前に scripts/bootstrap.sh を一度実行しておくこと。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXACT="$ROOT/vendor/exact"
# Exact は既定で送信前に必ず確認する（docs/diary.md）。ここではヒントや確認も出さない。
export EXACT_FEEDBACK="${EXACT_FEEDBACK:-0}"

mode=verify sdk=0 apps=()
for arg in "$@"; do
  case "$arg" in
    --quick) mode=test ;;
    --sdk) sdk=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) apps+=("$arg") ;;
  esac
done

[ -f "$EXACT/scripts/exact.mjs" ] || { echo "verify: vendor/exact がありません。先に scripts/bootstrap.sh を実行してください" >&2; exit 1; }

if [ ${#apps[@]} -eq 0 ]; then
  for contract in "$ROOT"/apps/*/app.contract; do apps+=("$(dirname "$contract")"); done
fi

failed=()
step() { # step <dir> <label> <command...>
  local dir="$1" label="$2"; shift 2
  echo
  echo "==> $label"
  if (cd "$dir" && "$@"); then echo "<== ok: $label"; else echo "<== FAILED: $label"; failed+=("$label"); fi
}

for app in "${apps[@]}"; do
  app="$(cd "$app" && pwd)"
  name="${app#"$ROOT"/}"
  step "$app" "$name: contract build" bun exact.mjs contract build app.contract --json --errors-only
  if [ "$mode" = verify ]; then
    step "$app" "$name: verify web" bun exact.mjs verify web
  else
    step "$app" "$name: test web" bun exact.mjs test web
  fi
done

if [ "$sdk" = 1 ]; then
  step "$EXACT" "exact: caltrain build web" bun host/web/build.mjs caltrain-web
  step "$EXACT" "exact: caltrain test web" bun scripts/agent.mjs web --test apps/caltrain/app.test.contract
fi

echo
if [ ${#failed[@]} -eq 0 ]; then
  echo "verify: すべて成功"
else
  echo "verify: ${#failed[@]} 件失敗"
  printf '  - %s\n' "${failed[@]}"
  exit 1
fi
