# Zsh設定
{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    initContent = ''
      export PATH="$HOME/.local/share/mise/shims:$PATH"

      function o() {
        if command -v wsl-open >/dev/null 2>&1; then
          wsl-open "$@"
        elif command -v open >/dev/null 2>&1; then
          open "$@"
        elif command -v xdg-open >/dev/null 2>&1; then
          xdg-open "$@"
        else
          echo "o: no opener command found" >&2
          return 127
        fi
      }

      if [[ "$(uname -s)" == "Darwin" ]]; then
        export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
      fi

      # zoxide
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init zsh)"
      fi

      # ghq + fzf
      function ghq_fzf_repo() {
        local select
        select=$(ghq list --full-path | fzf --reverse --height=100%)
        if [[ -n "$select" ]]; then
          cd "$select"
          echo " $select "
          zle reset-prompt
        fi
      }
      zle -N ghq_fzf_repo
      bindkey '^G' ghq_fzf_repo
    '';
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "z"
      ];
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
    ];
    history = {
      size = 10000;
      ignoreAllDups = true;
      path = "$HOME/.zsh_history";
      ignorePatterns = [
        "rm *"
        "pkill *"
        "cp *"
      ];
    };
    shellAliases = {
      lg = "lazygit";
      ll = "ls -al";
      g = "git";
      n = "nvim";
      u =
        if pkgs.stdenv.isDarwin then
          "sudo darwin-rebuild switch --flake ."
        else
          "sudo nixos-rebuild switch --flake .";
    };
  };
}
