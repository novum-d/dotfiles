# Zsh設定
{ lib, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # Run this after Home Manager's mise activation so the command-not-found
    # bridge wraps mise's handler instead of being overwritten by it.
    initContent = lib.mkOrder 2000 ''
      export PATH="$HOME/.local/share/mise/shims:$PATH"
      if [[ -z "$JAVA_HOME" ]] && command -v mise >/dev/null 2>&1; then
        export JAVA_HOME="$(mise where java 2>/dev/null)"
      fi

      function open() {
        if (( $+commands[wsl-open] )); then
          command wsl-open "$@"
        elif (( $+commands[open] )); then
          command open "$@"
        elif (( $+commands[xdg-open] )); then
          command xdg-open "$@"
        else
          echo "open: no opener command found" >&2
          return 127
        fi
      }

      codex() {
        command codex "$@" </dev/tty >/dev/tty 2>/dev/tty
      }

      if [[ "$(uname -s)" == "Darwin" ]]; then
        export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
      fi

      # zoxide
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init zsh)"
      fi

      # mise does not currently map all missing binaries (for example java,
      # python3, and mix) through hook-not-found. Bridge the common runtime entrypoints
      # to their configured mise tools before falling back to zsh's default.
      if [[ -z "$_dotfiles_cmd_not_found_bridge" ]]; then
        _dotfiles_cmd_not_found_bridge=1
        if [[ -n "$(declare -f command_not_found_handler)" ]]; then
          eval "''${$(declare -f command_not_found_handler)/command_not_found_handler/_dotfiles_command_not_found_handler}"
        fi
      fi

      command_not_found_handler() {
        local cmd="$1"
        local tools=()
        shift

        case "$cmd" in
          java|javac|jar|jshell)
            tools=(java)
            ;;
          python|python3|pip|pip3)
            tools=(python)
            ;;
          rustc|cargo|rustup|rustdoc|rustfmt|clippy-driver)
            tools=(rust)
            ;;
          node|npm|npx|corepack)
            tools=(node)
            ;;
          erl|erlc|escript|dialyzer)
            tools=(erlang)
            ;;
          elixir|iex|mix)
            tools=(erlang elixir)
            ;;
        esac

        if (( ''${#tools[@]} )) && command -v mise >/dev/null 2>&1; then
          mise install "''${tools[@]}" && {
            (( $+functions[_mise_hook] )) && _mise_hook
            rehash
            "$cmd" "$@"
          }
          return $?
        fi

        if [[ -n "$(declare -f _dotfiles_command_not_found_handler)" ]]; then
          _dotfiles_command_not_found_handler "$cmd" "$@"
          return $?
        fi

        echo "zsh: command not found: $cmd" >&2
        return 127
      }

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
