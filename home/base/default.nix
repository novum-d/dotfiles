# 共通のHome Managerの設定ファイル
{ pkgs, unstable, ... }:
{
  # 共通パッケージ
  imports = [
    ./programs/zsh
    ./programs/ssh
    ./programs/git
    ./programs/karabiner
    ./programs/lazyvim
    ./programs/continue
    ./programs/jetbrains-toolbox
    ./programs/lazygit
    ./programs/android
    ./programs/mise
    ./programs/codex
    ./programs/github-copilot
  ];
  home = {
    packages = with pkgs; [
      # 開発環境・CLI
      tree-sitter
      fzf
      ghq
      google-cloud-sdk
      uv

      # 検索・ディレクトリ確認
      ripgrep
      fd
      tree
      tre-command

      # ファイル表示・差分・置換
      bat
      eza
      sd
      ydiff

      # 構造化データ
      jq
      yq-go

      # 通信
      curl
      wget

      # アーカイブ
      unzip
      zip

      # タスク実行・監視
      just
      watchexec

      # Lint・Format・Language Server
      nixfmt
      statix
      nil
      shellcheck
      shfmt

      # ビルド
      gnumake
      gcc
      pkg-config

      # 図・ドキュメント
      graphviz
      unstable.plantuml
      unstable.marp-cli

      # Android・デバイス操作
      android-tools
      scrcpy

      # XML・証明書・調査
      libxml2
      openssl

      # ストレージ・同期
      rclone

      # フォント
      meslo-lgs-nf

      # バージョンを優先したいツール
      unstable.gh
      unstable.terraform
    ];

    # Nixpkgsのリリースチェックを無効化
    enableNixpkgsReleaseCheck = false;

    # Home Managerの状態バージョンを指定
    stateVersion = "26.05";

    sessionVariables = {
      GRAPHVIZ_DOT = "${pkgs.graphviz}/bin/dot";
    };
  };

  # Home Managerの有効化
  programs.home-manager.enable = true;
}
