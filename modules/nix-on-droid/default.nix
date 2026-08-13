# Nix-on-Droid共通のシステム・Home Manager設定
{
  lib,
  pkgs,
  ...
}:

let
  duoPromptHeader = ''
    This is a continuation of the previous Herdr/Codex mobile duo work unless the task explicitly says otherwise.
    Continue from the existing repository state, shell context, and prior decisions instead of restarting from scratch.
    Do not mention, compare, or report the model or reasoning effort unless the user explicitly asks about them.
  '';

  droidCodexDuo = pkgs.writeShellScriptBin "hcodex-duo" ''
    set -eu

    if [ "''${HERDR_ENV:-}" != "1" ]; then
      echo "hcodex-duo: run this inside a Herdr pane" >&2
      echo "Start Herdr with: herdr" >&2
      exit 64
    fi

    suffix="''${HERDR_TEAM_SUFFIX:-$$}"
    agent_name="codex-bottom-v3-$suffix"
    prompt="${duoPromptHeader}"

    if [ "$#" -gt 0 ]; then
      prompt="$(printf '%s\n\nTask:\n%s' "$prompt" "$*")"
    fi

    herdr agent start "$agent_name" \
      --cwd "$PWD" \
      --split down \
      --focus \
      -- codex "$prompt"

    exec codex "$prompt"
  '';
in
{
  android-integration.termux-setup-storage.enable = true;

  environment = {
    etcBackupExtension = ".bak";
    packages = with pkgs; [
      coreutils
      curl
      diffutils
      findutils
      git
      gnugrep
      gnused
      gnutar
      openssh
      procps
      vim
      wget
    ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  user.shell = "${pkgs.zsh}/bin/zsh";

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    config = {
      imports = [ ../../home/base ];

      home.packages = [ droidCodexDuo ];

      programs.zsh.shellAliases = {
        hmobile = lib.mkForce "hcodex-duo";
        hphone = "hcodex-duo";
      };
    };
  };
}
