# Herdrのロール別CodexランチャーとHome Manager設定
{
  config,
  lib,
  pkgs,
  herdr,
  ...
}:

let
  # 現在のプラットフォームに対応するHerdrパッケージをFlake入力から選ぶ。
  herdrPackage = herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # promptを変更したときはrevisionを上げ、古い指示のsessionを再利用しない。
  rolePromptRevision = "4";
  vaultPath = "${config.home.homeDirectory}/repos/obsidian/vault";

  rolePromptHeader = ''
    Do not mention, compare, or report the model or reasoning effort unless the user explicitly asks about them.
  '';

  # 各ロールへ継続性を判定するkeyと共通指示を付加する。
  rolePrompt = role: text: ''
    Herdr continuity key: codex-role/${role}/rev-${rolePromptRevision}

    ${rolePromptHeader}
    ${text}
  '';

  # ロール本文は実行ロジックから分離し、レビュー時に役割定義だけを読めるようにする。
  rolePrompts = import ./role-prompts.nix { inherit rolePrompt; };

  roleNames = builtins.attrNames rolePrompts;
  roleList = lib.concatStringsSep " " roleNames;

  # Nix属性のロール定義を、Codexが直接読めるMarkdownファイルへ展開する。
  rolePromptFiles = lib.mapAttrs' (
    name: text: lib.nameValuePair "codex/roles/${name}.md" { inherit text; }
  ) rolePrompts;

  # 作業ディレクトリとロールが一致する直近sessionを探し、再開または新規起動する。
  codexRole = pkgs.writeShellScriptBin "codex-role" ''
    set -eu

    if [ "$#" -lt 1 ]; then
      echo "usage: codex-role <role> [task...]" >&2
      echo "available roles: ${roleList}" >&2
      exit 64
    fi

    role="$1"
    shift
    role_file="''${XDG_CONFIG_HOME:-$HOME/.config}/codex/roles/$role.md"
    workspace="$(pwd -P)"

    if [ ! -r "$role_file" ]; then
      echo "codex-role: unknown role '$role'" >&2
      echo "available roles: ${roleList}" >&2
      exit 64
    fi

    continuity_marker="Herdr continuity key: codex-role/$role/rev-${rolePromptRevision}"
    codex_home="''${CODEX_HOME:-$HOME/.codex}"
    state_db=""
    session_id=""
    session_rollout=""

    # 複数あるstate DBのうち、更新日時が最も新しいものを選ぶ。
    for candidate in "$codex_home"/state_*.sqlite; do
      if [ -f "$candidate" ] && { [ -z "$state_db" ] || [ "$candidate" -nt "$state_db" ]; }; then
        state_db="$candidate"
      fi
    done

    if [ -n "$state_db" ]; then
      workspace_sql="$(printf '%s' "$workspace" | ${pkgs.gnused}/bin/sed "s/'/&&/g")"
      continuity_marker_sql="$(printf '%s' "$continuity_marker" | ${pkgs.gnused}/bin/sed "s/'/&&/g")"
      session_id="$(${pkgs.sqlite}/bin/sqlite3 -readonly "$state_db" "
        SELECT id
        FROM threads
        WHERE archived = 0
          AND cwd = '$workspace_sql'
          AND instr(first_user_message, '$continuity_marker_sql') > 0
        ORDER BY recency_at_ms DESC, id DESC
        LIMIT 1;
      " 2>/dev/null || true)"

      if [ -n "$session_id" ]; then
        session_id_sql="$(printf '%s' "$session_id" | ${pkgs.gnused}/bin/sed "s/'/&&/g")"
        session_rollout="$(${pkgs.sqlite}/bin/sqlite3 -readonly "$state_db" "
          SELECT rollout_path
          FROM threads
          WHERE id = '$session_id_sql'
          LIMIT 1;
        " 2>/dev/null || true)"
      fi
    fi

    task=""
    if [ "$#" -gt 0 ]; then
      task="$*"
    fi

    # 中断されたturnはresumeせずforkし、履歴を保持した新しい分岐から再開する。
    if [ -n "$session_id" ]; then
      session_command="resume"

      if [ -r "$session_rollout" ]; then
        last_terminal_event="$(
          ${pkgs.jq}/bin/jq -r '
            select(
              .type == "event_msg"
              and (
                .payload.type == "task_complete"
                or .payload.type == "turn_aborted"
              )
            )
            | .payload.type
          ' "$session_rollout" 2>/dev/null \
            | ${pkgs.coreutils}/bin/tail -n 1 \
            || true
        )"

        if [ "$last_terminal_event" = "turn_aborted" ]; then
          session_command="fork"
          echo "codex-role: forking interrupted $role session to preserve its history" >&2
        fi
      fi

      if [ -n "$task" ]; then
        exec codex "$session_command" -C "$workspace" "$session_id" "$task"
      else
        exec codex "$session_command" -C "$workspace" "$session_id"
      fi
    fi

    prompt="$(cat "$role_file")"

    if [ -n "$task" ]; then
      prompt="$(printf '%s\n\nTask:\n%s' "$prompt" "$task")"
    fi

    exec codex -C "$workspace" "$prompt"
  '';

  # 指定ロールのCodexを新しいHerdrペインとして起動する共通ラッパー。
  herdrCodexRole = pkgs.writeShellScriptBin "herdr-codex-role" ''
    set -eu

    if [ "$#" -lt 1 ]; then
      echo "usage: herdr-codex-role <role> [task...]" >&2
      echo "available roles: ${roleList}" >&2
      exit 64
    fi

    role="$1"
    shift
    agent_name="''${HERDR_AGENT_NAME:-codex-$role}"

    exec ${herdrPackage}/bin/herdr agent start "$agent_name" --cwd "$PWD" -- ${codexRole}/bin/codex-role "$role" "$@"
  '';

  # `codex-pm`と`hcodex-pm`のようなロール別コマンドを定義から自動生成する。
  directRoleCommands = lib.mapAttrsToList (
    role: _:
    pkgs.writeShellScriptBin "codex-${role}" ''
      exec ${codexRole}/bin/codex-role ${role} "$@"
    ''
  ) rolePrompts;

  herdrRoleCommands = lib.mapAttrsToList (
    role: _:
    pkgs.writeShellScriptBin "hcodex-${role}" ''
      exec ${herdrCodexRole}/bin/herdr-codex-role ${role} "$@"
    ''
  ) rolePrompts;

  # PM、Architect、iOSを横並びの3ペインで起動する定型チーム。
  pmArchitectIosStack = pkgs.writeShellScriptBin "hpm-harch-hios" ''
    set -eu

    if [ "''${HERDR_ENV:-}" != "1" ]; then
      echo "hpm-harch-hios: run this inside a Herdr pane" >&2
      echo "Start Herdr with: herdr" >&2
      exit 64
    fi

    suffix="''${HERDR_TEAM_SUFFIX:-$$}"

    ${herdrPackage}/bin/herdr agent rename "$HERDR_PANE_ID" "codex-pm-$suffix"

    ${herdrPackage}/bin/herdr agent start "codex-architect-$suffix" \
      --cwd "$PWD" \
      --split right \
      --focus \
      -- ${codexRole}/bin/codex-role architect "$@"

    ${herdrPackage}/bin/herdr agent start "codex-ios-$suffix" \
      --cwd "$PWD" \
      --split right \
      --focus \
      -- ${codexRole}/bin/codex-role ios "$@"

    exec ${codexRole}/bin/codex-role pm "$@"
  '';

  # Obsidian vaultへ移動してから定型チームを起動する短縮コマンド。
  vaultPmArchitectIosStack = pkgs.writeShellScriptBin "hvault" ''
    set -eu

    vault_dir="${vaultPath}"

    if [ ! -d "$vault_dir" ]; then
      echo "hvault: vault directory not found: $vault_dir" >&2
      exit 66
    fi

    cd "$vault_dir"
    HERDR_TEAM_SUFFIX="vault-''${HERDR_TEAM_SUFFIX:-$$}" exec ${pmArchitectIosStack}/bin/hpm-harch-hios "$@"
  '';

  # よく使うロールだけ、さらに短いhpm・hiosなどのaliasを生成する。
  shortHerdrRoleCommands =
    lib.mapAttrsToList
      (
        command: role:
        pkgs.writeShellScriptBin command ''
          exec ${herdrCodexRole}/bin/herdr-codex-role ${role} "$@"
        ''
      )
      {
        hpm = "pm";
        hios = "ios";
        handroid = "android";
        hbackend = "backend";
        hweb = "web";
        hqa = "qa";
        harch = "architect";
        hreview = "reviewer";
      };

  # Codex用integrationを導入し、現在のintegration状態を表示する。
  herdrBootstrapCodex = pkgs.writeShellScriptBin "herdr-bootstrap-codex" ''
    set -eu

    if command -v codex >/dev/null 2>&1; then
      ${herdrPackage}/bin/herdr integration install codex
    else
      echo "Skipping Herdr Codex integration: codex not found" >&2
    fi

    ${herdrPackage}/bin/herdr integration status
  '';
