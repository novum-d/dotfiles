# Git設定
{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };

    extraConfig = {
      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      rebase = {
        autoStash = true;
      };

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      fetch = {
        prune = true;
      };

      merge = {
        conflictStyle = "zdiff3";
      };

      rerere = {
        enabled = true;
      };

      ghq = {
        root = "~/repos";
      };

      template = {
        commit = "${./commit_message.txt}";
      };
    };

    aliases = {
      a = "add";
      aa = "add -A";

      b = "branch -vv";

      c = "commit";
      ca = "commit --amend";

      co = "checkout";

      d = "diff";
      dc = "diff --cached";

      l = "log --oneline --graph --decorate";

      p = "pull";
      P = "push";

      st = "status -sb";

      stu = "stash -u";
      stp = "stash pop";
      stl = "stash list";

      sw = "switch";
      swc = "switch -c";

      rb = "rebase";

      last = "log -1 HEAD";
    };
  };

  home.packages = with pkgs; [
    git-trim
  ];
}