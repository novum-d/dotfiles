# Linux共通のHome Manager設定
{
  config,
  lib,
  pkgs,
  syncthing,
  unstable,
  guiPkgs,
  isWsl,
  ...
}:

let
  fcitx5WithMozc = pkgs.qt6Packages.fcitx5-with-addons.override {
    addons = with pkgs; [ fcitx5-mozc ];
  };
  studioSupport = import ../../lib/android-studio.nix {
    inherit lib pkgs isWsl;
    androidStudio = unstable.android-studio;
  };
  studio = studioSupport.mkLauncher "studio";
in
{
  imports = [
    ../base
  ];

  home = {
    packages = with pkgs; [
      fcitx5WithMozc
      gcc
      studio
    ];

    sessionVariables = studioSupport.inputMethodEnvironment;

    file = {
      ".config/fcitx5/profile" = {
        force = true;
        text = ''
          [Groups/0]
          Name=Default
          Default Layout=us
          DefaultIM=mozc

          [Groups/0/Items/0]
          Name=keyboard-us
          Layout=

          [Groups/0/Items/1]
          Name=mozc
          Layout=

          [GroupOrder]
          0=Default
        '';
      };

      "${studioSupport.vmOptionsRelativePath}" = {
        force = true;
        text = studioSupport.vmOptions;
      };
    };
  };

  xdg.enable = true;
  home.file."repos/obsidian/.stignore" = {
    force = true;
    source = ../base/programs/syncthing/obsidian.stignore;
  };

  xdg.desktopEntries."android-studio" = {
    name = "Android Studio";
    genericName = "Android IDE";
    exec = "${config.home.profileDirectory}/bin/studio %f";
    icon = "android-studio";
    terminal = false;
    categories = [
      "Development"
      "IDE"
    ];
  };

  services.syncthing = {
    enable = true;

    settings.folders."${syncthing.obsidianFolderId}" = {
      label = "obsidian";
      path = "${config.home.homeDirectory}/repos/obsidian";
      devices = [ "pixel7pro" ];
      versioning = {
        type = "trashcan";

        params = {
          cleanoutDays = "14";
        };
      };
    };

    settings.devices."pixel7pro".id = syncthing.pixel7proDeviceId;
  };

  programs.google-chrome = {
    enable = true;
    package = guiPkgs.google-chrome;
  };

  programs.obsidian = {
    enable = true;
    package = guiPkgs.obsidian;
  };
}
