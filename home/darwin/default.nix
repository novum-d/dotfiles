# macOS共通設定
{ pkgs, ... }:
{
  # nix-darwinとの競合を避けるため、nixは無効化
  nix.enable = false;

  # unfree（オープンソースでない、またはライセンス場制限のある）なパッケージを許可
  nixpkgs.config.allowUnfree = true;

  environment.shells = [ pkgs.zsh ];

  system.defaults = {
    NSGlobalDomain = {
      InitialKeyRepeat = 10;
      KeyRepeat = 1;

      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;

    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    dock = {
      autohide = true;
      show-recents = false;
      orientation = "bottom";
      tilesize = 48;
      mru-spaces = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    taps = [
      "android/tap"
    ];
    brews = [
      "mas"
      "ollama"
      "syncthing"
    ];
    casks = [
      "font-hack-nerd-font"
      "android-cli"
      "ghostty"
      "anki"
      "google-chrome"
      "karabiner-elements"
      "slack"
      "jetbrains-toolbox"
      "clipy"
      "obsidian"
      "zed"
      "codex-app"
    ];
  };
  launchd.user.agents.syncthing = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/bin/syncthing"
        "serve"
        "--no-browser"
      ];

      RunAtLoad = true;
      KeepAlive = true;
    };
  };
  launchd.user.agents.ollama = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/bin/ollama"
        "serve"
      ];

      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
