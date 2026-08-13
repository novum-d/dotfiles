{
  config,
  pkgs,
  guiPkgs,
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
    user.services.rc-local = {
      script = ''
        evtest --grab /dev/input/event0 > /dev/null 2>&1 &
      '';
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
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
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      openFirewall = true;
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

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ username ];

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    openssl
    openssl.dev
    pkg-config
  ];
  environment.variables = {
    EDITOR = "vim";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  system.stateVersion = "26.05";
}
