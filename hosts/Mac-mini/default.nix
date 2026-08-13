# Mac mini固有のnix-darwin設定
{ pkgs, username, ... }:
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
      imports = [ ../../home/darwin ];
      home.username = username;
      home.homeDirectory = "/Users/${username}";
    };
}
