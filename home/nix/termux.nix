{ pkgs, ... }:
{
  terminal.font = "${pkgs.meslo-lgs-nf}/share/fonts/truetype/MesloLGS NF Regular.ttf";
  user.shell = "${pkgs.zsh}/bin/zsh";
}