in
{
  # 小画面のNix-on-Droidなど、環境側からHerdrの自動起動を止められるoption。
  options.dotfiles.herdr.autoStart = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to start Herdr automatically in top-level interactive terminals.";
  };

  config = {
    # Herdr本体、共通ランチャー、ロール別に生成した全コマンドをユーザーへ配布する。
    home.packages = [
      herdrPackage
      herdrBootstrapCodex
      codexRole
      herdrCodexRole
      pmArchitectIosStack
      vaultPmArchitectIosStack
    ]
    ++ directRoleCommands
    ++ herdrRoleCommands
    ++ shortHerdrRoleCommands;

    # 生成したロールpromptとHerdr本体の設定をXDG config配下へ配置する。
    xdg.configFile = rolePromptFiles // {
      "herdr/config.toml".source = ./config.toml;
    };

    programs.zsh = {
      shellAliases = {
        hd = "herdr";
        hdb = "herdr-bootstrap-codex";
        hdl = "herdr agent list";
        hds = "herdr session list";
        hdi = "herdr integration status";
        hdr = "herdr server reload-config";
        hdw = "herdr worktree list";
        hmobile = "hpm-harch-hios";
        htrio = "hpm-harch-hios";
        hvault3 = "hvault";
      };

      initContent = lib.mkOrder 2100 ''
        # 任意の名前とコマンドでHerdr agentを追加する汎用関数。
        hagent() {
          if [[ $# -lt 2 ]]; then
            echo "usage: hagent <name> <command> [args...]" >&2
            return 64
          fi

          local name="$1"
          shift
          herdr agent start "$name" --cwd "$PWD" -- "$@"
        }

        ${lib.optionalString config.dotfiles.herdr.autoStart ''
          # Herdrペイン内ではHERDR_ENVが設定されるため、最上位の対話shellだけUIを起動する。
          if [[ -o interactive && -t 0 && -t 1 && ''${SHLVL:-1} -eq 1 && -z "''${HERDR_ENV:-}" ]]; then
            command herdr
          fi
        ''}
      '';
    };
  };
}
