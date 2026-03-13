# Nix-Darwin & Nix Flake を使用してmacOSを管理するためのdotfiles

このリポジトリは、 Nix-Darwin と Nix Flake を使用してmacOSを管理するためのdotfilesを提供しています。 これらのdotfilesは、Nix-Darwin を使用してmacOSの設定やパッケージ管理を行うための基本的な構成を含んでいます。

## 1. Determinate Systems からNix をインストールする

Nixをインストールする方法として、他に公式のインストーラーやLixなどもありますが、 今回は[uninstaller](https://zero-to-nix.com/start/uninstall/)を提供していたり、Nix Flakeが最初から有効化されているなど...なにかと便利な[Determinate Systems](https://docs.determinate.systems/determinate-nix/) からNix をインストールする方法を紹介します。

以下のスクリプトをターミナルで実行することで、Determinate Systems経由でNix をインストールできます。

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

インストールが完了したら、以下のコマンドを実行してNixのバージョンを確認してください。

```shell
nix --version                                     
```

以下のようにバージョンが表示されれば、Nixのインストールは成功です。

```shell
$ nix --version                                     
nix (Determinate Nix 3.17.0) 2.33.3
```

## 2. Nix Flake を使用してNix-Darwin をインストールする

Nixのパッケージ・システム設定を再現可能にするNix Flake を使用してmacOS用のNix「Nix-Darwin」をインストールします。

```shell
# Nix-Darwin をインストールするためのディレクトリを作成
sudo mkdir -p /etc/nix-darwin

# 所有者を現在のユーザーに変更
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin

# Nix Flake を初期化して、Nix-Darwin 用のテンプレートファイルを作成
cd /etc/nix-darwin
nix flake init -t nix-darwin/nix-darwin-25.11
sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
```

Nix Flakeの設定ファイルを編集し、macOS用のNix「Nix-Darwin」との競合を避けるため、通常のNixの設定を無効化します。

```shell
{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      nix.enable = false; # ← 通常のNixの設定を無効化
      # ...
```

Nix Flakeの設定ファイルを保存したら、以下のコマンドを実行してNix-Darwin をインストールします。

```shell
sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch
```

> [!WARNING]
>  自身で設定している.zshrcファイルがある場合、Nix-Darwin のインストール中に競合する可能性があるため、事前にバックアップを取ることをお勧めします。
> ```
> mv ~/.zshrc ~/.zshrc.bak
> ```

インストール完了後、ターミナルで新しいタブを開いて、以下のコマンドを実行を実行できることを確認してください。

```shell
sudo darwin-rebuild switch --flake .     
```

## 3. Nix-Darwin を使用したdotfilesをリポジトリからダウンロードする

設定を簡易化するために、Nix-Darwin を使用したdotfilesをダウンロードします。

```shell
mkdir -p ~/repos
cd ~/repos
git clone git@github.com:novum-d/dotfiles.git
```

## 4. Nix-Darwin を使用してmacOSの設定を管理する

まずは、全体のディレクトリ構成を確認してみましょう。

```shell
.
├── ...
├── hosts.nix.sample
├── flake.lock
├── flake.nix
├── home # 各プラットフォームのユーザーレベル（ホーム）の設定
│   ├── base # 全OS共通のパッケージ設定
│   │   ├── default.nix
│   │   └── programs # 各種プログラムの設定
│   │       ├── git
│   │       │   ├── commit_message
│   │       │   └── default.nix
│   │       ├── lazyvim
│   │       │   └── default.nix
│   │       └── zsh
│   │           ├── default.nix
│   │           └── p10k-config
│   │               └── p10k.zsh
│   └── darwin # macOS共通のパッケージ設定
│       └── default.nix
└── hosts # 端末ごとの固有設定（ハードウェア、ユーザー設定など）
    └── m2pro
        └── default.nix
```

あらゆるプラットフォーム・パッケージの設定が共通化されており、端末ごとの固有設定は「hosts」ディレクトリに配置されていることがわかります。

ここでは、使用する環境で個々に分かれる「端末ごとの固有設定（ハードウェア、ユーザー設定など）」をサンプルファイルからコピーして新たに自分用に作成します。

```shell
cd ~/repos/dotfiles
cp hosts.nix.sample hosts/<端末名>/default.nix
```

端末名は、任意の名前を付けることができますが、わかりやすい名前を付けることをお勧めします。 例えば、M2 Proを搭載したMacBook Proの場合は、「m2pro」などの名前を付けると良いでしょう。 

続いて、コピーしたファイル（`hosts/<端末名>/default.nix`）を編集して、自分の環境に合わせた設定を行います。 

ここではユーザー名を変更します。`whoami`コマンドの値を自分のユーザー名に変更してください。  
また、CPUアーキテクチャに応じて、Apple Siliconを搭載したMacの場合は「aarch64-darwin」、Intelを搭載したMacの場合は「x86_64-darwin」を指定します。

```shell
# 端末ごとの固有設定のサンプル
{ ... }:
let
    # TODO: ここを自分のユーザー名に変更
    username = "{{YOUR_USERNAME}}";
in
{
  nixpkgs.hostPlatform = "aarch64-darwin"; # または "x86_64-darwin"
  # ...
}
```

設定が完了したら、flake.nixのoutputsセクションを編集して、自身（ホスト）を追加しましょう。 ここでは、固有のホスト名を指定して、Nix-Darwin の設定を追加します。

ホスト名は、`hostname`コマンドで確認できます。

```shell

{
  description = "NixOS configuration of novumd";
  inputs = {
    # ...
  };
  outputs =
    inputs@{
        # ...
    }:
    {
      darwinConfigurations.m2pro = nix-darwin.lib.darwinSystem {
        # ...
      };
      darwinConfigurations."<ホスト名>" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/m2pro
          ./home/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
```
最後に、以下のコマンドを実行して、Nix-Darwin を使用してmacOSの設定を適用します。

```shell
sudo darwin-rebuild switch --flake . # . または、.#<ホスト名>
```

正常に設定が適用されたことを確認するために、ターミナルで新しいタブを開いて、以下のコマンドを実行してください。

```shell
u # `sudo darwin-rebuild switch --flake .`のエイリアス
```

問題なく実行できれば、Nix-Darwin を使用してmacOSの設定が適用されたことになります。

設定おつかれさまでした...! よき、Nix-Darwin ライフを...! 🚀
