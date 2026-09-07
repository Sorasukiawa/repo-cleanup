# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

AI コーディングエージェント向けの軽量スキルです。不要なキャッシュの削除、作業済み worktree の整理、古い説明の修正、README / AGENTS の簡素化を支援します。

必要な成果物を残しながら、ディスク使用量とコンテキストの負担を減らします。許可済みの作業は確認を繰り返さず進め、変更内容に応じて検証します。

## インストール

[skills CLI](https://github.com/vercel-labs/skills) を使い、Codex の個人用スキルディレクトリにインストールします。

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

手動の場合は、このリポジトリをダウンロードし、`SKILL.md`、`references/`、`agents/` を個人用スキルディレクトリ内の `repo-cleanup/` に配置してください。同名のスキルがある場合は、入手元とローカルの変更内容を先に確認してください。

## 使い方

```text
$repo-cleanup を使って、このリポジトリを整理し、古い説明を修正して README と AGENTS を簡潔にしてください。
```

確認のみ：`$repo-cleanup を使って、ファイルを変更せずにリポジトリの内容を調べてください。`

「ビルドキャッシュだけ削除」「AGENTS だけ簡素化」「マージ済み worktree を整理し、ブランチは残す」のように範囲を限定することもできます。

## Windows

[Windows 向けガイド](references/windows.md) は、ネイティブの PowerShell 5.1 / 7、Git Bash、WSL に対応した手順を説明します。特殊文字を含むパス、ジャンクション、ファイルのロック、Git の終了コードを扱います。WSL の導入は不要です。インストールコマンドは共通で、`npx` の使用には Node.js が必要です。

公式ドキュメントとの照合とシナリオレビューを実施しています。Windows 実機での検証はまだ行っていません。

## 動作方針

- 参照箇所と用途から、ソースコード、キャッシュ、配布物、過去の資料を区別します。無視設定やファイルの古さだけで削除を判断しません。
- worktree のマージ状況と固有ファイルを確認します。squash マージ、マージ後のコミット、detached HEAD も考慮します。
- 文書は保持、移動、アーカイブ、削除または統合に分類します。一律の削減率は設けません。
- 対象リポジトリのコミット規約に従います。ローカルの整理を理由に、リモートの削除や Issue の更新まで自動で行いません。
- ディレクトリ使用量の減少とディスク空き容量の増加を区別し、実際の検証結果を報告します。

実行指示は英語の [SKILL.md](SKILL.md) に集約し、[worktree の参考資料](references/worktrees.md) は必要な場合だけ読み込みます。対話と報告にはユーザーの言語を使い、指定がない場合は簡体字中国語を使います。4 言語の README は導入用であり、同時に読み込む必要はありません。

これは手順を示すガイドであり、インストールフックや自動削除プログラムは含みません。Codex で形式チェック、隔離リポジトリでの実行・読み取り専用シナリオ、マージ到達可能性、detached コミット、squash マージ、追加コミット、ignored ファイル、無効な参照の Git 検証を実施しています。すべてのエージェント、OS、リポジトリ構成を検証したわけではありません。再現可能な事例は Issues にお寄せください。

## 参考とライセンス

文書整理の考え方は [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor) を参考にしています。worktree の手順は [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) および参考資料内の Git / GitHub CLI 公式ドキュメントと照合しました。本プロジェクトは独立して保守されています。

[MIT](LICENSE) © 2026 Sorasukiawa.
