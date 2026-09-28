# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

AI コーディングエージェント向けの軽量スキルです。不要なキャッシュの削除、不要になった worktree の整理、必要に応じた README / AGENTS などのプロジェクト文書の確認と整理を支援します。

必要な成果物を保護し、文書の正確さ、探しやすさ、実用性を保ちます。空き容量が必要な場合は不要なデータを整理します。許可済みの作業は確認を繰り返さず進め、変更内容に応じて検証します。

## インストール

[skills CLI](https://github.com/vercel-labs/skills) を使い、Codex の個人用スキルディレクトリにインストールします。

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

手動の場合は、このリポジトリをダウンロードし、`SKILL.md`、`references/`、`agents/` を個人用スキルディレクトリ内の `repo-cleanup/` に配置してください。同名のスキルがある場合は、入手元とローカルの変更内容を先に確認してください。

## 使い方

```text
$repo-cleanup を使って、今回の目的に沿ってリポジトリを整理し、README と AGENTS を確認してください。根拠のある問題を修正し、適切な内容はそのまま残してください。
```

確認のみ：`$repo-cleanup を使って、ファイルを変更せずにリポジトリの内容を調べてください。`

「ビルドキャッシュだけ削除」「AGENTS だけ簡素化」「マージ済み worktree を整理し、ブランチは残す」のように範囲を限定することもできます。

## Windows

[Windows 向けガイド](references/windows.md) は、ネイティブの PowerShell 5.1 / 7、Git Bash、WSL に対応した手順を説明します。特殊文字を含むパス、ジャンクション、ファイルのロック、Git の終了コードを扱います。WSL の導入は不要です。インストールコマンドは共通で、`npx` の使用には Node.js が必要です。

公式ドキュメントとの照合とシナリオレビューを実施しています。Windows 実機での検証はまだ行っていません。

## 動作方針

- 参照箇所と用途から、ソースコード、キャッシュ、配布物、過去の資料を区別します。無視設定やファイルの古さだけで削除を判断しません。
- 使用中か、再利用に適しているかを先に確認します。Codex 管理の worktree は標準のアーカイブ機能を使い、通常の Git worktree は固有の成果を保存してから削除します。マージ確認が必要な場合は squash マージ、追加コミット、detached HEAD も考慮します。
- 文書の目標は正確さと使いやすさであり、簡素化は必要に応じて使う手段です。適切な内容は残し、不足情報は補います。README は読者のために、AGENTS はプロジェクトの判断に必要な長期的な規約のために使い、段階ごとの取り決めは進捗文書に記載します。
- 対象リポジトリのコミット規約に従います。ローカルの整理を理由に、リモートの削除や Issue の更新まで自動で行いません。
- 容量の整理では、ディレクトリ使用量の減少とディスク空き容量の増加を区別します。文書だけの整理ではリポジトリ全体の容量調査は不要で、変更内容に応じて検証します。

実行指示は英語の [SKILL.md](SKILL.md) に集約し、worktree やブランチを整理・削除する際には [worktree の参考資料](references/worktrees.md) を読み込みます。対話と報告にはユーザーの言語を使い、指定がない場合は簡体字中国語を使います。4 言語の README は導入用であり、同時に読み込む必要はありません。

これは手順を示すガイドであり、インストールフックや自動削除プログラムは含みません。Codex で形式チェック、隔離リポジトリでの実行・読み取り専用シナリオ、マージ到達可能性、detached コミット、squash マージ、追加コミット、ignored ファイル、無効な参照の Git 検証を実施しています。すべてのエージェント、OS、リポジトリ構成を検証したわけではありません。再現可能な事例は Issues にお寄せください。

今回の文書とアーカイブ手順の更新では、形式、内部リンク、ファイルの一致を確認しました。Codex 管理の worktree のアーカイブと復元は、まだ実行検証していません。

## 参考とライセンス

文書整理の考え方は [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor) を参考にしています。worktree の手順は [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) および参考資料内の Git / GitHub CLI 公式ドキュメントと照合しました。本プロジェクトは独立して保守されています。

[MIT](LICENSE) © 2026 Sorasukiawa.
