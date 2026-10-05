# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

> この翻訳は簡体字中国語版を基準としており、更新が遅れる場合があります。

AI コーディングエージェント向けの軽量スキルです。不要なキャッシュの削除、不要になった worktree とマージ済みブランチの整理、必要に応じた README / AGENTS / CLAUDE.md などのプロジェクト文書の確認と整理を支援します。

必要な成果物を保護し、文書の正確さ、探しやすさ、実用性を保ちます。空き容量が必要な場合は不要なデータを整理します。許可済みの作業は確認を繰り返さず進め、変更内容に応じて検証します。

## インストール

### Claude Code プラグイン

```bash
claude plugin marketplace add Sorasukiawa/repo-cleanup
```

```bash
claude plugin install repo-cleanup@repo-cleanup
```

セッション内では `/plugin marketplace add Sorasukiawa/repo-cleanup` と `/plugin install repo-cleanup@repo-cleanup` でも同じ操作ができます。更新するときは `claude plugin marketplace update repo-cleanup` の後に `claude plugin update repo-cleanup@repo-cleanup` を実行します。

### skills CLI（Codex または Claude Code）

[skills CLI](https://github.com/vercel-labs/skills) を使い、個人用スキルディレクトリにインストールします。

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent claude-code --global
```

Claude Code ではプラグインと skills CLI のどちらか一方を使ってください。両方を入れると同名のスキルが 2 つ表示されます。

### 手動インストール

手動の場合は、このリポジトリをダウンロードし、`SKILL.md`、`references/`、`scripts/`、`agents/` を個人用スキルディレクトリ（Codex は `~/.agents/skills/`。`~/.codex/skills/` も読み込まれます。Claude Code は `~/.claude/skills/`）内の `repo-cleanup/` に配置してください。`tests/` と `evals/` は保守用です。同名のスキルがある場合は、入手元とローカルの変更内容を先に確認してください。

## 使い方

Codex では `$repo-cleanup` で呼び出します。Claude Code では `/repo-cleanup` を使います（プラグインとして入れた場合の正式名は `/repo-cleanup:repo-cleanup` で、同名のコマンドがなければ短い形で使えます）。`/repo-cleanup 確認のみ` のように範囲を付けることもできます。やりたいことを直接伝えることもできます。

```text
$repo-cleanup を使って、今回の目的に沿ってリポジトリを整理し、README と AGENTS を確認してください。根拠のある問題を修正し、適切な内容はそのまま残してください。
```

確認のみ：`$repo-cleanup を使って、ファイルを変更せずにリポジトリの内容を調べてください。`

「ビルドキャッシュだけ削除」「AGENTS だけ簡素化」「マージ済み worktree を整理し、ブランチは残す」「マージ済みのローカルブランチを削除し、リモートは触らない」のように範囲を限定することもできます。

## 動作方針

- まずモードを判断します。確認のみの場合は完全に読み取り専用です（fetch、ビルド、編集、削除をしません）。実行の場合は許可された範囲を自律的に進め、保留事項は最後にまとめて一度だけ質問します。
- 作業に必要な参考資料だけを読み込みます：容量整理、worktree とブランチ、ホスト管理の worktree、文書、Windows。
- 参照箇所と用途から、ソースコード、キャッシュ、ローカルの機密情報、配布物、過去の資料を区別します。無視設定やファイルの古さだけで削除を判断しません。SKILL.md の「よくある誤判断」表には、誤って削除しやすい例をまとめています（例：`git worktree remove` は ignored の `.env` も削除する）。
- worktree の整理では、まず前提チェック（使用中、ロック中、ホスト管理、未保存の変更や ignored ファイル）を行い、その後マージの証拠を確認します：通常マージ、squash マージ（ローカルの tip が PR の `headRefOid` と一致すること）、detached HEAD。Codex 管理の worktree は標準のアーカイブ機能を使い、Claude Code とデスクトップアプリの worktree はまずホスト側の仕組みに任せます。
- ブランチは既定で残します。削除する場合は `-d` と `-D` をそれぞれの条件で使い分け、復元用に `name sha` を記録します。`[gone]` は手がかりにすぎません。リモートや Issue は自動で変更しません。
- 文書の目標は正確さと使いやすさであり、簡素化は必要に応じて使う手段です。README は読者のために、AGENTS / CLAUDE.md はプロジェクトの判断に必要な長期的な規約のために使い、段階ごとの取り決めは進捗文書に記載します。
- Claude Code では、調査スクリプトと読み取り専用の git、`du`、`df` コマンドを `allowed-tools` で事前に許可しているため、調査中にコマンドごとの許可確認は出ません。削除、取り外し、プッシュ系のコマンドは含みません。
- 報告は判断表（項目、種類、根拠、サイズ、提案または結果）から始め、最後に DONE か PENDING を示します。容量の整理では、ディレクトリ使用量の減少とディスク空き容量の増加を区別します。

`scripts/survey.sh` を使うと、すべての worktree とローカルブランチを一度に読み取り専用で調べられます。

```bash
bash ~/.agents/skills/repo-cleanup/scripts/survey.sh --repo . --base main --sizes
```

上記は skills CLI で Codex にインストールした場合のパスです。`~/.codex/skills/` や `~/.claude/skills/` に置いた場合はそのディレクトリに読み替えてください。プラグインとして入れた場合は、スキルがスクリプトの完全なパスを自動で示します。比較には `--base` の指定が必要で、スクリプトが対象ブランチを推測することはありません。出力は判断材料であり、最終的な判断はスキルの規則に従います。

## ファイル構成

| パス | 役割 |
| --- | --- |
| `SKILL.md` | 英語の実行指示：モード、振り分け、用途の分類、よくある誤判断、報告形式 |
| `.claude-plugin/` | Claude Code のプラグインと marketplace のマニフェスト。リポジトリのルートがプラグインで、`SKILL.md` がその唯一のスキルです |
| `agents/openai.yaml` | Codex の画面に表示する名前、概要、既定のプロンプト |
| `references/space.md` | キャッシュとビルド成果物の整理、エコシステム別の早見表、容量の測定 |
| `references/worktrees.md` | worktree とブランチの整理：前提チェック、マージの証拠、判断表、ブランチ削除 |
| `references/hosts.md` | Codex、Claude Code、Claude デスクトップアプリが管理する worktree |
| `references/docs.md` | README、AGENTS、CLAUDE.md などの文書と規則の整理 |
| `references/windows.md` | ネイティブ PowerShell、Git Bash、WSL |
| `scripts/survey.sh` | 読み取り専用の調査スクリプト |
| `tests/`、`evals/` | テスト用リポジトリ、回帰テスト、動作評価と起動評価 |

対話と報告にはユーザーの言語を使い、指定がない場合は簡体字中国語を使います。4 言語の README は導入用であり、同時に読み込む必要はありません。

## 対象外

- 自動削除プログラムやインストールフックは含みません。`survey.sh` は読み取り専用です。
- リポジトリ外のキャッシュ（Xcode DerivedData、npm / pnpm のグローバルキャッシュ、Docker など）の整理や、インストール済みのエージェントツール・スキルの保守は行いません。
- 既定ではリモートブランチの削除や PR / Issue の更新を行いません。
- 短くするためだけに有用な文書内容を削除することはしません。

## Windows

[Windows 向けガイド](references/windows.md) は、ネイティブの PowerShell 5.1 / 7、Git Bash、WSL に対応した手順を説明します。特殊文字を含むパス、ジャンクション、ファイルのロック、Git の終了コードを扱います。`survey.sh` は Git Bash または WSL で実行でき、ネイティブ PowerShell ではガイド内のコマンドを使います。WSL の導入は不要で、`npx` の使用には Node.js が必要です。

## テストと検証

```bash
bash tests/check-skill.sh
```

```bash
bash tests/test-survey.sh
```

`check-skill.sh` は frontmatter、行数、リンク、バージョン（SKILL.md、plugin.json、CHANGELOG の一致）、JSON ファイル、重要な安全規則を確認します。`CLAUDE_BIN` を設定するか PATH に `claude` がある場合は、公式の `claude plugin validate --strict` も実行します。`test-survey.sh` は一時ディレクトリに 11 種類のシナリオを含むテスト用リポジトリを作成し、調査スクリプトの出力と読み取り専用であること、参考資料が前提とする Git の挙動を検証します。`evals/evals.json` はエージェントで実行する動作テスト、`evals/trigger-evals.json` は起動判定用のクエリで、いずれも [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) と互換性があります（`claude plugin eval` の形式ではありません）。

各バージョンの変更内容と検証範囲は [CHANGELOG.md](CHANGELOG.md) を参照してください。再現可能な事例は Issues にお寄せください。

## 参考とライセンス

文書整理の考え方は [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor) と [claude-md-improver](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management) を参考にしています。worktree の手順は [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo)、[pd:cleanup](https://github.com/peterdrier/skills/tree/main/plugins/pd/skills/cleanup)、[superpowers](https://github.com/obra/superpowers) の finishing-a-development-branch、および参考資料内の Git / GitHub CLI / Claude Code 公式ドキュメントと照合しました。テストの方法は [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) と superpowers の writing-skills を参考にしています。本プロジェクトは独立して保守されています。

[MIT](LICENSE) © 2026 Sorasukiawa.
