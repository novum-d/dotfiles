# macOS共通設定
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
in
{
  # nix-darwinとの競合を避けるため、nixは無効化
  nix.enable = false;

  # unfree（オープンソースでない、またはライセンス場制限のある）なパッケージを許可
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

  home-manager.users."${username}".home.file."repos/obsidian/.stignore" = {
    force = true;
    source = ../base/programs/syncthing/obsidian.stignore;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    brews = [
      "mas"
      "ollama"
      "syncthing"
    ];
    casks = [
      "font-hack-nerd-font"
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
      "discord"
    ];
  };
  launchd.user.agents = {
    syncthing = {
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

    ollama = {
      serviceConfig = {
        ProgramArguments = [
          "/opt/homebrew/bin/ollama"
          "serve"
        ];

        RunAtLoad = true;
        KeepAlive = true;
      };
    };

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
