# ローカル個人情報の分離

このリポジトリでは、公開・共有するdotfilesにGitのユーザー名やメールアドレスを直接書かず、各端末の `~/.gitconfig.local` に分離します。

## 管理方針

- Git管理する設定には、共有して問題ないデフォルトだけを置く。
- Gitの `user.name` / `user.email` は `~/.gitconfig.local` に置く。
- APIキー、トークン、パスワード、秘密鍵はdotfilesにも `.local` にも直書きせず、1Password、Bitwarden、sops、ageなどで管理する。
- `*.local` と `*.local.*` は `.gitignore` で除外する。

## 初回セットアップ

サンプルをコピーします。

```sh
cp samples/gitconfig.local.sample ~/.gitconfig.local
```

`~/.gitconfig.local` を自分の値に変更します。

```ini
[user]
  name = Your Name
  email = you@example.com
```

NixOSまたはnix-darwinでシステム設定を適用します。

```sh
sudo nixos-rebuild switch --flake .#<host>
sudo darwin-rebuild switch --flake .#<host>
```

## 確認

Gitがローカル設定を読んでいるか確認します。

```sh
git config --global user.name
git config --global user.email
git config --global --show-origin --get user.email
```

最後のコマンドで `~/.gitconfig.local` が表示されれば分離できています。

## 注意

Nix flakeはGit管理外のファイルを純粋評価の入力として扱いにくいため、Gitの個人情報はNix式へ import せず、Git本来の `include.path = ~/.gitconfig.local` で読み込ませます。

既にメールアドレスなどをコミット済みの場合、履歴から完全に消したいときは `git filter-repo` などで履歴を書き換える必要があります。公開済みリポジトリでは影響範囲が大きいので、必要になった時点で別途判断してください。
