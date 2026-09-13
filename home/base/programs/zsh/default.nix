# Zsh設定
{ lib, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # Home Managerのmise初期化後に実行し、command-not-foundの処理を上書きされないようにする。
    initContent = lib.mkOrder 2000 ''
      # miseのshimを優先し、利用可能なJavaからJAVA_HOMEを補完する。
      export PATH="$HOME/.local/share/mise/shims:$PATH"
      if [[ -z "$JAVA_HOME" ]] && command -v mise >/dev/null 2>&1; then
        export JAVA_HOME="$(mise where java 2>/dev/null)"
      fi

      # macOS、WSL、Linuxで同じopen関数を使い、環境ごとの既定アプリを呼び出す。
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

      if [[ "$(uname -s)" == "Darwin" ]]; then
        export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
      fi

      # zoxideが利用できる場合だけ、ディレクトリ移動履歴をzshへ統合する。
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init zsh)"
      fi

      # miseがhook-not-foundへ対応付けないjava、python3、mixなども、
      # 未導入なら対応するmiseランタイムを導入してから再実行する。
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

      # ghqのリポジトリ一覧をfzfで選び、選択先へ移動するZLE widget。
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

    # 補完、候補表示、syntax highlightをHome Managerの機能で有効にする。
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
      # prompt本体と、このリポジトリで管理する設定を別pluginとして読み込む。
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

    # 履歴は重複を除き、破壊的になりやすいコマンドを保存対象から外す。
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

    # `u`だけは評価中のプラットフォームに対応するrebuildコマンドへ切り替える。
    shellAliases = {
      lg = "lazygit";
      ll = "ls -al";
      g = "git";
      n = "nvim";
      u =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "sudo darwin-rebuild switch --flake ."
        else
          "sudo nixos-rebuild switch --flake .";
    };
  };
}
