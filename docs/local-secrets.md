# ローカル個人情報の分離

このリポジトリでは、公開・共有するdotfilesにGitのユーザー名やメールアドレスを直接書かず、各端末の `~/.gitconfig.local` に分離します。

## 管理方針

- Git管理する設定には、共有して問題ないデフォルトだけを置く。
- Gitの `user.name` / `user.email` は `~/.gitconfig.local` に置く。
- 社内GitLabのドメインを公開したくない場合は、Lazygit用の `lazygit.gitlabHost` も `~/.gitconfig.local` に置く。
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

[lazygit]
  gitlabHost = gitlab.internal.example.com
```

`lazygit.gitlabHost` は任意です。設定されている場合、Lazygitのラッパーが起動時に値を読み、self-managed GitLab用の `services` 設定を一時ファイルとして追加します。`https://` などのschemeは省略でき、ポートが必要な場合は `gitlab.internal.example.com:8443` のように指定できます。この設定はWeb画面やMerge RequestのURLを組み立てるためのもので、GitLabの認証情報ではありません。

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
git config --file ~/.gitconfig.local --get lazygit.gitlabHost
```

3番目のコマンドで `~/.gitconfig.local` が表示されれば、Gitの個人情報を分離できています。GitLabホストも設定した場合は、最後のコマンドでその値が表示されることを確認します。

## 注意

Nix flakeはGit管理外のファイルを純粋評価の入力として扱いにくいため、Gitの個人情報はNix式へ import せず、Git本来の `include.path = ~/.gitconfig.local` で読み込ませます。Lazygitのラッパーは `~/.gitconfig.local` を実行時に直接読み込むため、GitLabのドメインはGit管理対象やNix Storeに入りません。ただしファイル自体は平文なので、トークンやパスワードの保存先には使用しません。

既にメールアドレスなどをコミット済みの場合、履歴から完全に消したいときは `git filter-repo` などで履歴を書き換える必要があります。公開済みリポジトリでは影響範囲が大きいので、必要になった時点で別途判断してください。
