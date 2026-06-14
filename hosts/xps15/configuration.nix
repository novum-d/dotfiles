{ config, pkgs, ... }:

let
  username = "novumd";
  user_email = "hamada.tomoki01@gmail.com";
in
{
  imports = [
    ./hardware-configuration.nix
    ./fonts
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
  networking.firewall.enable = false;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

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

  users.users."${username}" = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ firefox ];
    shell = pkgs.zsh;
  };

  home-manager.users."${username}" =
    { ... }:
    {
      imports = [
        ../../home/base
        ../../home/nix
      ];
      home.username = username;
      home.homeDirectory = "/home/${username}";
      programs.git.settings.user.name = username;
      programs.git.settings.user.email = user_email;
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

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };
  services.input-remapper.enable = true;

  system.stateVersion = "25.11";
}
