# WSL固有のNixOSシステム設定
{
  lib,
  pkgs,
  unstable,
  ...
}:

let
  fcitx5WithMozc = pkgs.qt6Packages.fcitx5-with-addons.override {
    addons = with pkgs; [ fcitx5-mozc ];
  };
  studioSupport = import ../../lib/android-studio.nix {
    inherit lib pkgs;
    androidStudio = unstable.android-studio;
    isWsl = true;
  };
  androidStudioWsl = pkgs.symlinkJoin {
    name = "android-studio-wsl";
    paths = [
      (studioSupport.mkLauncher "android-studio")
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
      exec powershell.exe -NoProfile -Command "& { param([string]\$target) Invoke-Item -LiteralPath \$target }" "$target"
    fi

    exec powershell.exe -NoProfile -Command "& { param([string]\$target) Start-Process \$target }" "$target"
  '';
  windowsPowerShell = pkgs.writeShellScriptBin "powershell.exe" ''
    set -eu

    powershell_path=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
    if [ ! -x "$powershell_path" ]; then
      echo "powershell.exe: Windows PowerShell not found at $powershell_path" >&2
      exit 127
    fi

    exec "$powershell_path" "$@"
  '';
in
{
  imports = [ ../nixos/common.nix ];

  i18n.inputMethod = {
    enable = true;
    enableGtk2 = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-mozc ];
      waylandFrontend = true;
      settings.globalOptions."Hotkey/TriggerKeys"."0" = "Shift_R";
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

  environment = {
    systemPackages = with pkgs; [
      kmod
      dbus
      usbutils
      fcitx5WithMozc
      android-tools
      androidStudioWsl
      windowsPowerShell
      wslOpen
    ];
    variables.BROWSER = "wsl-open";
  };
}
