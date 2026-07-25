{
  lib,
  pkgs,
  ...
}:

let
  droidCodexDuo = pkgs.writeShellScriptBin "hcodex-duo" ''
    set -eu

    if [ "''${HERDR_ENV:-}" != "1" ]; then
      echo "hcodex-duo: run this inside a Herdr pane" >&2
      echo "Start Herdr with: herdr" >&2
      exit 64
    fi

    suffix="''${HERDR_TEAM_SUFFIX:-$$}"

    herdr agent start "codex-bottom-$suffix" \
      --cwd "$PWD" \
      --split down \
      --focus \
      -- codex "$@"

    exec codex "$@"
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
      imports = [ ../base ];

      home.packages = [ droidCodexDuo ];

      programs.zsh.shellAliases = {
        hmobile = lib.mkForce "hcodex-duo";
        hphone = "hcodex-duo";
      };
    };
  };
}
