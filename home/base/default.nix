# 全プラットフォーム共通のHome Manager設定
{
  lib,
  pkgs,
  unstable,
  ...
}:
{
  # manページ生成を省き、Home Managerのactivationを軽くする。
  manual.manpages.enable = false;

  # OS固有optionを持つmoduleはhome/darwinまたはhome/nixosからimportする。
  imports = [
    ./scripts
    ./programs/zsh
    ./programs/ssh
    ./programs/git
    ./programs/lazyvim
    ./programs/continue
    ./programs/jetbrains-toolbox
    ./programs/lazygit
    ./programs/android
    ./programs/mise
    ./programs/codex
    ./programs/github-copilot
    ./programs/herdr
  ];

  # OSに依存しないCLIを全環境へ配布し、Linux限定ツールだけ条件付きで追加する。
  home = {
    packages =
      (with pkgs; [
        # 開発環境・CLI
        tree-sitter
        fzf
        ghq
        google-cloud-sdk
        uv
        git-lfs

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
      ])
      # Wayland/X11のクリップボードCLIはLinuxでだけ評価する。
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        with pkgs;
        [
          wl-clipboard
          xclip
          xsel
        ]
      );

    enableNixpkgsReleaseCheck = false;

    # 既存環境との互換性を保つHome Managerの状態バージョン。
    stateVersion = "26.05";

    # Graphvizを利用するツールへ、Nix Store内のdot実体を明示する。
    sessionVariables = {
      GRAPHVIZ_DOT = "${pkgs.graphviz}/bin/dot";
    };
  };

  # Home Manager自身を世代管理の対象として有効にする。
  programs.home-manager.enable = true;
}
