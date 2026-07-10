# Lazygit設定
{ unstable, ... }:

{
  programs.lazygit = {
    enable = true;
    package = unstable.lazygit;

    settings = {
      gui = {
        nerdFontsVersion = "3";
        sidePanelWidth = 0.15;
        mainPanelSplitMode = "horizontal";
        expandFocusedSidePanel = false;
        border = "rounded";
        showfiletree = true;
        showbottomline = false;
        showCommandLog = false;
        showRandomTip = false;
        skipStashWarning = true;
      };

      os.copyToClipboardCmd = ''
        printf %s {{text}} | sh -c 'if command -v clip.exe >/dev/null 2>&1 && command -v iconv >/dev/null 2>&1; then iconv -f UTF-8 -t UTF-16LE | clip.exe; elif command -v pbcopy >/dev/null 2>&1; then pbcopy; elif command -v wl-copy >/dev/null 2>&1; then wl-copy; elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; else cat >/dev/null; fi'
      '';

      git = {
        autoFetch = true;

        allBranchesLogCmds = [
          "git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(#a0a0a0 reverse)%h%Creset %C(cyan)%ad%Creset %C(#dd4814)%ae%Creset %C(yellow reverse)%d%Creset %n%C(white bold)%s%Creset%n' --"
        ];
        branchLogCmd = "git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(#a0a0a0 reverse)%h%Creset %C(cyan)%ad%Creset %C(#dd4814)%ae%Creset %C(yellow reverse)%d%Creset %n%C(white bold)%s%Creset%n' {{branchName}} --";
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

      customCommands = [
        {
          key = "C";
          context = "files";
          description = "Commit with Gitmoji prefix";
          command = ''git commit -m {{ printf "%s%s" .Form.Prefix .Form.Message | quote }}'';
          loadingText = "Committing...";
          prompts = [
            {
              type = "menu";
              title = "Commit type";
              key = "Prefix";
              options = [
                {
                  key = "f";
                  name = "feat";
                  description = "new feature";
                  value = "✨ feat: ";
                }
                {
                  key = "b";
                  name = "fix";
                  description = "bug fix";
                  value = "🐛 fix: ";
                }
                {
                  key = "r";
                  name = "refactor";
                  description = "code refactor";
                  value = "♻️ refactor: ";
                }
                {
                  key = "p";
                  name = "perf";
                  description = "performance";
                  value = "⚡ perf: ";
                }
                {
                  key = "d";
                  name = "docs";
                  description = "documentation";
                  value = "📝 docs: ";
                }
                {
                  key = "t";
                  name = "test";
                  description = "tests";
                  value = "✅ test: ";
                }
                {
                  key = "c";
                  name = "chore";
                  description = "maintenance";
                  value = "🏗️ chore: ";
                }
                {
                  key = "x";
                  name = "remove";
                  description = "remove code or files";
                  value = "🔥 remove: ";
                }
                {
                  key = "h";
                  name = "hotfix";
                  description = "urgent fix";
                  value = "🚑 hotfix: ";
                }
              ];
            }
            {
              type = "input";
              title = "Commit message";
              key = "Message";
            }
          ];
        }
        {
          key = "B";
          context = "files";
          description = "Blame selected file";
          command = ''git blame --date=short -- {{.SelectedFile.Name | quote}} | delta --paging=always'';
          output = "terminal";
        }
      ];
    };
  };
}
