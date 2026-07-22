# Nix-on-Droid セットアップ

この構成は Android/aarch64 の Pixel 7 Pro 向けです。Nix-on-Droid は Termux の中に追加するパッケージではなく、独立した Android アプリとして動作します。

## 1. Android アプリを導入

1. [F-Droid の Nix-on-Droid](https://f-droid.org/packages/com.termux.nix/) から APK をインストールする。
2. Nix-on-Droid を起動し、初回ダイアログで `OK` を押す。
3. 数百 MB の bootstrap ダウンロードと初期構築が完了するまで待つ。

Android 設定で Nix-on-Droid のバッテリー最適化を無効にすると、初回構築中にプロセスが停止しにくくなります。共有ストレージを使う場合は、アプリ情報からストレージアクセスも許可します。

## 2. dotfiles を適用

Nix-on-Droid のターミナル内で実行します。初回は SSH 鍵がまだないため HTTPS で clone します。

```sh
mkdir -p ~/repos
nix shell nixpkgs#git -c git clone https://github.com/novum-d/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
nix-on-droid switch --flake .#pixel7pro
```

初回の `switch` で `flake.lock` に Nix-on-Droid 入力が追加されます。適用後は zsh がログインシェルになり、このリポジトリ直下で次のエイリアスを使えます。

```sh
u
```

ロールバックは次のとおりです。

```sh
nix-on-droid rollback
```

## 構成の範囲

- Nix-on-Droid: `hosts/pixel7pro/default.nix`
- Home Manager: `home/android/default.nix`
- flake output: `nixOnDroidConfigurations.pixel7pro`

デスクトップ GUI、Android Studio、`scrcpy`、USB デバッグ関連は Android 上の Nix-on-Droid では実用的でないため含めていません。
