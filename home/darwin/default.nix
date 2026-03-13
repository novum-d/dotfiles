# macOS共通設定
{ pkgs, ... }:
{
  # nix-darwinとの競合を避けるため、nixは無効化
  nix.enable = false;

  # unfree（オープンソースでない、またはライセンス場制限のある）なパッケージを許可
  nixpkgs.config.allowUnfree = true;

  # homebrew = {
  #   enable = true;
  #   onActivation.cleanup = "zap";
  #   brews = [
  #     "node"
  #     "mas"
  #   ];
  #   casks = [
  #     "google-chrome"
  #     "visual-studio-code"
  #     "slack"
  #     "jetbrains-toolbox"
  #     "google-japanese-ime"
  #     "clipy"
  #     "figma"
  #     "charles"
  #     "iterm2"
  #   ];
  # };
}
