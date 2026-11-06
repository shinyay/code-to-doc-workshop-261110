# 追いつき用の patch

テンプレートのブランチでは追いつき用の状態を配らない（テンプレートから作ったリポジトリでは、ブランチ同士の履歴がつながらず、PR を作れないため）。代わりに、復旧点ごとの差分を patch として置き、参加者のリポジトリの `main` の最初のコミット（テンプレートから生成した状態）から派生させる。

| 復旧点 | patch | 含めるもの |
|---|---|---|
| 1-2 | `1-2.patch` | 採否表（F-003 を含む）と As-Is 文書 |
| 2-1 | `2-1.patch` | 観察ログ OBS-001 と特性テスト CHAR-ORD-001 |
| 2-2 | `2-2.patch` | ADR-0001（決定済み）と受け入れテスト ACC-001（赤） |
| 3-1 | `3-1.patch` | ISSUE-001 の実装（ACC-001 が緑） |
| eval-no-doc | `eval-no-doc.patch` | A/B eval の A 側。AGENTS.md、`.github/copilot-instructions.md`、`docs/` を除いた状態 |
| drift-fixture | `drift-fixture.patch` | 第4章の固定の drift（根拠にしたコードを動かす変更） |

使い方：`sh scripts/catch-up.sh 2-1`（Windows の手元では `pwsh scripts/catch-up.ps1 2-1`）。当たるかだけを確かめるときは `--dry-run` を付ける。

patch は試走で作った完成状態から、テンプレートの `main` との差分として生成する（`git diff <最初のコミット>..<完成状態> > catch-up/2-1.patch`）。各 patch は最初のコミットに単独で当たるように、累積の差分にする。【試走後に作成】
