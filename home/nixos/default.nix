# NixOS共通のHome Manager設定
{
  config,
  lib,
  pkgs,
  syncthing,
  unstable,
  guiPkgs,
  isWsl,
  ...
}:

let
  # GUIアプリと同じMozc構成を利用するfcitx5パッケージ。
  fcitx5WithMozc = pkgs.qt6Packages.fcitx5-with-addons.override {
    addons = with pkgs; [ fcitx5-mozc ];
  };
  studioSupport = import ../../lib/android-studio.nix {
    inherit lib pkgs isWsl;
    androidStudio = unstable.android-studio;
  };

  # Home Managerから起動できるAndroid Studioラッパーを生成する。
  studio = studioSupport.mkLauncher "studio";
in
{
  # 全環境共通設定を土台に、NixOS・WSL向けのユーザー設定だけを追加する。
  imports = [
    ../base
  ];

  home = {
    # 日本語入力とAndroid StudioはNixOS系環境にだけ導入する。
    packages = with pkgs; [
      fcitx5WithMozc
      gcc
      studio
    ];

    # Android StudioをX11/fcitx5で起動するための環境変数をログイン環境へ渡す。
    sessionVariables = studioSupport.inputMethodEnvironment;

    file = {
      # 初回起動時から英語キーボードとMozcを選べるfcitx5プロファイルを生成する。
      ".config/fcitx5/profile" = {
        force = true;
        text = ''
          [Groups/0]
          Name=Default
          Default Layout=us
          DefaultIM=mozc

          [Groups/0/Items/0]
          Name=keyboard-us
          Layout=

          [Groups/0/Items/1]
          Name=mozc
          Layout=

          [GroupOrder]
          0=Default
        '';
      };

      # Compose上の日本語入力を安定させるJVMオプションをAndroid Studioへ渡す。
      "${studioSupport.vmOptionsRelativePath}" = {
        force = true;
        text = studioSupport.vmOptions;
      };
    };
  };

  # デスクトップエントリーとアプリ設定をXDG準拠の場所へ生成する。
  xdg.enable = true;

  # Obsidianリポジトリで同期対象外にするファイルを共通定義から配置する。
  home.file."repos/obsidian/.stignore" = {
    force = true;
    source = ../base/programs/syncthing/obsidian.stignore;
  };

  # 生成したラッパー経由でAndroid Studioをアプリ一覧から起動できるようにする。
  xdg.desktopEntries."android-studio" = {
    name = "Android Studio";
    genericName = "Android IDE";
    exec = "${config.home.profileDirectory}/bin/studio %f";
    icon = "android-studio";
    terminal = false;
    categories = [
      "Development"
      "IDE"
    ];
  };

  # ObsidianリポジトリをPixelと同期し、削除済みファイルを14日間保持する。
  services.syncthing = {
    enable = true;

    settings.folders."${syncthing.obsidianFolderId}" = {
      label = "obsidian";
      path = "${config.home.homeDirectory}/repos/obsidian";
      devices = [ "pixel7pro" ];
      versioning = {
        type = "trashcan";

        params = {
          cleanoutDays = "14";
        };
      };
    };

    settings.devices."pixel7pro".id = syncthing.pixel7proDeviceId;
  };

  # GUIアプリはunstable側のパッケージセットから取得する。
  programs.google-chrome = {
    enable = true;
    package = guiPkgs.google-chrome;
  };

  programs.obsidian = {
    enable = true;
    package = guiPkgs.obsidian;
  };
}
