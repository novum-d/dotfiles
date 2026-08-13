# Pixel 7 Pro固有のNix-on-Droid設定
{
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../../modules/nix-on-droid ];

  terminal.font = "${pkgs.meslo-lgs-nf}/share/fonts/truetype/MesloLGS NF Regular.ttf";

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "24.05";

  home-manager.config.programs.zsh.shellAliases.u =
    lib.mkForce "nix-on-droid switch --flake .#pixel7pro";
}
