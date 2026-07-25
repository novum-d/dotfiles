# Repository Instructions

このファイルはリポジトリ全体に適用するCodex向けの入口です。変更・レビュー・診断を始める前に、ルートの [`prompt.md`](prompt.md) を最後まで読み、対象プラットフォームの構成と検証方法を確認してください。

## 基本方針

- ユーザー向けの説明と作業結果は、特に指定がなければ日本語で記述する。
- 実ファイル、Flake出力、エラーログを確認してから判断し、記憶や推測だけで構成を変更しない。
- 変更前に `git status --short` を確認し、ユーザーの既存変更や無関係な差分を保持する。
- 一時的な手動設定より、既存構成に沿った小さく宣言的なNix変更を優先する。
- macOS、NixOS、WSL、Nix-on-Droidの境界を維持し、1環境向けの修正を無条件に共有層へ入れない。
- APIキー、トークン、パスワード、秘密鍵、個人のGit identityをGit管理対象へ追加しない。
- `config/default.nix` は秘密情報を含まないPure Nix設定専用とする。
- 必要性が実証されない限り `builtins.getEnv`、`.env` 依存、`--impure` を導入しない。
- `flake.lock` は入力更新を意図した場合だけ変更し、手作業で編集しない。
- システムへ影響する `darwin-rebuild switch`、`nixos-rebuild switch`、`nix-on-droid switch` は、ユーザーが適用まで求めた場合だけ実行する。通常は評価・ビルドで検証する。

## 配置の要点

- `flake.nix`: 入力、出力、プラットフォーム間の配線
- `config/default.nix`: 全ホスト共通の公開可能なローカル値
- `hosts/<host>`: 端末固有設定
- `home/base`: 全プラットフォーム共通のHome Manager設定
- `home/base/programs/<tool>`: ツール単位のHome Manager設定
- `home/darwin`: macOS共通のシステム設定とHomebrew
- `home/nix/configuration.nix`: NixOS共通のシステム設定
- `home/nix/default.nix`: Linux系Home Manager設定
- `home/wsl-nixos`: WSL固有設定
- `home/nix-on-droid`: Nix-on-Droid固有設定

## 必須検証

変更内容に応じて最小限から実行し、最終報告に実行結果を記載してください。

```shell
git diff --check
nix shell nixpkgs#nixfmt --command nixfmt --check $(git ls-files '*.nix')
statix check .
nix flake check --no-build --no-warn-dirty
```

新規NixファイルはPure Flake評価から見えるよう、評価前に `git add -N -- <path>` を使用できます。実際にコミットする場合は、対象ファイルだけを明示的にステージしてください。

## Git

- コミットやプッシュはユーザーが明示的に依頼した場合だけ行う。
- `git add .` や無差別な `git add -A` を避け、対象パスを明示する。
- コミット前に `git diff --cached --check` と `git diff --cached --stat` で境界を確認する。
- コミットメッセージは既存履歴に合わせ、簡潔な英語の命令形または変更内容を表す文にする。
- PR作成を依頼されていない場合は、現在のブランチを既存のSSH remoteへプッシュし、勝手にPRを作成しない。

## 指示の更新

ユーザーからリポジトリ運用に関する訂正を受け、その内容が今後も繰り返し適用される場合は、実装と同時に `AGENTS.md` または `prompt.md` の最も近い該当箇所を更新してください。
