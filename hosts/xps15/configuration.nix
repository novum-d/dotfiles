{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../home/nix/configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  console.earlySetup = true;

  systemd.user.services.rc-local = {
    script = ''
      evtest --grab /dev/input/event0 > /dev/null 2>&1 &
    '';
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
  };
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc ];
  };

  console = {
    font = "ter-i32b";
    packages = with pkgs; [ terminus_font ];
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb.layout = "us";
    xkb.variant = "";
    excludePackages = with pkgs; [ xterm ];
  };
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  boot.blacklistedKernelModules = [ "nouveau" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput = {
    enable = true;
    touchpad = {
      accelSpeed = "-0.5";
      additionalOptions = ''
        Option "ScrollPixelDistance" "30"
      '';
    };
  };

  users.users.novumd = {
    extraGroups = [
      "networkmanager"
    ];
    packages = with pkgs; [ firefox ];
  };

  services.input-remapper.enable = true;

  system.stateVersion = "26.05";
}
