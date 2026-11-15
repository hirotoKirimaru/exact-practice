# exact-practice

[expo/exact](https://github.com/expo/exact)（Exact）を手元で試し、検証するためのリポジトリです。

Exact は、UI を小さな宣言型言語 **Contract**（`app.contract`）で書き、データ処理を TypeScript か Rust で書くクロスプラットフォームのアプリ基盤です。
Web では Contract がコンパイルされ、約 20 KB のランタイムが DOM を動かします。macOS・iOS・Linux では Rust のランナーが AppKit・UIKit・GPU で描画します。
1.0 前の段階で API は毎日変わり、リリース・タグ・npm パッケージはありません。そのため、ここでは検証したコミットを `EXACT_REV` に固定し、アプリからはチェックアウトをパスで参照します。

## 構成

```
EXACT_REV                 検証に使う expo/exact のコミット（scripts/bump-exact.sh で更新）
scripts/bootstrap.sh      EXACT_REV の版を vendor/exact に取得し、exact setup を実行する
scripts/verify.sh         apps/* を Web で検証する（contract build + verify web）
scripts/bump-exact.sh     EXACT_REV を main の最新へ更新する
apps/todo/                README の Todo 例（追加・完了・削除）＋テスト 2 件
apps/library/             starter pattern「list-detail」（ルーティング、シート、検索、ファイル保存）＋テスト 8 件
.github/workflows/verify.yml  CI: Ubuntu で bootstrap → verify
vendor/exact/             expo/exact のチェックアウト（git 管理外、bootstrap が作る）
```

## 必要なもの

- Linux または macOS（Web での検証は Linux で可能。macOS・iOS アプリのビルドには Mac と Xcode 27.1 以降が必要）
- `git`、[Bun](https://bun.sh) 1.4.2 以上、[rustup](https://rustup.rs)
- ディスク: 空き 20 GB 程度（`vendor/exact/target` だけで 7〜12 GB、Rust ツールチェーン 2.3 GB）

Chromium、固定版の Rust、wasm-bindgen、Binaryen は `bootstrap.sh` がインストールします。

## 使い方

```bash
scripts/bootstrap.sh
```

```bash
scripts/verify.sh
```

`bootstrap.sh` は初回 10 分前後かかります。`verify.sh` の初回は、Contract コンパイラのビルドに 3 分前後かかります。2 回目以降は 1 アプリ数十秒です。

`verify.sh` は各アプリで次の 2 つを実行し、最後に成否をまとめて表示します。

| ステップ | 内容 |
|---|---|
| `bun exact.mjs contract build app.contract --json --errors-only` | Contract の型・エラー検査（`[]` なら成功）と、`app.ts` の型チェック |
| `bun exact.mjs verify web` | `*.test.contract` の実行、ライト/ダーク × 2 幅での画面検査、アクセシビリティツリー検査、リロード・再起動、最大文字サイズでのはみ出し検査 |

主なオプション:

- `--quick`: `verify web` の代わりに `test web`（テストのみ）を実行する
- `apps/todo`: 指定したアプリだけを検証する
- `--sdk`: Exact 同梱の Caltrain もビルドしてテストする（初回ビルド 8 分前後）

スクリーンショットは `apps/<app>/.exact/verify/*.png` に出力されます。

### アプリを触る

```bash
cd apps/todo && bun exact.mjs web
```

`http://127.0.0.1:8765/` で開きます。`app.contract` を保存すると、0.1 秒程度で再ビルドされリロードされます。

エージェントと同じ方法で、コマンドからアプリを操作できます。

```bash
cd apps/todo && bun exact.mjs agent web tree "type new-todo Milk" "tap add" state "screenshot .exact/out.png"
```

Contract の語彙は次のコマンドで調べられます。

```bash
cd apps/todo && bun exact.mjs contract vocab list-rows search swipe
```

### 新しいアプリを追加する

```bash
bun vendor/exact/scripts/exact.mjs new apps/hello --name Hello --bundle-id com.example.exactpractice.hello
```

```bash
cd apps/hello && bun exact.mjs pattern list-detail
```

`pattern` を引数なしで実行すると、ひな形の一覧が表示されます（`one-screen`、`list-detail`、`tabs`、`dashboard`、`chat`、`rest`、`site`）。
`apps/` に置いたアプリは `verify.sh` の対象に自動で含まれます。アプリを書くときに読むべきガイドは `vendor/exact/docs/start-here.md` の 1 本だけです。

### Exact の版を上げる

```bash
scripts/bump-exact.sh
```

```bash
scripts/bootstrap.sh
```

`bootstrap.sh` の後、各アプリのディレクトリで `bun exact.mjs update` を実行し、最後に `scripts/verify.sh` を実行します。

### ネイティブ（macOS / iOS）

Mac で次を実行します。`--full` を付けると、ネイティブの TypeScript 実行に必要な Hermes なども入ります。

```bash
scripts/bootstrap.sh --full
```

```bash
cd apps/todo && bun exact.mjs mac --run
```

```bash
cd apps/todo && bun exact.mjs ios --run
```

Mac で必要なものが揃っているかは、次のコマンドで確認できます。

```bash
bun vendor/exact/scripts/exact.mjs setup --check --platform ios
```

## 検証結果（2026-11-15、expo/exact@8231e5c、Linux x86_64・4 vCPU）

| 対象 | 結果 |
|---|---|
| `bootstrap.sh`（`setup --platform web`） | 全項目 ok |
| apps/todo: contract build / verify web | 成功（テスト 2/2、検査の指摘 0） |
| apps/library: contract build / verify web | 成功（テスト 8/8、検査の指摘 0） |
| Caltrain: Web ビルド | 成功（8 分強、警告 1 件 `lower-colour-one-scheme`） |
| Caltrain: `app.test.contract` | 3 件中 2 件成功。`"the clock is the driver's"` の `clock +60000` が `Runtime.evaluate did not answer within 60000 ms` で失敗（2 回とも再現） |
| `setup`（全部入り） | Hermes バンドルのダウンロードがクラウドサンドボックスの TLS プロキシで失敗（Hermes の取得処理が独自の証明書ストアを使うため）。Hermes はネイティブでの TypeScript 実行にしか使わないので、Web の検証には影響しない |
| macOS / iOS | 未検証（Mac が必要） |

Caltrain の失敗について、`agent web "clock +1000"` は成功し、`clock +10000` で止まりました。一方、apps/library では `clock +60000` も成功しています。
このため、Caltrain の時刻表示がある画面で時計を大きく進めたときの、Exact 側（またはこの環境の性能）の問題と考えられます。CI では `--sdk` を付けていません。

## 注意

- **フィードバック送信**: Exact には、作業メモ（diary）を Expo に送る仕組みがあります（`bun exact.mjs feedback`）。既定の `ask` では、本人の承認なしに送信されません。`verify.sh` と CI では、念のため `EXACT_FEEDBACK=0` を設定し、確認や送信の案内も止めています。
- **`apps/*/exact.mjs` と `AGENTS.md`**: `exact new` が生成するファイルです。手で編集せず、`bun exact.mjs update` で更新します。
- **`apps/*/app.contract.d.ts`**: ビルド時に生成されるため、git 管理外です。
