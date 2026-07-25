# Continue Project Rules

このリポジトリの作業規約の正本は、ルートの `AGENTS.md` と `prompt.md` です。

プロジェクト固有の調査、編集、レビューを行う前に、次の順で確認してください。

1. `AGENTS.md`
2. `prompt.md`
3. `README.md`
4. 対象環境に対応する `docs/` とNixモジュール

特に次を守ります。

- macOSだけでなく、NixOS、WSL、Nix-on-Droidを含む複数環境のFlakeとして扱う。
- 既存の未コミット変更を保持し、最小差分で編集する。
- 環境変数や `.env` に依存せず、Pure Nix評価を維持する。
- 秘密情報とGit identityをNix式やGit管理対象へ追加しない。
- プラットフォーム固有設定を無条件に `home/base` へ移動しない。
- 変更後は `prompt.md` の検証マトリクスから対象に合うコマンドを実行する。
- コミット・プッシュはユーザーが明示的に依頼した場合だけ行う。
