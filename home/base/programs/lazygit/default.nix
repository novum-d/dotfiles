# Lazygit設定
{
  config,
  pkgs,
  unstable,
  ...
}:

let
  lazygitConfigFile =
    if pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable then
      "${config.home.homeDirectory}/Library/Application Support/lazygit/config.yml"
    else
      "${config.xdg.configHome}/lazygit/config.yml";

  # Configure a self-managed GitLab instance with:
  # export GITLAB_HOST=https://gitlab.example.com
  lazygit = pkgs.writeShellScriptBin "lazygit" ''
    gitlab_host="''${GITLAB_HOST:-}"
    if [[ -z "$gitlab_host" ]]; then
      gitlab_host="''${GL_HOST:-}"
    fi

    if [[ -z "$gitlab_host" ]]; then
      exec ${unstable.lazygit}/bin/lazygit "$@"
    fi

    gitlab_host="''${gitlab_host#http://}"
    gitlab_host="''${gitlab_host#https://}"
    gitlab_host="''${gitlab_host%/}"

    if [[ ! "$gitlab_host" =~ ^[A-Za-z0-9._-]+(:[0-9]+)?$ ]]; then
      echo "lazygit: GITLAB_HOST must be a hostname with an optional port" >&2
      exit 2
    fi

    gitlab_config="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/lazygit-gitlab.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$gitlab_config"' EXIT

    printf 'services:\n  %s: gitlab:%s\n' "$gitlab_host" "$gitlab_host" > "$gitlab_config"

    base_config="''${LG_CONFIG_FILE:-}"
    if [[ -z "$base_config" ]]; then
      base_config="${lazygitConfigFile}"
    fi

    LG_CONFIG_FILE="$base_config,$gitlab_config" ${unstable.lazygit}/bin/lazygit "$@"
  '';
in

{
  programs.lazygit = {
    enable = true;
    package = lazygit;

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
          command = "git blame --date=short -- {{.SelectedFile.Name | quote}} | delta --paging=always";
          output = "terminal";
        }
      ];
    };
  };
}
