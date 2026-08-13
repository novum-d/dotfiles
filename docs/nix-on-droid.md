# Nix-on-Droid セットアップ手順

Android 上の Nix-on-Droid にこの dotfiles を導入し、Flake の設定を反映する手順。

## 設定構成

- `hosts/pixel7pro`: Pixel 7 Pro 固有の設定
- `modules/nix-on-droid`: Nix-on-Droid 端末で共有するシステム設定
- `home/base`: 全環境で共有するHome Manager設定
- `nixOnDroidConfigurations.pixel7pro`: Pixel 7 Pro 用の Flake 出力
- `nixOnDroidConfigurations.default`: `pixel7pro` を指す互換用の別名

## 前提

- `aarch64` の Android 端末に Nix-on-Droid をインストール済み
- 初回セットアップが完了し、`nix --version` が実行できる
- GitHub へ接続できる

リポジトリは共有ストレージではなく、Nix-on-Droid のホームディレクトリ以下に配置する。

## リポジトリを clone する

初期環境には Git がない場合があるため、`nix shell` から一時的に Git を使用する。

```shell
mkdir -p ~/repos

nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command git clone https://github.com/novum-d/dotfiles.git ~/repos/dotfiles

cd ~/repos/dotfiles
```

すでに clone 済みの場合は、リポジトリへ移動して最新版を取得する。

```shell
cd ~/repos/dotfiles

nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command git pull
```

## 共通の初期チェック

clone後、設定を反映する前に全環境共通のpreflightを実行します。

```shell
./boot-strap.sh
```

GitまたはNixがまだ使えない初期状態では、上記の一時的な `nix shell` を先に使います。

## 設定を反映する

リポジトリ直下で実行する。

```shell
nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command nix-on-droid switch --flake .#pixel7pro
```

activation が最後まで完了したら、新しいターミナルを開いて設定を確認する。設定反映後は、次のエイリアスも使用できる。

```shell
u
```

ログインシェルは zsh に設定される。新しいターミナルで次のように確認できる。

```shell
echo "$SHELL"
```

## Herdr で Codex を上下に並べる

Home Manager の共通 `home/base` 設定により、Herdr と Codex も導入される。リポジトリの作業ディレクトリで Herdr を起動する。

```shell
herdr
```

Herdr のペイン内で次のいずれかを実行すると、縦画面を上下に分割して両方のペインで Codex が起動する。

```shell
hcodex-duo
# または
hmobile
# または
hphone
```

同じ初期プロンプトを両方へ渡す場合は、引数に指定する。

```shell
hmobile "このリポジトリの構成を確認して"
```

各ロールは、同じ作業ディレクトリで前回使用した同じロールのCodexセッションを自動的に再開する。たとえばPMは前回のPM、iOSは前回のiOSの履歴を引き継ぎ、ロール間では共有しない。引数を指定した場合は、再開したセッションへの新しい依頼として渡される。

`hmobile` はPM、Architect、iOSに同じ起動サフィックスを持つ専用のHerdrエージェント名を使う。実行元のペインも `codex-pm-<suffix>` に更新される。起動プロンプトを変更した場合は名前のrevisionも更新し、古い mobile duo セッションを再利用しない。

Codexと各Herdrロールは `config/default.nix` の `codexModels` を正本として、`gpt-5.6-sol`、reasoning effort `high` を使用する。利用可能モデル一覧にこの組み合わせがない場合だけ、`gpt-5.5`、`high` へフォールバックする。

通常の開始報告ではモデル名やreasoning effortを表示しない。確認が必要な場合は、セッション内の `CODEX_CONFIGURED_MODEL` と `CODEX_CONFIGURED_REASONING_EFFORT` を使用する。Codexのベース指示に表示される「GPT-5」はモデルファミリーの表記であり、実効モデルが `gpt-5.6-sol` ではないことを意味しない。

## 日本語を入力できるようにする

Nix-on-Droidの通常のターミナル画面は、Gboardの日本語12キーによる直接入力に対応していない。日本語はTermux由来のText Input Viewから入力する。

1. Gboardの「設定」→「言語」→「日本語」で「12キー」を有効にする。
2. Nix-on-Droidへ戻り、ソフトウェアキーボード上部の特殊キー列（`ESC`、`CTRL`、矢印など）を左へスワイプする。
3. 表示されたText Input Viewをタップする。通常のテキスト入力欄として扱われるため、Gboardの日本語12キーが表示される。
4. 日本語を入力してEnterを押すと、入力内容がターミナルへ送信される。コマンドを実行する場合はもう一度Enterを押す。

特殊キー列へ戻すにはText Input Viewを右へスワイプする。

## 設定を更新する

通常の更新は、`git pull` の後に `switch` を実行する。

```shell
cd ~/repos/dotfiles

nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command git pull

nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command nix-on-droid switch --flake .#pixel7pro
```

`util-linux` や `script` は不要。TTY を外側から追加しても、後述の既知不具合は解消しない。

## nix-on-droid#495 の回避策

Nix-on-Droid release-24.05 の古い `proot-static` は、glibc 2.42を使用する新しい nixpkgs と互換性がない。activation の `installPackages` で、次のエラーが発生する。

```text
error: getting pseudoterminal attributes: Permission denied
error: unexpected EOF reading a line
```

このリポジトリでは、Droidで使用する入力だけを既知の動作するリビジョンへ固定している。

- `nixpkgs-droid`: `88d3861acdd3d2f0e361767018218e51810df8a1`
  - glibc 2.40を使用する、報告済みの最終動作リビジョン
- `home-manager-droid`: `2539eba97a6df237d75617c25cd2dbef92df3d5b`
  - 固定した nixpkgs と同時期のHome Manager

macOS、NixOS、WSL用の `nixpkgs` と Home Manager は固定対象ではない。

固定状態は次のコマンドで確認できる。

```shell
grep -n '88d3861acdd3d2f0e361767018218e51810df8a1' flake.lock
grep -n '2539eba97a6df237d75617c25cd2dbef92df3d5b' flake.lock
```

関連情報:

- [nix-community/nix-on-droid#495](https://github.com/nix-community/nix-on-droid/issues/495)
- [既存環境で発生する理由と復旧手順](https://github.com/nix-community/nix-on-droid/issues/495#issuecomment-4907964650)

## トラブルシューティング

### `getting pseudoterminal attributes: Permission denied`

最新の設定と正しいロックファイルを取得しているか確認する。

```shell
git log -1 --oneline
grep -n '88d3861acdd3d2f0e361767018218e51810df8a1' flake.lock
```

固定が表示されない場合は `git pull` 後に再度 `switch` する。

失敗したactivationは `installLoginInner` の更新を途中まで配置することがある。修正版を反映できるまでは、可能ならNix-on-Droidの全ターミナルを閉じず、現在のセッションから復旧作業を続ける。

### `lib/services/lib.nix: No such file or directory`

新しい Home Manager と古い nixpkgs の組み合わせが原因。`home-manager-droid` の固定を含む最新版を `git pull` し、再度 `switch` する。

### `Git tree ... is dirty`

未コミットのローカル変更があるという警告。TTYエラーの直接原因ではない。変更内容を確認する。

```shell
nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command git status --short
```

必要な変更を誤って消さないよう、内容を確認せずに `git reset --hard` を実行しない。

### `system has been renamed`

```text
trace: evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
```

これは評価時の警告で、activation失敗の直接原因ではない。

## 再インストールについて

activation の途中で失敗しただけなら、通常は `/nix/store` の削除やNix-on-Droidの再インストールは不要。最新版を取得して `switch` をやり直す。
