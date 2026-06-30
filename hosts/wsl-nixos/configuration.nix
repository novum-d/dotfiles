{ pkgs, unstable, ... }:

let
  username = "novumd";
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

  programs.nix-ld.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE:="0666", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    kmod
    usbutils
    android-tools
    wslOpen
    unstable.android-studio
  ];
  environment.variables.BROWSER = "wsl-open";

  system.stateVersion = "26.05";
}
