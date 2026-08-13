# Macセットアップ手順

このdotfilesを新しいMacへ導入し、nix-darwinとHome Managerの設定を適用する手順です。現在の構成はApple Siliconの `novumdnoMac-mini` を対象にしています。

## 1. Nixをインストールする

[Determinate Nixの公式セットアップ](https://docs.determinate.systems/getting-started/individuals/)からmacOS用インストーラーを取得して実行します。Determinate NixではFlakeが最初から有効です。

インストール後、新しいターミナルを開いて動作を確認します。

```shell
nix --version
```

このリポジトリでは、Determinate Nixとnix-darwinによるNix管理の競合を避けるため、`modules/darwin/default.nix` で `nix.enable = false` を設定しています。

## 2. リポジトリをcloneする

初回はHTTPSでcloneできます。

```shell
mkdir -p ~/repos
git clone https://github.com/novum-d/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

SSHへ切り替える場合は、[GitHub SSH設定](github-ssh.md)を完了してからリモートURLを変更します。

```shell
git remote set-url origin git@github.com:novum-d/dotfiles.git
```

## 3. ユーザーとホストを設定する

### 既存のMac構成を使用する場合

`config/default.nix` のユーザー名をMacのローカルユーザー名に合わせます。

```nix
{
  username = "your_username";
}
```

現在のホスト名とFlake出力名を確認します。

```shell
scutil --get LocalHostName
nix flake show
```

既存構成は、次の組み合わせです。

- Flake出力: `darwinConfigurations.novumdnoMac-mini`
- ホスト設定: `hosts/Mac-mini/default.nix`
- アーキテクチャ: `aarch64-darwin`

### 別のMacを追加する場合

ホスト名を確認し、サンプルから端末固有設定を作成します。

```shell
HOST_NAME="$(scutil --get LocalHostName)"
mkdir -p "hosts/${HOST_NAME}"
cp hosts/hosts.nix.sample "hosts/${HOST_NAME}/default.nix"
```

続いて `flake.nix` の `darwinConfigurations` に、そのホスト名と `hosts/<ホスト名>` を使う構成を追加します。Intel Macでは、ホスト設定の `nixpkgs.hostPlatform` とFlakeのDarwin用 `system` を `x86_64-darwin` に変更し、Apple Silicon専用のRosetta設定も無効化してください。

## 4. ローカルのGitユーザー情報を設定する

Gitのユーザー名とメールアドレスはNixへ直接書かず、Git管理外の `~/.gitconfig.local` に保存します。

```shell
cp samples/gitconfig.local.sample ~/.gitconfig.local
```

コピー後、`~/.gitconfig.local` の `user.name` と `user.email` を編集します。詳しくは[ローカル個人情報の分離](local-secrets.md)を参照してください。

## 5. 既存ファイルを確認する

Home Managerが管理するファイルと同名のファイルがすでにある場合は、初回activation時に `.backup` へ移動されます。特に `~/.zshrc` など、必要な設定が残っていることを事前に確認してください。

手動でも退避する場合は、次のように実行します。

```shell
mv ~/.zshrc ~/.zshrc.pre-nix
```

## 6. 初回のnix-darwin設定を適用する

初回は `darwin-rebuild` がまだPATHにないため、リポジトリ直下でnix-darwinのFlakeから実行します。

```shell
sudo nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake .#novumdnoMac-mini
```

別のホストを追加した場合は、`novumdnoMac-mini` をそのFlake出力名へ置き換えてください。

初回適用では、Nixパッケージに加えてHomebrew、GUIアプリ、macOS defaults、launchdサービスなども構成されます。

## 7. 設定を更新する

2回目以降は、リポジトリ直下で次のコマンドを実行します。

```shell
git pull
sudo darwin-rebuild switch --flake .#novumdnoMac-mini
```

設定適用後は、リポジトリ直下で `u` エイリアスも使用できます。

```shell
u
```

`u` は `sudo darwin-rebuild switch --flake .` を実行するため、別のディレクトリから使用する場合は明示的にFlakeのパスとホスト名を指定してください。

## 8. 動作を確認する

```shell
command -v darwin-rebuild
git config --global --show-origin --get user.email
nix flake check --no-build
```

Git設定の確認結果に `~/.gitconfig.local` が含まれていれば、ローカル情報の分離も完了しています。

## Obsidian GTDをGoogle Driveへ同期する

macOS構成には、ローカルの `~/repos/obsidian/vault/GTD` を毎週月曜日の12:00に `gdrive:GTD` へ一方向同期するlaunchdジョブが含まれます。事前に次のコマンドで `gdrive` remoteを設定してください。認証トークンはGit管理せず、rcloneのユーザー設定へ保存します。

```shell
rclone config
rclone lsd gdrive:
```

このジョブは `rclone sync` を使用するため、ローカルで削除したファイルはGoogle Drive側からも削除されます。Google Driveのゴミ箱を明示的に使用し、1回の実行で100件を超える削除は停止します。初回や大きな整理の後は、適用前にdry-runで削除対象を確認してください。

```shell
rclone sync ~/repos/obsidian/vault/GTD gdrive:GTD \
  --check-first \
  --create-empty-src-dirs \
  --delete-after \
  --drive-use-trash \
  --max-delete 100 \
  --dry-run
```

設定適用後、ジョブを手動実行する場合は次を使用します。

```shell
launchctl kickstart -k "gui/$(id -u)/org.nixos.obsidian-gtd-google-drive-sync"
```

実行結果は次のログで確認できます。

```shell
tail -f ~/Library/Logs/obsidian-gtd-google-drive-sync.log
tail -f ~/Library/Logs/obsidian-gtd-google-drive-sync.error.log
```

## トラブルシューティング

### `Git tree ... has uncommitted changes`

Flakeを参照しているGitツリーに未コミットの変更があるという警告です。評価失敗の直接原因ではありません。変更内容を確認してください。

```shell
git status --short
```

### Home Managerの対象ファイルが競合する

既存ファイルは通常 `<元の名前>.backup` へ移動されます。バックアップの内容を確認し、必要な設定だけをNix管理側へ移してください。

### `darwin-rebuild` が見つからない

初回適用前はPATHにありません。「初回のnix-darwin設定を適用する」の `nix run` コマンドを使用します。

## 公式ドキュメント

- [Determinate Nix](https://docs.determinate.systems/determinate-nix/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
