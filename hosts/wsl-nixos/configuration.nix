{ pkgs, unstable, ... }:

let
  username = "novumd";
  androidStudioWsl = pkgs.symlinkJoin {
    name = "android-studio-wsl";
    paths = [
      (pkgs.writeShellScriptBin "android-studio" ''
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
      '')
      (pkgs.makeDesktopItem {
        name = "android-studio";
        desktopName = "Android Studio";
        genericName = "Android IDE";
        exec = "android-studio %f";
        icon = "android-studio";
        terminal = false;
        categories = [
          "Development"
          "IDE"
        ];
      })
    ];
  };
  wslOpen = pkgs.writeShellScriptBin "wsl-open" ''
    set -eu

    if [ "$#" -eq 0 ]; then
      exit 1
    fi

    target="$1"
    if command -v wslpath >/dev/null 2>&1 && [ -e "$target" ]; then
      target="$(wslpath -w "$target")"
    fi

    cmd.exe /c start "" "$target"
  '';
in
{
  imports = [
    ../../home/nix/configuration.nix
  ];

  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    useWindowsDriver = true;
    usbip = {
      enable = true;
      autoAttach = [ "4-7" ];
    };
    wslConf = {
      automount.root = "/mnt";
      interop.appendWindowsPath = true;
      network.hostname = "wsl-nixos";
    };
  };

  networking.hostName = "wsl-nixos";

  i18n.inputMethod = {
    enable = true;
    enableGtk2 = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-mozc ];
      waylandFrontend = true;
      settings.inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us";
          Layout = "";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
          Layout = "";
        };
        GroupOrder."0" = "Default";
      };
    };
  };

  programs.nix-ld.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE:="0666", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    kmod
    dbus
    usbutils
    android-tools
    androidStudioWsl
    wslOpen
  ];
  environment.variables.BROWSER = "wsl-open";

  system.stateVersion = "26.05";
}
