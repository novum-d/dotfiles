{ pkgs, unstable, ... }:

let
  username = "novumd";
  user_email = "hamada.tomoki01@gmail.com";
in
{
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

  users.users."${username}" = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  home-manager.users."${username}" =
    { ... }:
    {
      imports = [
        ../../home/base
      ];
      home.username = username;
      home.homeDirectory = "/home/${username}";
      programs.git.settings.user.name = username;
      programs.git.settings.user.email = user_email;
    };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE:="0666", TAG+="uaccess"
  '';

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
    kmod
    usbutils
    android-tools
    unstable.android-studio
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

  system.stateVersion = "26.05";
}
