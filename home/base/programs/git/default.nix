# Git設定
{ pkgs, ... }:

{
  home.file.".config/git/ignore".source = ./ignore;

  programs.git = {
    enable = true;

    includes = [
      { path = "${./themes.gitconfig}"; }
      { path = "~/.gitconfig.local"; }
    ];

    lfs.enable = true;

    settings = {
      core.excludesFile = "~/.config/git/ignore";

      init.defaultBranch = "main";

      pull.rebase = true;

      rebase.autoStash = true;

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      fetch.prune = true;

      merge.conflictStyle = "zdiff3";

      rerere.enabled = true;

      ghq.root = "~/repos";

      template.commit = "${./commit_message.txt}";

      alias = {
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
  };

  programs.delta = {
    enable = true;

    enableGitIntegration = true;

    options = {
      features = "weeping-willow";
      navigate = true;
      line-numbers = true;
      side-by-side = true;
    };
  };

  home.packages = with pkgs; [
    git-trim
  ];
}
