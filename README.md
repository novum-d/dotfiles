# dotfiles

Nix Flakeを使用して、macOS、NixOS、WSL、Nix-on-Droidのシステム設定とユーザー環境を管理するdotfilesです。

## 対応環境

| 環境 | Flake出力 | ホスト設定 |
| --- | --- | --- |
| macOS | `darwinConfigurations.novumdnoMac-mini` | `hosts/Mac-mini` |
| NixOS | `nixosConfigurations.nixos` | `hosts/xps15` |
| WSL | `nixosConfigurations.windows-vm` | `hosts/windows-vm` |
| Nix-on-Droid | `nixOnDroidConfigurations.pixel7pro` | `hosts/pixel7pro` |

## 構成

- `config`: Flake全体で共有する、秘密情報を含まないPure Nix設定
- `hosts`: 端末固有のシステム設定
- `home/base`: 全環境で共有するHome Manager設定
- `home/darwin`: macOS共通設定
- `home/nix`: NixOS共通設定
- `home/wsl-nixos`: WSL共通設定
- `home/nix-on-droid`: Nix-on-Droid共通設定
- `docs`: 環境別のセットアップ手順と運用メモ

ユーザー名は [`config/default.nix`](config/default.nix) で一元管理し、Flake評価時に各ホストへ渡します。このファイルには秘密情報を保存しません。

## セットアップ

- [Macセットアップ手順](docs/macos-setup.md)
- [Nix-on-Droidセットアップ手順](docs/nix-on-droid.md)

## 関連ドキュメント

- [GitHub SSH設定](docs/github-ssh.md)
- [ローカル個人情報の分離](docs/local-secrets.md)
- [WSL上のAndroid Studioと実機接続](docs/android-studio-wsl-device.md)
- [Deltaのテーマ設定](docs/delta-theme-fix.md)

## AIエージェント向け作業ルール

- [`AGENTS.md`](AGENTS.md): Codexが自動的に読み込むリポジトリ共通の指示
- [`prompt.md`](prompt.md): モジュール配置、Pure Nix、検証、Git運用の詳細ガイド

## 基本的な検証

リポジトリ全体のFlake出力を評価します。

```shell
nix flake check --no-build
```

Nixファイルのフォーマットを確認します。

```shell
nix shell nixpkgs#nixfmt --command nixfmt --check $(git ls-files '*.nix')
```
