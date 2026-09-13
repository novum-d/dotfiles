# XPS 15固有のNixOS設定
{
  config,
  pkgs,
  username,
  ...
}:

{
  # 自動生成されたハードウェア設定と、NixOS共通設定を土台にする。
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
  ];

  # UEFI起動を構成し、競合するnouveauドライバーを無効にする。
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
    # この端末は常時稼働させるため、サスペンド系targetを無効にする。
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # デスクトップとアプリでMozcを利用できるようfcitx5を有効にする。
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc ];
  };

  # 仮想コンソールでも読みやすいTerminusフォントを使う。
  console = {
    font = "ter-i32b";
    packages = with pkgs; [ terminus_font ];
  };

  # GNOMEデスクトップ、印刷、音声、タッチパッドなど実機の周辺機能を構成する。
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

  # Intel GPUを表示側、NVIDIA GPUを必要時だけ使うPRIME offload構成。
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

  # この端末だけで使うGUIアプリとNetworkManager権限をユーザーへ追加する。
  users.users."${username}" = {
    extraGroups = [
      "networkmanager"
    ];
    packages = with pkgs; [
      anki
      firefox
    ];
  };

  system.stateVersion = "26.05";
}
