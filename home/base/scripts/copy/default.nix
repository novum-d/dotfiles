# 標準入力を環境ごとのクリップボードへコピーするコマンド
{ pkgs, ... }:

let
  copyCommand = pkgs.writeShellApplication {
    name = "copy";
    text = builtins.readFile ./copy.sh;
  };
in
{
  home.packages = [ copyCommand ];
}
