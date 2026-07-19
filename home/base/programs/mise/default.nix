# Mise settings
{ lib, pkgs, ... }:

let
  pythonBuildDeps = with pkgs; [
    bzip2
    libffi
    ncurses
    openssl
    readline
    sqlite
    tk
    xz
    zlib
  ];
in
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        rust = "stable";
        java = "21";
        erlang = "stable";
        elixir = "stable";
        python = "3";
        node = "lts";
      };

      env = {
        CPPFLAGS = lib.concatMapStringsSep " " (pkg: "-I${lib.getDev pkg}/include") pythonBuildDeps;
        LDFLAGS = lib.concatMapStringsSep " " (pkg: "-L${lib.getLib pkg}/lib") pythonBuildDeps;
        PKG_CONFIG_PATH = lib.concatMapStringsSep ":" (
          pkg: "${lib.getDev pkg}/lib/pkgconfig"
        ) pythonBuildDeps;
      };

      settings = {
        auto_install = true;
        exec_auto_install = true;
        not_found_auto_install = true;
        task_run_auto_install = true;
      };
    };
  };

  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
  ];

  home.sessionVariables = {
    JAVA_HOME = "$HOME/.local/share/mise/installs/java/21";
  };
}
