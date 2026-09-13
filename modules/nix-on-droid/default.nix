# Nix-on-Droid共通のシステム・Home Manager設定
{
  lib,
  pkgs,
  ...
}:

let
  # モバイル用の2ペイン作業でも、既存セッションと判断を引き継ぐようCodexへ伝える。
  duoPromptHeader = ''
    This is a continuation of the previous Herdr/Codex mobile duo work unless the task explicitly says otherwise.
    Continue from the existing repository state, shell context, and prior decisions instead of restarting from scratch.
    Do not mention, compare, or report the model or reasoning effort unless the user explicitly asks about them.
  '';

  # 現在のHerdrペインを維持しつつ、下側に追加のCodexペインを起動する。
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
  # Androidの共有ストレージをNix-on-Droidから参照できるようにする。
  android-integration.termux-setup-storage.enable = true;

  # 端末復旧や基本的なCLI操作に必要な最小パッケージをシステム側へ置く。
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

  # Flakeを利用するための実験的機能をNix-on-Droidでも有効にする。
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  user.shell = "${pkgs.zsh}/bin/zsh";

  # システム側のパッケージセットをHome Managerでも使い、共通ユーザー設定を読み込む。
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    config = {
      imports = [ ../../home/base ];

      # 小さい画面ではHerdrの自動起動を止め、必要なときだけ専用aliasから起動する。
      dotfiles.herdr.autoStart = false;

      home.packages = [ droidCodexDuo ];

      programs.zsh.shellAliases = {
        hmobile = lib.mkForce "hcodex-duo";
        hphone = "hcodex-duo";
      };
    };
  };
}
