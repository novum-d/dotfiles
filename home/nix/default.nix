# 共通のHome Managerの設定ファイル
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
    slack
    discord
    jetbrains.rust-rover
  ];

  services.syncthing.enable = true;

  programs.anki.enable = true;

  programs.ghostty.enable = true;

  programs.google-chrome = {
    enable = true;
  };

  programs.obsidian.enable = true;

  programs.zed-editor.enable = true;
}
