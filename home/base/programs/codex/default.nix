# Codex本体、実行ラッパー、Home Manager設定
{
  codexModels,
  config,
  isNixOnDroid ? false,
  lib,
  pkgs,
  unstable,
  ...
}:

let
  # モデル選択の正本はconfig/default.nixに置き、ラッパーと設定で同じ値を使う。
  primaryModel = codexModels.preferred.model;
  primaryReasoningEffort = codexModels.preferred.reasoningEffort;
  fallbackModel = codexModels.fallback.model;
  fallbackReasoningEffort = codexModels.fallback.reasoningEffort;

  # nixpkgs-unstableがCodexの更新へ追いつくまでは、パッケージ定義のversionとsourceだけを上書きする。
  codexMinimumVersion = "0.153.1";
  codexPackage =
    if lib.versionAtLeast unstable.codex.version codexMinimumVersion then
      unstable.codex
    else
      unstable.codex.overrideAttrs (_: rec {
        version = codexMinimumVersion;
        src = unstable.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          tag = "rust-v${version}";
          hash = "sha256-u7bp0B3MUuPIlk1QUKz267EGedjwMgTaoSNoYI5piLQ=";
        };
        cargoDeps = unstable.rustPlatform.fetchCargoVendor {
          inherit src;
          sourceRoot = "${src.name}/codex-rs";
          hash = "sha256-GG6kOXmCdq+bZLU2ul0DIVL8lDuweayvZvXn6+bcUZw=";
        };
      });

  # Codexのproject trustは親ディレクトリから継承されず、リポジトリルートの
  # 完全一致で判定される。Home Manager管理のconfig.tomlは読み取り専用なので、
  # 利用するリポジトリをここで宣言し、TUIによる書き戻しを発生させない。
  trustedRepositoryNames = [
    "TvApp"
    "android-platform-research"
    "base"
    "dotfiles"
    "obsidian"
    "zunda-bot-rs"
  ];
  trustedRepositories = lib.listToAttrs (
    map (name: {
      name = "${config.home.homeDirectory}/repos/${name}";
      value.trust_level = "trusted";
    }) trustedRepositoryNames
  );

  # Nix-on-DroidのPRootが扱えないTCGETS2を避け、従来のTCGETSでisattyを判定する共有ライブラリ。
  # constructorで元のLD_PRELOADを復元し、Codexの子プロセスへ回避策を漏らさない。
  legacyIsatty = pkgs.runCommandCC "codex-legacy-isatty" { } ''
    mkdir -p "$out/lib"
    "$CC" \
      -shared \
      -fPIC \
      -O2 \
      -Wall \
      -Wextra \
      -Werror \
      -Wl,--version-script=${pkgs.writeText "codex-legacy-isatty.map" ''
        GLIBC_2.17 {
          global: isatty;
        };
      ''} \
      ${pkgs.writeText "codex-legacy-isatty.c" ''
        #include <stdlib.h>
        #include <sys/ioctl.h>
        #include <termios.h>
        #include <unistd.h>

        int isatty(int fd) {
          struct termios attributes;
          return ioctl(fd, TCGETS, &attributes) == 0;
        }

        __attribute__((constructor))
        static void restore_ld_preload(void) {
          const char *original =
              getenv("CODEX_NIX_ON_DROID_ORIGINAL_LD_PRELOAD");

          if (original != NULL && original[0] != '\0') {
            setenv("LD_PRELOAD", original, 1);
          } else {
            unsetenv("LD_PRELOAD");
          }

          unsetenv("CODEX_NIX_ON_DROID_ORIGINAL_LD_PRELOAD");
        }
      ''} \
      -o "$out/lib/libcodex-legacy-isatty.so"
  '';

  # Nix-on-Droidだけ互換ライブラリと実行時CLIを追加してCodex本体を起動する。
  codexForNixOnDroid = pkgs.writeShellScriptBin "codex" ''
    set -eu

    codex_original_ld_preload="''${LD_PRELOAD:-}"
    export CODEX_NIX_ON_DROID_ORIGINAL_LD_PRELOAD="$codex_original_ld_preload"
    export LD_PRELOAD="${legacyIsatty}/lib/libcodex-legacy-isatty.so''${codex_original_ld_preload:+:$codex_original_ld_preload}"
    export PATH="${
      unstable.lib.makeBinPath [
        unstable.ripgrep
        unstable.bubblewrap
      ]
    }:$PATH"

    exec ${codexPackage}/bin/.codex-wrapped "$@"
  '';

  codexBasePackage = if isNixOnDroid then codexForNixOnDroid else codexPackage;

  # 利用可能なモデル一覧を確認し、preferredが使えない場合だけfallbackへ切り替える。
  codexWithFallback = pkgs.writeShellApplication {
    name = "codex";
    # Home Managerが旧config.yamlではなくconfig.tomlを選べるようversionを引き継ぐ。
    passthru.version = codexPackage.version;
    runtimeInputs = [ pkgs.jq ];
    text = ''
      preferred_model="${primaryModel}"
      preferred_reasoning_effort="${primaryReasoningEffort}"
      fallback_model="${fallbackModel}"
      fallback_reasoning_effort="${fallbackReasoningEffort}"
      selected_model="$preferred_model"
      selected_reasoning_effort="$preferred_reasoning_effort"

      model_catalog="$(${codexBasePackage}/bin/codex debug models 2>/dev/null)" || model_catalog=""

      if [ -n "$model_catalog" ] &&
        ! jq -e \
          --arg model "$preferred_model" \
          --arg effort "$preferred_reasoning_effort" \
          '.models | any(.slug == $model and (.supported_reasoning_levels | any(.effort == $effort)))' \
          >/dev/null <<<"$model_catalog"
      then
        if jq -e \
          --arg model "$fallback_model" \
          --arg effort "$fallback_reasoning_effort" \
          '.models | any(.slug == $model and (.supported_reasoning_levels | any(.effort == $effort)))' \
          >/dev/null <<<"$model_catalog"
        then
          selected_model="$fallback_model"
          selected_reasoning_effort="$fallback_reasoning_effort"
          echo "codex: $preferred_model/$preferred_reasoning_effort is unavailable; using $fallback_model/$fallback_reasoning_effort" >&2
        else
          echo "codex: neither $preferred_model/$preferred_reasoning_effort nor $fallback_model/$fallback_reasoning_effort is available; trying the preferred model" >&2
        fi
      fi

      export CODEX_CONFIGURED_MODEL="$selected_model"
      export CODEX_CONFIGURED_REASONING_EFFORT="$selected_reasoning_effort"

      exec ${codexBasePackage}/bin/codex \
        -m "$selected_model" \
        -c "model_reasoning_effort=\"$selected_reasoning_effort\"" \
        "$@"
    '';
  };
