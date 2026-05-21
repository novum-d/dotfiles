# Lazygit設定
{ ... }:

{
  programs.lazygit = {
    enable = true;

    settings = {
      gui = {
        nerdFontsVersion = "3";
        sidePanelWidth = 0.15;
        mainPanelSplitMode = "horizontal";
        expandFocusedSidePanel = false;
        border = "rounded";
        showFileTree = true;
        showBottomLine = false;
        showCommandLog = false;
        showRandomTip = false;
        skipStashWarning = true;
      };

      git = {
        autoFetch = true;

        allBranchesLogCmds = [
            ''git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(#a0a0a0 reverse)%h%Creset %C(cyan)%ad%Creset %C(#dd4814)%ae%Creset %C(yellow reverse)%d%Creset %n%C(white bold)%s%Creset%n' --''
        ];
        branchLogCmd = ''git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(#a0a0a0 reverse)%h%Creset %C(cyan)%ad%Creset %C(#dd4814)%ae%Creset %C(yellow reverse)%d%Creset %n%C(white bold)%s%Creset%n' {{branchName}} --'';
        pagers = [
          {
            colorArgs = "always";
            pager = ''delta --dark --paging=never --side-by-side --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
          }
        ];
      };

      update = {
        method = "never";
      };

      commitMessage = {
        customMessages = [
          "✨ feat: "
          "🐛 fix: "
          "♻️ refactor: "
          "⚡ perf: "
          "📝 docs: "
          "✅ test: "
          "🏗️ chore: "
          "🔥 remove: "
          "🚑 hotfix: "
        ];
      };
    };
  };
}