# macOS固有のnix-darwin設定
{ pkgs, username, ... }:

let
  homeDirectory = "/Users/${username}";
  obsidianGtdGoogleDriveSync = pkgs.writeShellScript "obsidian-gtd-google-drive-sync" ''
    set -eu

    source_directory="${homeDirectory}/repos/obsidian/vault/GTD"

    if [ ! -d "$source_directory" ]; then
      echo "rclone sync source directory not found: $source_directory" >&2
      exit 66
    fi

    exec ${pkgs.rclone}/bin/rclone sync \
      "$source_directory" \
      "gdrive:GTD" \
      --check-first \
      --create-empty-src-dirs \
      --delete-after \
      --drive-use-trash \
      --max-delete 100 \
      --log-level INFO
  '';
  mkKeepAliveAgent = programArguments: {
    serviceConfig = {
      ProgramArguments = programArguments;
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
in
{
  # Determinate Nixがdaemonを管理するため、nix-darwin側では管理しない。
  nix.enable = false;

  # Homebrew caskと同様に、非自由ライセンスのGUIアプリを許可する。
  nixpkgs.config.allowUnfree = true;

  environment.shells = [ pkgs.zsh ];

  system.defaults = {
    NSGlobalDomain = {
      InitialKeyRepeat = 10;
      KeyRepeat = 2;

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
    # 宣言から外したformula/caskも次回activationで削除する。
    onActivation.cleanup = "zap";
    brews = [
      "mas"
      "ollama"
      "syncthing"
    ];
    casks = [
      "anki"
      "clipy"
      "codex-app"
      "discord"
      "font-hack-nerd-font"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "jetbrains-toolbox"
      "obsidian"
      "slack"
      "zed"
    ];
  };

  launchd.user.agents = {
    syncthing = mkKeepAliveAgent [
      "/opt/homebrew/bin/syncthing"
      "serve"
      "--no-browser"
    ];

    ollama = mkKeepAliveAgent [
      "/opt/homebrew/bin/ollama"
      "serve"
    ];

    obsidian-gtd-google-drive-sync = {
      serviceConfig = {
        ProgramArguments = [ "${obsidianGtdGoogleDriveSync}" ];

        EnvironmentVariables = {
          HOME = homeDirectory;
        };

        StartCalendarInterval = {
          Weekday = 1;
          Hour = 12;
          Minute = 0;
        };

        ProcessType = "Background";
        LowPriorityIO = true;
        StandardOutPath = "${homeDirectory}/Library/Logs/obsidian-gtd-google-drive-sync.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/obsidian-gtd-google-drive-sync.error.log";
      };
    };
  };
}
