# Git設定
{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      push = {
        autoSetupRemote = true;
      };
      ghq = {
        root = "~/repos";
      };
      template = {
        commit = "${./commit_message}";
      };
      aliases = {
        a = "add";
        b = "branch -vv";
        d = "diff";
        st = "status";
        s = "stash -u";
        pop = "stash pop";
        l = "log";
        p = "pull";
        P = "push";
        co = "checkout";
        c = "commit";
        sw = "switch";
      };
    };
  };

  home.packages = with pkgs; [
    git-trim
  ];
}