in
{
  # Codexのruleは専用形式のファイルに分け、個別にレビュー・再利用できるようにする。
  home.file = {
    ".codex/rules/development.rules".source = ./rules/development.rules;
    ".codex/rules/git.rules".source = ./rules/git.rules;
    ".codex/rules/information-gathering.rules".source = ./rules/information-gathering.rules;
    ".codex/rules/nix.rules".source = ./rules/nix.rules;
  };

  home.packages = with pkgs; [
    # Codexがファイル調査や機械的編集で利用する基礎CLI。
    bzip2
    file
    gawk
    gzip
    patch
    perl
    python3
    rsync
    xz
  ];

  programs.codex = {
    enable = true;
    # Nix-on-Droidでは上記のTCGETS互換ラッパーを、それ以外では通常のCodexを使う。
    package = codexWithFallback;
    settings = {
      # 通常はsandbox内で実行し、権限拡張が必要な操作はCodex内の自動レビューへ送る。
      approval_policy = "on-request";
      approvals_reviewer = "auto_review";
      # Nixで更新を一元管理しているため、CLI自身の更新通知を止める。
      check_for_update_on_startup = false;
      features.context_management.experimental_mode = true;
      mcp_servers.openaiDeveloperDocs.url = "https://developers.openai.com/mcp";
      model = primaryModel;
      model_reasoning_effort = primaryReasoningEffort;
      projects = {
        "${config.home.homeDirectory}".trust_level = "trusted";
      }
      // trustedRepositories
      // lib.optionalAttrs isNixOnDroid {
        "/storage/emulated/0/Sync/obsidian" = {
          trust_level = "trusted";
        };
      };

      # リポジトリを含むホーム配下へ書き込みを許可し、sandbox内のnetworkも利用可能にする。
      sandbox_mode = "workspace-write";
      sandbox_workspace_write = {
        network_access = true;
        writable_roots = [ config.home.homeDirectory ];
      };
      # Codexが非表示のときだけ完了・承認要求を通知する。
      tui = {
        notifications = [
          "agent-turn-complete"
          "approval-requested"
        ];
        notification_condition = "unfocused";
      };
    };
  };
}
