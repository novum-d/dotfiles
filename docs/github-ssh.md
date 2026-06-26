# GitHub SSH 接続のセットアップ手順

別の環境でこの dotfiles を使い、GitHub への `git push` を SSH 鍵で行うための手順。

このリポジトリでは Home Manager の activation で `~/.ssh/id_ed25519` が存在しない場合だけ鍵を生成する。秘密鍵はリポジトリには入れず、各環境の `~/.ssh` にだけ作成する。

## 前提

- 対象環境でこの dotfiles を clone 済み
- GitHub CLI (`gh`) が使える
- GitHub にログインできるブラウザが使える
- NixOS/WSL では `sudo nixos-rebuild switch --flake .#wsl-nixos` を実行できる

## Nix 設定を反映する

対象環境に合わせて Home Manager 設定を反映する。

WSL/NixOS の場合:

```shell
sudo nixos-rebuild switch --flake .#wsl-nixos
```

通常の NixOS の場合:

```shell
sudo nixos-rebuild switch --flake .#nixos
```

macOS の場合:

```shell
sudo darwin-rebuild switch --flake .#novumdnoMac-mini
```

反映後、`~/.ssh/id_ed25519` と `~/.ssh/id_ed25519.pub` が作成されていることを確認する。

```shell
ls -la ~/.ssh
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

`~/.ssh/config` には `github.com` 用の設定が生成される。

```shell
ssh -G github.com | rg '^(user|identityfile) '
```

期待値:

```text
user git
identityfile ~/.ssh/id_ed25519
```

## GitHub CLI の認証を確認する

`gh` の認証状態を確認する。

```shell
gh auth status
```

未ログインの場合はログインする。

```shell
gh auth login -h github.com
```

公開鍵を追加するには `admin:public_key` scope が必要。足りない場合は追加する。

```shell
gh auth refresh -h github.com -s admin:public_key
```

ブラウザで GitHub のデバイス認証が表示された場合は、画面の指示に従って承認する。

## 公開鍵を GitHub に追加する

生成された公開鍵を GitHub アカウントに登録する。

```shell
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
```

同じ鍵がすでに登録済みの場合は、GitHub 側の SSH keys を確認して重複登録を避ける。

```shell
gh ssh-key list
```

## SSH 接続を確認する

GitHub に SSH で認証できるか確認する。

```shell
ssh -T git@github.com
```

初回は known hosts への追加確認が出る。成功時は次のような表示になる。

```text
Hi novum-d! You've successfully authenticated, but GitHub does not provide shell access.
```

`Permission denied (publickey)` になる場合は、次を確認する。

- `~/.ssh/id_ed25519.pub` が GitHub に登録されている
- `~/.ssh/config` の `github.com` が `IdentityFile ~/.ssh/id_ed25519` を指している
- `chmod 600 ~/.ssh/id_ed25519`、`chmod 700 ~/.ssh` になっている

## Git remote を SSH に変更する

`git push` でユーザー名とパスワードを聞かれる場合、remote が HTTPS のままになっている。

現在の remote を確認する。

```shell
git remote -v
```

HTTPS になっている例:

```text
origin  https://github.com/novum-d/dotfiles (fetch)
origin  https://github.com/novum-d/dotfiles (push)
```

SSH URL に変更する。

```shell
git remote set-url origin git@github.com:novum-d/dotfiles.git
```

変更後:

```text
origin  git@github.com:novum-d/dotfiles.git (fetch)
origin  git@github.com:novum-d/dotfiles.git (push)
```

push の dry-run で認証できるか確認する。

```shell
git push --dry-run
```

ユーザー名とパスワードを聞かれずに `To github.com:novum-d/dotfiles.git` のように表示されれば完了。
