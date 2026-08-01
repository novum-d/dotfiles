{
  config,
  isNixOnDroid ? false,
  lib,
  pkgs,
  unstable,
  ...
}:

let
  primaryModel = "gpt-5.6-sol";
  primaryReasoningEffort = "high";
  fallbackModel = "gpt-5.5";
  fallbackReasoningEffort = "high";

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

    exec ${unstable.codex}/bin/.codex-wrapped "$@"
  '';

  codexBasePackage = if isNixOnDroid then codexForNixOnDroid else unstable.codex;

  codexWithFallback = pkgs.writeShellApplication {
    name = "codex";
    # Home Manager uses the package version to select config.toml instead of legacy config.yaml.
    passthru.version = unstable.codex.version;
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
  home = {
    file = {
      ".codex/rules/nix.rules".text = ''
        prefix_rule(
            pattern = ["nix"],
            decision = "allow",
            justification = "Allow Nix commands without repeated approval prompts",
            match = [
                "nix build .#darwinConfigurations.novumdnoMac-mini.config.system.build.toplevel",
                "nix eval --raw .#nixosConfigurations.windows-vm.config.system.build.toplevel.drvPath",
                "nix flake check --no-build --no-warn-dirty",
                "nix shell nixpkgs#nixfmt --command nixfmt --check flake.nix",
            ],
        )
      '';

      ".codex/rules/git.rules".text = ''
        prefix_rule(
            pattern = ["git"],
            decision = "allow",
            justification = "Allow Git operations without repeated approval prompts",
            match = [
                "git status --short",
                "git add -- flake.nix",
                "git commit -m 'Update configuration'",
                "git push origin master",
            ],
        )
      '';

      ".codex/rules/information-gathering.rules".text = ''
        prefix_rule(
            pattern = [["rg", "fd", "find", "grep", "locate", "mdfind"]],
            decision = "allow",
            justification = "Allow local file and text searches without repeated approval prompts",
            match = [
                "rg -n approval_policy .",
                "fd config.toml /Users/example",
                "find /Applications -name *.app",
                "grep -R sandbox_mode /etc",
                "locate config.toml",
                "mdfind kMDItemFSName == '*.nix'",
            ],
        )

        prefix_rule(
            pattern = [["ls", "stat", "file", "cat", "head", "tail", "jq", "ps", "lsof", "uname", "sw_vers", "system_profiler", "readlink", "realpath", "pwd", "dirname", "basename", "which", "whereis", "du", "df", "tree", "eza", "bat", "wc", "diff", "cmp", "shasum", "md5", "strings"]],
            decision = "allow",
            justification = "Allow read-only local inspection without repeated approval prompts",
            match = [
                "ls -la /Applications",
                "stat flake.nix",
                "file /bin/zsh",
                "cat /etc/os-release",
                "head -n 20 flake.nix",
                "tail -n 20 flake.nix",
                "jq . flake.lock",
                "ps aux",
                "lsof -iTCP -sTCP:LISTEN",
                "uname -a",
                "sw_vers",
                "system_profiler SPSoftwareDataType",
                "readlink ~/.config/mise/config.toml",
                "realpath flake.nix",
                "pwd",
                "dirname /Users/example/config.toml",
                "basename /Users/example/config.toml",
                "which nix",
                "whereis nix",
                "du -sh /nix/store",
                "df -h",
                "tree home/base/programs",
                "eza -la home/base/programs",
                "bat flake.nix",
                "wc -l flake.nix",
                "diff old.conf new.conf",
                "cmp old.conf new.conf",
                "shasum -a 256 flake.lock",
                "md5 flake.lock",
                "strings /bin/zsh",
            ],
        )

        prefix_rule(
            pattern = ["defaults", "read"],
            decision = "allow",
            justification = "Allow reading macOS defaults without repeated approval prompts",
            match = [
                "defaults read com.apple.dock",
            ],
        )

        prefix_rule(
            pattern = [["curl", "wget"]],
            decision = "allow",
            justification = "Allow external information retrieval without repeated approval prompts",
            match = [
                "curl -L https://example.com",
                "wget https://example.com",
            ],
        )

        prefix_rule(
            pattern = ["plutil", "-p"],
            decision = "allow",
            justification = "Allow read-only property list inspection without repeated approval prompts",
            match = [
                "plutil -p /Applications/Example.app/Contents/Info.plist",
            ],
        )

      '';
    };

    packages = with pkgs; [
      # Baseline tools Codex uses for inspection and mechanical edits.
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
  };

  programs.codex = {
    enable = true;
    # glibc 2.42 uses TCGETS2 for isatty(), but the PRoot bundled with
    # Nix-on-Droid 24.05 does not emulate it. Use the legacy TCGETS path whenever Codex starts on Nix-on-Droid.
    package = codexWithFallback;
    settings = {
      approval_policy = "on-request";
      approvals_reviewer = "auto_review";
      mcp_servers.openaiDeveloperDocs.url = "https://developers.openai.com/mcp";
      model = primaryModel;
      model_reasoning_effort = primaryReasoningEffort;
      projects = {
        "${config.home.homeDirectory}" = {
          trust_level = "trusted";
        };
        "${config.home.homeDirectory}/repos/dotfiles" = {
          trust_level = "trusted";
        };
      }
      // lib.optionalAttrs isNixOnDroid {
        "/storage/emulated/0/Sync/obsidian" = {
          trust_level = "trusted";
        };
      };
      sandbox_mode = "workspace-write";
      sandbox_workspace_write = {
        network_access = true;
        writable_roots = [ config.home.homeDirectory ];
      };
    };
  };
}
