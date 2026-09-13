# Git設定
{ pkgs, ... }:

{
  # OSやエディターが生成するファイルを除外する共通ignoreを配置する。
  home.file.".config/git/ignore".source = ./ignore;

  programs.git = {
    enable = true;

    # 配色テーマは共有し、氏名・メールアドレスなどの非公開値はローカル設定から読む。
    includes = [
      { path = "${./themes.gitconfig}"; }
      { path = "~/.gitconfig.local"; }
    ];

    lfs.enable = true;

    settings = {
      # リポジトリ作成、同期、履歴表示の既定動作を全環境でそろえる。
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

      # 日常操作を短いコマンドで実行するための共通alias。
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

  # deltaをGitのpagerとして組み込み、差分を横並びで表示する。
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

  # マージ済みbranchを対話的に整理する補助CLI。
  home.packages = with pkgs; [
    git-trim
  ];
}
