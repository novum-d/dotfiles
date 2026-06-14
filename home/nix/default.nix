# 共通のHome Managerの設定ファイル
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
    #slack
    #discord
    #jetbrains.rust-rover
  ];

  services.syncthing = {
    enable = true;

    settings.folders."obsidian" = {
      path = "/home/novumd/repos/obsidian";
      devices = [ "pixel7pro" ];
      versioning = {
        type = "trashcan";

        params = {
          cleanoutDays = "14";
        };
      };
    };

    settings.devices."pixel7pro".id = "NMD27JO-BIQEEZU-GWOZSKD-3ZS6RQ5-H6VPOOR-5K3XLEB-OL4WZRU-AT744QM";
  };

  # programs.anki.enable = true;

  # programs.ghostty.enable = true;

  programs.google-chrome = {
    enable = true;
  };

  programs.obsidian.enable = true;

  #programs.zed-editor.enable = true;
}
