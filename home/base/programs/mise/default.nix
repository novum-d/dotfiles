# miseによる言語ランタイム管理
{ lib, pkgs, ... }:

let
  # miseがPythonをソースからビルドするときに参照する開発ライブラリ。
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
      # 各言語で利用する既定系列。実際のversion解決と導入はmiseへ任せる。
      tools = {
        rust = "stable";
        java = "21";
        erlang = "latest";
        elixir = "latest";
        python = "3";
        node = "lts";
      };

      # PythonビルドがNix Store内のheader・library・pkg-configを見つけられるようにする。
      env = {
        CPPFLAGS = lib.concatMapStringsSep " " (pkg: "-I${lib.getDev pkg}/include") pythonBuildDeps;
        LDFLAGS = lib.concatMapStringsSep " " (pkg: "-L${lib.getLib pkg}/lib") pythonBuildDeps;
        PKG_CONFIG_PATH = lib.concatMapStringsSep ":" (
          pkg: "${lib.getDev pkg}/lib/pkgconfig"
        ) pythonBuildDeps;
      };

      # 未導入のランタイムを初回実行時に自動導入する。
      settings = {
        auto_install = true;
        exec_auto_install = true;
        not_found_auto_install = true;
        task_run_auto_install = true;
      };
    };
  };

  # shimをPATHの前方へ置き、miseが選んだランタイムを優先する。
  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
  ];

  # Javaを利用するビルドツール向けに既定JDKの場所を公開する。
  home.sessionVariables = {
    JAVA_HOME = "$HOME/.local/share/mise/installs/java/21";
  };
}
