# 共通のHome Managerの設定ファイル
{
  pkgs,
  unstable,
  guiPkgs,
  ...
}:

let
  studio = pkgs.writeShellScriptBin "studio" ''
    exec ${unstable.android-studio}/bin/android-studio "$@"
  '';
in
{
  imports = [
    ../base
  ];

  home.packages = with pkgs; [
    gcc
    studio
    unstable.android-studio
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
    package = guiPkgs.google-chrome;
  };

  programs.obsidian = {
    enable = true;
    package = guiPkgs.obsidian;
  };

  #programs.zed-editor.enable = true;
}
