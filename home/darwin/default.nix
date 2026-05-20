# macOS共通設定
{ pkgs, ... }:
{
  # nix-darwinとの競合を避けるため、nixは無効化
  nix.enable = false;

  # unfree（オープンソースでない、またはライセンス場制限のある）なパッケージを許可
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [
    pkgs.ollama
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    brews = [
      #"node"
      "mas"
    ];
    casks = [
      "font-hack-nerd-font"
      "alacritty"
      "anki"
      "google-chrome"
      "karabiner-elements"
      "slack"
      "jetbrains-toolbox"
      "clipy"
    ];
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
