{ pkgs, ... }:

let
  username = "novumd";
  locale = "ja_JP.UTF-8";
in
{
  networking.firewall.enable = false;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale;
    LC_IDENTIFICATION = locale;
    LC_MEASUREMENT = locale;
    LC_MONETARY = locale;
    LC_NAME = locale;
    LC_NUMERIC = locale;
    LC_PAPER = locale;
    LC_TELEPHONE = locale;
    LC_TIME = locale;
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
        ./.
      ];
      home.username = username;
      home.homeDirectory = "/home/${username}";
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
    xdg-utils
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
}
