# 共通のHome Managerの設定ファイル
{
  config,
  pkgs,
  unstable,
  guiPkgs,
  ...
}:

let
  studio = pkgs.writeShellScriptBin "studio" ''
    set -u

    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export QT_IM_MODULES="wayland;fcitx;ibus"
    export XMODIFIERS=@im=fcitx
    export SDL_IM_MODULE=fcitx
    export _JAVA_OPTIONS="-Drecreate.x11.input.method=true ''${_JAVA_OPTIONS-}"

    if [ -z "''${DBUS_SESSION_BUS_ADDRESS-}" ] && command -v dbus-run-session >/dev/null 2>&1; then
      exec dbus-run-session -- "$0" "$@"
    fi

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
      dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XAUTHORITY XMODIFIERS GTK_IM_MODULE QT_IM_MODULE QT_IM_MODULES SDL_IM_MODULE >/dev/null 2>&1 || true
    fi

    if command -v fcitx5 >/dev/null 2>&1 && [ -n "''${DISPLAY-}''${WAYLAND_DISPLAY-}" ]; then
      fcitx5 -d --replace >/dev/null 2>&1 || true
    fi

    exec ${unstable.android-studio}/bin/android-studio "$@"
  '';
in
{
  imports = [
    ../base
  ];

  home.packages = with pkgs; [
    fcitx5
    fcitx5-mozc
    gcc
    qt6Packages.fcitx5-configtool
    studio
    #slack
    #discord
    #jetbrains.rust-rover
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    QT_IM_MODULES = "wayland;fcitx;ibus";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  home.file.".config/fcitx5/profile" = {
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

  xdg.enable = true;
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
