# dotfiles

Nix Flakeを入口に、macOS、NixOS、WSL、Nix-on-Droidのシステム設定とユーザー環境を宣言的に管理するdotfilesです。共通設定とプラットフォーム固有設定を分離し、各ホストの差分を小さく保っています。

## 対応環境

| 環境 | Flake出力 | ホスト設定 |
| --- | --- | --- |
| macOS | `darwinConfigurations.novumdnoMac-mini` | `hosts/Mac-mini` |
| NixOS | `nixosConfigurations.nixos` | `hosts/xps15` |
| WSL | `nixosConfigurations.windows-vm` | `hosts/windows-vm` |
| Nix-on-Droid | `nixOnDroidConfigurations.pixel7pro` | `hosts/pixel7pro` |

## 設計

設定は「ホスト → プラットフォーム → 共通設定」の順に合成します。システム設定とHome Manager設定を別のツリーに置くことで、OS固有のoptionが別環境へ混入しない構成です。

```text
flake.nix
├── hosts/<host>             # 端末固有のハードウェア・値
├── modules/<platform>       # OSのシステム設定
├── home
│   ├── base                 # 全環境共通のユーザー設定
│   ├── darwin               # macOS用Home Manager entrypoint
│   └── linux                # Linux用Home Manager entrypoint
├── lib                      # 複数moduleから使うPure Nixヘルパー
├── config                   # 公開可能な共通値
└── docs                     # 導入・復旧・運用手順
```

主な設計方針は次のとおりです。

- `home/base` は全環境で使えるCLIとユーザー設定だけを持つ。
- `home/darwin` と `home/linux` はOS固有のHome Manager設定を追加する。
- `modules/nixos`、`modules/darwin`、`modules/wsl`、`modules/nix-on-droid` はシステム設定を持つ。
- 重複する生成処理は `lib` のPure Nix関数へ抽出する。
- 秘密情報とGit identityはリポジトリ外のローカル設定へ分離する。

ユーザー名、Codexの既定モデル、Syncthingの公開識別子は [`config/default.nix`](config/default.nix) で一元管理し、Flake評価時に各ホストへ渡します。このファイルには秘密情報を保存しません。

## セットアップ

- [全環境共通の初期チェック](boot-strap.sh): clone後、各OSの手順より先に実行
- [Macセットアップ手順](docs/macos-setup.md)
- [Nix-on-Droidセットアップ手順](docs/nix-on-droid.md)

clone直後は、まず次のチェックを実行します。Nixのインストールやシステムのactivationは行わず、OSごとの前提条件だけを確認します。

```shell
cd ~/repos/dotfiles
./boot-strap.sh
```

## 関連ドキュメント

- [GitHub SSH設定](docs/github-ssh.md)
- [ローカル個人情報の分離](docs/local-secrets.md)
- [WSL上のAndroid Studioと実機接続](docs/android-studio-wsl-device.md)
- [Deltaのテーマ設定](docs/delta-theme-fix.md)

## AIエージェント向け作業ルール

- [`AGENTS.md`](AGENTS.md): Codexが自動的に読み込むリポジトリ共通の指示
- [`prompt.md`](prompt.md): モジュール配置、Pure Nix、検証、Git運用の詳細ガイド

## 検証

変更後は、差分、Nix整形、lint、Flake出力を順に確認します。

```shell
git diff --check
nix shell nixpkgs#nixfmt --command nixfmt --check $(git ls-files '*.nix')
statix check .
nix flake check --no-build --no-warn-dirty
```

各環境の詳しい評価コマンドと、実マシンへ反映する際の注意事項は [`prompt.md`](prompt.md) にまとめています。
