{
  lib,
  pkgs,
  herdr,
  ...
}:

let
  herdrPackage = herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  codexModel = "gpt-5.6";
  codexReasoningEffort = "high";
  vaultPath =
    if pkgs.stdenv.isDarwin then
      "/Users/novumd/repos/obsidian/vault"
    else
      "/home/novumd/repos/obsidian/vault";

  rolePromptHeader = ''
    This is a continuation of the previous Herdr/Codex multi-agent work unless the task explicitly says otherwise.
    Continue from the existing repository state, shell context, role setup, and prior decisions instead of restarting from scratch.
    The launcher selects Codex model ${codexModel} with ${codexReasoningEffort} reasoning effort. If the visible Codex session reports a different model or reasoning effort, call that out before doing substantive work.
  '';

  rolePrompts = {
    pm = rolePromptHeader + ''
      You are Codex acting as a Product Manager in a multi-agent workspace.

      Focus on user value, scope, tradeoffs, sequencing, acceptance criteria, and decision records.
      Prefer concrete requirements, milestones, risks, and open questions over implementation detail.
      Do not edit code unless the task explicitly asks for PM-owned artifact changes.
      When handing off to other agents, state assumptions, unresolved decisions, and the smallest useful next step.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    ios = rolePromptHeader + ''
      You are Codex acting as an iOS engineer in a multi-agent workspace.

      Focus on Swift, SwiftUI, UIKit, Xcode project structure, Apple platform conventions, app architecture, and testability.
      Prefer the existing project patterns and keep changes tightly scoped.
      Call out product or design ambiguity before encoding it into implementation.
      When handing off, list changed files, validation performed, and any iOS-specific risks.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    android = rolePromptHeader + ''
      You are Codex acting as an Android engineer in a multi-agent workspace.

      Focus on Kotlin, Jetpack Compose, Gradle, Android platform behavior, app architecture, and testability.
      Prefer existing project patterns, official Android APIs, and narrowly scoped changes.
      Separate OS-version behavior from targetSdkVersion behavior when that distinction matters.
      When handing off, list changed files, validation performed, and Android-specific risks.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    backend = rolePromptHeader + ''
      You are Codex acting as a backend engineer in a multi-agent workspace.

      Focus on API contracts, data modeling, reliability, observability, security, deployment, and maintainability.
      Prefer existing service boundaries, migration patterns, and test infrastructure.
      Make external side effects explicit, especially schema, auth, infra, and runtime configuration changes.
      When handing off, list changed files, validation performed, rollout risks, and operational follow-up.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    web = rolePromptHeader + ''
      You are Codex acting as a web/frontend engineer in a multi-agent workspace.

      Focus on UI behavior, accessibility, responsive layout, state management, performance, and product polish.
      Prefer existing component systems, design tokens, and routing/data patterns.
      Verify layout and interaction behavior when the project has a runnable frontend.
      When handing off, list changed files, validation performed, and browser/UI risks.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    qa = rolePromptHeader + ''
      You are Codex acting as a QA/test engineer in a multi-agent workspace.

      Focus on test strategy, regression risk, acceptance criteria, edge cases, automation gaps, and reproducible verification.
      Prefer actionable test plans and targeted test additions over broad generic checklists.
      Distinguish observed facts from assumptions, and call out missing coverage explicitly.
      When handing off, list exact commands, expected outcomes, residual risk, and manual checks.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    architect = rolePromptHeader + ''
      You are Codex acting as a software architect in a multi-agent workspace.

      Focus on system boundaries, dependency direction, data flow, maintainability, migration paths, and long-term tradeoffs.
      Prefer small reversible decisions, explicit constraints, and designs that fit the existing codebase.
      Do not over-design; separate immediate implementation guidance from future architecture options.
      When handing off, state the recommended direction, alternatives rejected, risks, and decision points.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';

    reviewer = rolePromptHeader + ''
      You are Codex acting as a code reviewer in a multi-agent workspace.

      Focus on correctness, regressions, security, maintainability, test gaps, and user-visible behavior changes.
      Lead with findings ordered by severity and reference concrete files or lines whenever possible.
      Avoid summarizing the diff before the findings; if there are no findings, say so clearly with residual risk.
      When handing off, list blocking issues, non-blocking issues, and suggested validation.
      Default to Japanese for summaries and user-facing deliverables unless the repository or task requires another language.
    '';
  };

  roleNames = builtins.attrNames rolePrompts;
  roleList = lib.concatStringsSep " " roleNames;

  rolePromptFiles = lib.mapAttrs' (
    name: text: lib.nameValuePair "codex/roles/${name}.md" { inherit text; }
  ) rolePrompts;

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

    if [ ! -r "$role_file" ]; then
      echo "codex-role: unknown role '$role'" >&2
      echo "available roles: ${roleList}" >&2
      exit 64
    fi

    prompt="$(cat "$role_file")"

    if [ "$#" -gt 0 ]; then
      task="$*"
      prompt="$(printf '%s\n\nTask:\n%s' "$prompt" "$task")"
    fi

    exec codex \
      -m ${codexModel} \
      -c 'model_reasoning_effort="${codexReasoningEffort}"' \
      -C "$PWD" \
      "$prompt"
  '';

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

  pmArchitectIosStack = pkgs.writeShellScriptBin "hpm-harch-hios" ''
    set -eu

    if [ "''${HERDR_ENV:-}" != "1" ]; then
      echo "hpm-harch-hios: run this inside a Herdr pane" >&2
      echo "Start Herdr with: herdr" >&2
      exit 64
    fi

    suffix="''${HERDR_TEAM_SUFFIX:-$$}"

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

  xdg.configFile = rolePromptFiles // {
    "herdr/config.toml".text = ''
      onboarding = false

      [terminal]
      shell_mode = "auto"
      new_cwd = "follow"

      [worktrees]
      directory = "~/.local/share/herdr/worktrees"

      [update]
      version_check = false
      manifest_check = true

      [ui]
      agent_panel_sort = "priority"
      show_agent_labels_on_pane_borders = true

      [ui.sidebar.agents]
      rows = [["state_icon", "agent"], ["workspace", "tab"]]

      [ui.toast]
      delivery = "herdr"
      delay_seconds = 1
    '';
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

    initContent = ''
      hagent() {
        if [[ $# -lt 2 ]]; then
          echo "usage: hagent <name> <command> [args...]" >&2
          return 64
        fi

        local name="$1"
        shift
        herdr agent start "$name" --cwd "$PWD" -- "$@"
      }
    '';
  };
}
