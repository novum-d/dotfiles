# Mac mini固有のnix-darwin設定
{ pkgs, username, ... }:
{
  # このホストをApple Silicon Macとして評価し、nix-darwinの互換版を固定する。
  nixpkgs.hostPlatform = "aarch64-darwin"; # または "x86_64-darwin"
  system.stateVersion = 6;
  system.primaryUser = username;

  # nix-darwin側のユーザーとログインシェルを、共通usernameから作成する。
  users.users."${username}" = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # 同じユーザーへmacOS用Home Manager設定を接続する。
  home-manager.users."${username}" =
    { ... }:
    {
      imports = [ ../../home/darwin ];
      home.username = username;
      home.homeDirectory = "/Users/${username}";
    };
}
