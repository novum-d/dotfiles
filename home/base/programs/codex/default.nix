{
  config,
  isNixOnDroid ? false,
  pkgs,
  unstable,
  ...
}:

let
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

  codexPackage = if isNixOnDroid then codexForNixOnDroid else unstable.codex;
in
{
  home.packages = with pkgs; [
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

  programs.codex = {
    enable = true;
    # glibc 2.42 uses TCGETS2 for isatty(), but the PRoot bundled with
    # Nix-on-Droid 24.05 does not emulate it. Use the legacy TCGETS path whenever Codex starts on Nix-on-Droid.
    package = codexPackage;
    settings = {
      approval_policy = "on-request";
      approvals_reviewer = "auto_review";
      model = "gpt-5.6-sol";
      model_reasoning_effort = "high";
      projects = {
        "${config.home.homeDirectory}" = {
          trust_level = "trusted";
        };
        "${config.home.homeDirectory}/repos/dotfiles" = {
          trust_level = "trusted";
        };
      };
      sandbox_mode = "workspace-write";
    };
  };
}
