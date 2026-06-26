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
  ];
  home.packages = with pkgs; [
    nixfmt
    nodejs
    tree-sitter
    ripgrep
    fzf
    fd
    zoxide
    tre-command
    gh
    ghq
    ydiff
    uv
    jq
    tmux
    statix
    meslo-lgs-nf
    graphviz
    plantuml
    scrcpy
    rclone
    unstable.marp-cli
  ];

  # Home Managerの有効化
  programs.home-manager.enable = true;

  # Nixpkgsのリリースチェックを無効化
  home.enableNixpkgsReleaseCheck = false;

  # Home Managerの状態バージョンを指定
  home.stateVersion = "26.05";

  home.sessionVariables = {
    GRAPHVIZ_DOT = "${pkgs.graphviz}/bin/dot";
  };
}
