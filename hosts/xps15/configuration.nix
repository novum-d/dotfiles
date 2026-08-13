# XPS 15固有のNixOS設定
{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    blacklistedKernelModules = [ "nouveau" ];
  };
  console.earlySetup = true;

  systemd = {
    # 内蔵キーボードをgrabし、外付けキーボードを主入力として使う。
    user.services.grab-built-in-keyboard = {
      description = "Grab the built-in keyboard input device";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.evtest}/bin/evtest --grab /dev/input/event0";
        Restart = "on-failure";
      };
    };
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

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

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
      xkb.variant = "";
      excludePackages = with pkgs; [ xterm ];
    };
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput = {
      enable = true;
      touchpad = {
        accelSpeed = "-0.5";
        additionalOptions = ''
          Option "ScrollPixelDistance" "30"
        '';
      };
    };
    input-remapper.enable = true;
  };

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

  security.rtkit.enable = true;

  users.users."${username}" = {
    extraGroups = [
      "networkmanager"
    ];
    packages = with pkgs; [ firefox ];
  };

  system.stateVersion = "26.05";
}
