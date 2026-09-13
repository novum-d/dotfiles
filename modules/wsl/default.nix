# WSL固有のNixOSシステム設定
{
  lib,
  pkgs,
  unstable,
  ...
}:

let
  # WSLg上のGUIアプリでMozcを利用できるfcitx5パッケージを作る。
  fcitx5WithMozc = pkgs.qt6Packages.fcitx5-with-addons.override {
    addons = with pkgs; [ fcitx5-mozc ];
  };
  studioSupport = import ../../lib/android-studio.nix {
    inherit lib pkgs;
    androidStudio = unstable.android-studio;
    isWsl = true;
  };

  # Android Studio本体、WSL向け起動ラッパー、デスクトップエントリーを1パッケージへまとめる。
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

  # LinuxのパスはWindows形式へ変換し、URLなどはそのまま既定アプリで開く。
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

  # Windows側の実体を明示して、PATH継承に依存せずPowerShellを呼び出す。
  windowsPowerShell = pkgs.writeShellScriptBin "powershell.exe" ''
    set -eu

    powershell_path=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
    if [ ! -x "$powershell_path" ]; then
      echo "powershell.exe: Windows PowerShell not found at $powershell_path" >&2
      exit 127
    fi

    exec "$powershell_path" "$@"
  '';

  # HerdrなどからWindows側のWSL CLIを確実に呼べるラッパー。
  windowsWsl = pkgs.writeShellScriptBin "wsl.exe" ''
    set -eu

    wsl_path=/mnt/c/Windows/System32/wsl.exe
    if [ ! -x "$wsl_path" ]; then
      echo "wsl.exe: Windows WSL command not found at $wsl_path" >&2
      exit 127
    fi

    exec "$wsl_path" "$@"
  '';
in
{
  # WSL固有差分の土台として、実機と共有するNixOS設定を先に読み込む。
  imports = [ ../nixos/common.nix ];

  # 右ShiftでMozcを切り替えられる日本語入力環境をWSLgへ提供する。
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

  # 動的リンカーを前提とする一般的なLinuxバイナリをNixOS上で実行可能にする。
  programs.nix-ld.enable = true;

  # USB/IP経由で接続するAndroid端末を一般ユーザーからadbで扱えるようにする。
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE:="0666", TAG+="uaccess"
  '';

  # WSLとWindowsを橋渡しするCLIとGUI起動ラッパーをシステム全体へ提供する。
  environment = {
    systemPackages = with pkgs; [
      kmod
      dbus
      usbutils
      fcitx5WithMozc
      android-tools
      androidStudioWsl
      windowsPowerShell
      windowsWsl
      wslOpen
    ];
    variables.BROWSER = "wsl-open";
  };
}
