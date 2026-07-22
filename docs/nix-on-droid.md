# Nix-on-Droid セットアップ手順

Android 上の Nix-on-Droid にこの dotfiles を導入し、Flake の設定を反映する手順。

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

## 設定を反映する

リポジトリ直下で実行する。

```shell
nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command nix-on-droid switch --flake .
```

activation が最後まで完了したら、新しいターミナルを開いて設定を確認する。設定反映後は、次のエイリアスも使用できる。

```shell
u
```

## 日本語を入力できるようにする

このリポジトリは `~/.termux/termux.properties` に次の設定を反映する。

```properties
enforce-char-based-input = true
```

Android の日本語IMEが生成した文字列を、個別のキーイベントではなく文字としてターミナルへ渡すための設定。既存の `termux.properties` がある場合は、初回activation時に `termux.properties.bak` へ退避する。

`switch` が完了したら設定を再読み込みする。

```shell
termux-reload-settings
```

その後、GboardなどのAndroid側キーボードを日本語入力へ切り替える。反映されない場合は、Nix-on-Droidの全セッションを閉じてアプリを起動し直す。

## 設定を更新する

通常の更新は、`git pull` の後に `switch` を実行する。

```shell
cd ~/repos/dotfiles

nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command git pull

nix shell github:NixOS/nixpkgs/nixpkgs-unstable#git \
  --command nix-on-droid switch --flake .
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
