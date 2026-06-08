# 端末ごとの固有設定のサンプル
{ pkgs, ... }:
let
  username = "novumd";
  user_email = "hamada.tomoki01@gmail.com";
in
{
  nixpkgs.hostPlatform = "aarch64-darwin"; # または "x86_64-darwin"
  system.stateVersion = 6;
  system.primaryUser = username;

  users.users."${username}" = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  home-manager.users."${username}" =
    { ... }:
    {
      imports = [ ../../home/base ];
      home.username = username;
      home.homeDirectory = "/Users/${username}";
      programs.git.settings.user.name = "${username}";
      programs.git.settings.user.email = "${user_email}";
    };
}
