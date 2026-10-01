# macOS共通のHome Manager設定
{ ... }:

{
  # 全環境共通設定に、macOS専用のアプリ設定を追加する。
  imports = [
    ../base
    ./programs/karabiner
    ./programs/zed
  ];

  # macOS側でも同じObsidian除外ルールを利用する。
  home.file."repos/obsidian/.stignore" = {
    force = true;
    source = ../base/programs/syncthing/obsidian.stignore;
  };
}
