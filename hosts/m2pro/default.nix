# 端末ごとの固有設定
{ ... }:
let
    username = let u = builtins.getEnv "USER"; in if u != "" then u else "t.hamada";
    hostname = "t-hamada-5393";
in
{
  networking.hostName = hostname;
  nixpkgs.hostPlatform = "aarch64-darwin"; # または "x86_64-darwin"
  system.stateVersion = 6;
  system.primaryUser = username;

  users.users."${username}" = {
    name = username;
    home = "/Users/${username}";
  };

  home-manager.users."${username}" = { ... }: {
    imports = [ ../../home/base ];
    home.username = username;
    home.homeDirectory = "/Users/${username}";
    programs.git.settings.user.name = "${username}";
    programs.git.settings.user.email = "${username}@gmail.com";
  };
}
