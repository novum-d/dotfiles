# macOS共通のHome Manager設定
{ ... }:

{
  imports = [
    ../base
    ./programs/karabiner
  ];

  home.file."repos/obsidian/.stignore" = {
    force = true;
    source = ../base/programs/syncthing/obsidian.stignore;
  };
}
