# Codex作業ガイド

この文書は、このdotfilesリポジトリで調査、実装、レビュー、検証、公開を行うための詳細な作業規約です。Codexはルートの `AGENTS.md` を入口として本書を読み、現在のファイルとユーザーの指示を優先して作業します。

## 1. リポジトリの目的

このリポジトリは、Nix Flakeを入口として次の環境を宣言的に管理します。

| 環境 | Flake出力 | ホスト設定 |
| --- | --- | --- |
| macOS | `darwinConfigurations.novumdnoMac-mini` | `hosts/Mac-mini` |
| NixOS | `nixosConfigurations.nixos` | `hosts/xps15` |
| WSL | `nixosConfigurations.windows-vm` | `hosts/windows-vm` |
| Nix-on-Droid | `nixOnDroidConfigurations.pixel7pro` | `hosts/pixel7pro` |

Home Managerの共通設定は `home/base` に集約し、OSや端末に固有の差分だけを外側のモジュールで追加します。設定変更では、再現可能性、Pure評価、プラットフォーム間の責務分離を維持してください。

## 2. 作業開始時の確認

1. `git status --short` と `git diff` で既存変更を確認する。
2. `flake.nix` と対象モジュールのimport経路を確認する。
3. 対象がmacOS、NixOS、WSL、Nix-on-Droid、または全環境のどれかを明確にする。
4. 関連する `docs/` とサンプル設定を確認する。
5. 外部仕様やパッケージ状態が関係する場合は、公式ドキュメントや実際のNix評価で確認する。

ユーザーの既存差分は所有物として扱い、関係のない整形、移動、削除、コミットへの混入を行いません。

## 3. タスク別の行動

### 説明・レビュー

- 読み取りと評価に留め、依頼されていない編集やシステム適用を行わない。
- レビューでは要約より先に、重要度順の具体的な指摘を示す。
- 問題がない場合も、確認範囲と残るリスクを明示する。

### 診断

- エラー全文、実効値、生成済み設定を確認して原因を特定する。
- 評価エラー、ビルドエラー、activationエラー、実行時エラーを区別する。
- 修正まで依頼されていない場合は、原因と修正方針の提示に留める。

### 変更

- 既存モジュール構造に沿った最小差分で実装する。
- 一時的なshell exportや手動設定だけで終わらせず、継続的に必要な設定はNixで管理する。
- ただし認証状態、秘密情報、端末ごとの非公開値はNix StoreやGitへ入れない。
- 振る舞いを変更した場合は、README、`docs/`、サンプル、エージェント指示の同期要否を確認する。

### コミット・プッシュ

- ユーザーから明示された場合だけ実行する。
- 作業開始時から存在した無関係な変更を含めない。
- 対象パスを明示してステージし、cached diffを確認してからコミットする。
- このリポジトリでは通常 `master` をSSH remoteの `origin` へ直接プッシュする。別ブランチやPRを求められた場合は、その指示を優先する。

## 4. モジュール配置ルール

| 変更内容 | 配置先 |
| --- | --- |
| Flake input、output、`specialArgs`、全体配線 | `flake.nix` |
| 公開可能な共通ユーザー値 | `config/default.nix` |
| 全環境共通のCLIパッケージ | `home/base/default.nix` |
| ツール固有の設定 | `home/base/programs/<tool>/default.nix` |
| macOS defaults、Homebrew、launchd | `home/darwin/default.nix` |
| NixOS共通のsystem設定 | `home/nix/configuration.nix` |
| Linux系のHome Manager設定 | `home/nix/default.nix` |
| WSL固有のinterop、USB、GUI起動 | `home/wsl-nixos/default.nix` |
| Nix-on-Droid固有の端末・activation設定 | `home/nix-on-droid/default.nix` |
| ハードウェア、ホスト名、端末固有override | `hosts/<host>` |
| 導入・復旧・運用手順 | `docs/` |

### パッケージ追加

- 複数環境で必要なCLIは `home/base` へ置く。
- 設定を伴うツールは専用モジュールを作成し、`home/base/default.nix` からimportする。
- macOSのGUIアプリは原則 `home/darwin/default.nix` のHomebrew caskで管理する。
- Linuxだけで利用可能なパッケージには `lib.optionals` または `lib.meta.availableOn` を使う。
- AI系CLIは、特別な理由がない限り `nixpkgs-unstable` の `unstable` から取得する。
- 同じパッケージをsystem packages、Home Manager、Homebrewへ重複配置しない。

### CodexとHerdr

- CodexとHerdrロールの既定モデルは `gpt-5.6-sol`、reasoning effortは `high` とする。
- 利用可能モデル一覧に既定モデルがない場合だけ `gpt-5.5`、`high` へフォールバックする。
- モデル一覧を取得できない場合は、ネットワーク障害などをモデル未提供と誤認せず、既定モデルで起動を試みる。
- Herdrロールは、作業ディレクトリとロールが一致する直近のCodexセッションを再開する。PM、Architect、iOSなど異なるロールの履歴を混在させない。

### シェルスクリプト

- 再現可能なコマンドは `pkgs.writeShellScriptBin` を優先する。
- `set -eu` を基本とし、引数を `"$@"` で保持する。
- Darwin、Linux、WSLのコマンド差は実行時またはNix評価時に明示的に分岐する。
- Nixの複数行文字列内でshell変数を書く場合は、Nix展開とshell展開を混同しない。

