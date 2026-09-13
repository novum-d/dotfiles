# Pixel 7 Pro固有のNix-on-Droid設定
{
  lib,
  pkgs,
  ...
}:

{
  # Nix-on-Droid共通設定へ、この端末だけの表示・時刻・更新コマンドを重ねる。
  imports = [ ../../modules/nix-on-droid ];

  # Androidアプリ内のターミナルが読み込める実体パスでフォントを指定する。
  terminal.font = "${pkgs.meslo-lgs-nf}/share/fonts/truetype/MesloLGS NF Regular.ttf";

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "24.05";

  # 共通の更新aliasを、この端末のNix-on-Droid出力へ差し替える。
  home-manager.config.programs.zsh.shellAliases.u =
    lib.mkForce "nix-on-droid switch --flake .#pixel7pro";
}
