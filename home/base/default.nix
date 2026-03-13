# 共通のHome Managerの設定ファイル
{ pkgs, ... }:
{
  # 共通パッケージ
  imports = [
    ./programs/zsh
    ./programs/git
    ./programs/lazyvim
  ];
  home.packages =
    with pkgs;
    [
      nixfmt
      tree-sitter
      ripgrep
      fzf
      fd
      zoxide
      tre-command
      gh
      ghq
      lazygit
      ydiff
      meslo-lgs-nf
    ];

  # Home Managerの有効化
  programs.home-manager.enable = true;

  # Nixpkgsのリリースチェックを無効化
  home.enableNixpkgsReleaseCheck = false;

  # Home Managerの状態バージョンを指定
  home.stateVersion = "25.11";
}