## 5. Pure Nixと秘密情報

- ユーザー名は `config/default.nix` で管理し、Flakeから各ホストへ渡す。
- `config/default.nix` はGit管理対象であり、秘密情報を含めない。
- Pure評価を維持するため、環境変数や `.env` をFlake評価の入力にしない。
- `builtins.getEnv` や `--impure` は、代替不能な理由と影響範囲を説明できる場合だけ検討する。
- Gitの `user.name` と `user.email` は `~/.gitconfig.local` に置く。
- APIキー、トークン、パスワード、秘密鍵はコミットせず、必要ならsops/ageなどの秘密管理方式を別途設計する。
- 秘密を平文のNix式へ書くとNix Storeに残る可能性があるため禁止する。

## 6. プラットフォーム固有の注意

### macOS

- `home/darwin/default.nix` ではDeterminate Nixとの競合を避けるため `nix.enable = false` を維持する。
- `nix-homebrew` はApple Silicon側とRosetta側のprefixを管理している。
- `homebrew.onActivation.cleanup = "zap"` のため、cask削除は次回activationで実アプリの削除につながる。削除対象を明確に確認する。
- 初回導入と通常更新は `docs/macos-setup.md` を正本とする。

### NixOS

- `home/nix/configuration.nix` は共通のNixOS system moduleである。
- `home/nix/default.nix` はHome Manager entrypointであり、system設定を置かない。
- `hosts/xps15` にはハードウェアとNVIDIA固有設定があるため、共有層へ移す前に他ホストへの影響を確認する。

### WSL

- Flake出力名とホスト名は `windows-vm` である。
- WSL固有のWindows interop、`wsl-open`、USB auto-attach、Android Studio起動処理は `home/wsl-nixos` と `hosts/windows-vm` に保つ。
- Windows側のPowerShell資材は `windows/` に置き、Nixモジュールと役割を混在させない。

### Nix-on-Droid

- Flake出力名は `pixel7pro` で、`default` はその別名である。
- `nixpkgs-droid` と `home-manager-droid` は既知のPRoot互換性問題を避けるため固定されている。通常の入力更新に巻き込まない。
- macOSからDroid構成全体をrealizeできない場合があるため、`config.user.shell` などの狭い評価を使用する。
- 詳細な復旧手順は `docs/nix-on-droid.md` を参照する。

## 7. 検証

### 共通

```shell
git diff --check
statix check .
nix shell nixpkgs#nixfmt --command nixfmt --check $(git ls-files '*.nix')
nix flake check --no-build --no-warn-dirty
```

`nix fmt` は現在 `formatter.aarch64-darwin` を公開していないため、macOSでは検証コマンドとして使用しません。

### 対象別の評価

```shell
# macOS
nix eval --raw \
  .#darwinConfigurations.novumdnoMac-mini.config.system.build.toplevel.drvPath

# NixOS
nix eval --raw \
  .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath

# WSL
nix eval --raw \
  .#nixosConfigurations.windows-vm.config.system.build.toplevel.drvPath

# Nix-on-Droid
nix eval --raw \
  .#nixOnDroidConfigurations.pixel7pro.config.user.shell
```

変更がshell文字列を生成する場合は、評価後の実効値を取り出し、可能なら `zsh -n`、`shellcheck`、または対象コマンドのdry-runでも確認します。

新規ファイルがFlakeから参照される場合、未追跡のままでは評価対象に入らないことがあります。

```shell
git add -N -- path/to/new-file.nix
```

これはintent-to-addであり、コミット前には改めてステージ済み差分を確認してください。

### activation

次のコマンドは実マシンを変更するため、ユーザーが適用を求めた場合だけ実行します。

```shell
sudo darwin-rebuild switch --flake .#novumdnoMac-mini
sudo nixos-rebuild switch --flake .#nixos
sudo nixos-rebuild switch --flake .#windows-vm
nix-on-droid switch --flake .#pixel7pro
```

## 8. ドキュメント

- READMEは全環境の入口に保ち、環境固有の長い手順は `docs/` に置く。
- コマンド、ホスト名、Flake出力、ファイルパスは実在を確認してから記載する。
- バージョン番号を固定して書く場合は、`flake.nix` または `flake.lock` と一致させる。
- 設定の正本を重複させず、詳細文書へのリンクを使う。
- 古いツールや削除済みモジュールを例に残さない。

## 9. Git公開前チェック

```shell
git status --short
git diff --check
git diff --stat
git add -- <対象パス...>
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
```

コミット後は次を確認します。

```shell
git push origin <current-branch>
git status -sb
git rev-list --left-right --count HEAD...origin/<current-branch>
```

GitHub CLIの認証が無効でもSSH remoteが利用できる場合があります。PR操作を求められていない通常のpushでは、`gh auth status` だけを理由に作業を止めず、SSH pushの結果で判断します。

## 10. 完了条件

- 依頼された変更が既存構造に沿って実装されている。
- 対象外の差分を変更・削除・ステージしていない。
- Pure評価と秘密情報の境界を維持している。
- 変更範囲に適したformat、lint、Flake評価が成功している。
- 実行できなかった検証と理由、残るリスクを報告している。
- ユーザーがコミット・プッシュを依頼した場合、remoteとの同期まで確認している。
