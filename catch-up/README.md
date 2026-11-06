# 追いつき用の patch

テンプレートのブランチでは追いつき用の状態を配らない（テンプレートから作ったリポジトリでは、ブランチ同士の履歴がつながらず、PR を作れないため）。代わりに、復旧点ごとの差分を patch として置き、参加者のリポジトリの `main` の最初のコミット（テンプレートから生成した状態）から派生させる。

| 復旧点 | patch | 含めるもの |
|---|---|---|
| 1-2 | `1-2.patch` | 採否表 `docs/as-is/findings/order-import.md`（F-003 を含む）と、As-Is 文書 `docs/as-is/order-import-module-map.md` |
| 2-1 | `2-1.patch` | 1-2 の内容に加えて、観察ログ `docs/as-is/observations.md`（OBS-001）と、`tests/characterization/order-import.characterization.test.mjs` に足した特性テスト CHAR-ORD-001 |
| 2-2 | `2-2.patch` | 2-1 の内容に加えて、ADR-0001 `docs/adr/0001-order-import-validation.md`（決定済み）と、期待値を埋めて `@Ignore` を外した ACC-001（`wholesale-batch/src/test/java/jp/co/tsubame/wholesale/batch/OrderDuplicateAcceptanceTest.java`。赤） |
| 3-1 | `3-1.patch` | 2-2 の内容に加えて、ISSUE-001 の実装（`OrderGroup.java`）と、ずれた引用の直し。ACC-001 が緑、CHAR-ORD-001 も緑のまま |
| eval-no-doc | `eval-no-doc.patch` | A/B eval の A 側。AGENTS.md、`.github/copilot-instructions.md`、`docs/` を除いた状態 |
| drift-fixture | `drift-fixture.patch` | 第4章の固定の drift（根拠にしたコードを動かす変更）。作り方は下の注意を参照 |

使い方：`sh scripts/catch-up.sh 2-1`（Windows の手元では `pwsh scripts/catch-up.ps1 2-1`）。当たるかだけを確かめるときは `--dry-run` を付ける。

patch は試走で作った完成状態から、テンプレートの `main` との差分として生成する（`git diff <最初のコミット>..<完成状態> > catch-up/2-1.patch`）。各 patch は最初のコミットに単独で当たるように、累積の差分にする。【試走後に作成】

## drift-fixture の注意

drift 検出（`doc-drift.mjs`）が調べるのは、基準の側の文書にある引用だけです。`catch-up.sh` は、`main` の最初のコミットの上に1つのコミットを作ります。文書とコードの移動を1つの patch に入れると、基準（`main` の最初のコミットや、文書のない `main`）には文書がありません。そのため、ずれがあっても終了コードは0（ずれなし）になります（11/06 に一時リポジトリで確認）。

- 文書を入れたコミットの後に、コードを動かすコミットを置く。たとえば、3-1 までの累積を1つ目のコミット、`OrderGroup.java` の重複チェックの移動を2つ目のコミットにする。今の `catch-up.sh` は1つの patch しか当てないので、この形にするには作り直しが要る。
- 比べ方は `--base HEAD~1 --head HEAD` にする（同じ一時リポジトリで、終了コード2と `line-shift` を確認）。4-1 の依頼文の「main とこのブランチを比べ」も、これに合わせる。
- 手順書 `docs/procedures/doc-drift-check.md` は、終了コードが0のときに、基準のコミットに文書があるかを確かめさせる。
