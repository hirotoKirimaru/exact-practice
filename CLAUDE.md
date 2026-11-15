# exact-practice

expo/exact（Exact）を検証するためのリポジトリ。README.md に全体像がある。

- 最初に `scripts/bootstrap.sh` を実行する。`EXACT_REV` の版が `vendor/exact` に入り、Web 用のツールが揃う。`vendor/exact` は git 管理外で、編集しない。
- アプリは `apps/<name>/` に置く。各アプリの `CLAUDE.md`（= `AGENTS.md`、`exact new` が生成）が、そのアプリでの作業手順になる。
- 検証は `scripts/verify.sh`（全アプリ）か `scripts/verify.sh apps/<name>`。報告の前に、`apps/<name>/.exact/verify/*.png` のスクリーンショットも確認する。
- `bun exact.mjs feedback note` / `feedback send` は Expo へ送信されうる。ユーザーの承認なしに実行しない。
