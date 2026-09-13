# LinuxとWSLで共有するAndroid Studio起動設定の生成関数
{
  lib,
  pkgs,
  androidStudio,
  isWsl ? false,
}:

let
  # Compose/Android Studioの入力メソッドをX11上のfcitx5へ統一する。
  inputMethodEnvironment = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    QT_IM_MODULES = "wayland;fcitx;ibus";
    SDL_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # 上の属性セットを起動スクリプトで使えるexport文へ変換する。
  inputMethodExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: value: "export ${name}=${lib.escapeShellArg value}"
    ) inputMethodEnvironment
  );

  # Android Studioが参照するユーザー設定内のVM optionファイル。
  vmOptionsConfigPath = "Google/AndroidStudio2026.1.1/studio64.vmoptions";
in
{
  # Home Manager側のsessionVariablesにも同じ入力メソッド設定を再利用させる。
  inherit inputMethodEnvironment;

  vmOptionsRelativePath = ".config/${vmOptionsConfigPath}";
  vmOptions = ''
    -Dawt.toolkit.name=XToolkit
    -Dsun.awt.enableInputMethods=true
    -Djava.awt.im.style=on-the-spot
    -Drecreate.x11.input.method=true
  '';

  # GUIプロセスをshellから切り離し、必要なD-Busセッションとfcitx5を準備する。
  mkLauncher =
    name:
    pkgs.writeShellScriptBin name ''
      set -u

      ${inputMethodExports}
      export STUDIO_VM_OPTIONS="''${XDG_CONFIG_HOME:-$HOME/.config}/${vmOptionsConfigPath}"

      # 端末を閉じてもGUIを終了させないよう、最初の起動だけ別セッションへ切り離す。
      if [ -z "''${_DOTFILES_STUDIO_DETACHED-}" ]; then
        export _DOTFILES_STUDIO_DETACHED=1
        exec ${pkgs.util-linux}/bin/setsid --fork "$0" "$@" </dev/null >/dev/null 2>&1
      fi

      ${lib.optionalString isWsl ''
        # WSLgがDISPLAYを公開しなかった場合だけ既定のX11 socketへ接続する。
        if [ -z "''${DISPLAY-}" ] && [ -S /tmp/.X11-unix/X0 ]; then
          export DISPLAY=:0
        fi
      ''}

      # D-Busセッションがない端末から起動した場合は、一度だけセッションを作り直す。
      if [ -z "''${DBUS_SESSION_BUS_ADDRESS-}" ] && command -v dbus-run-session >/dev/null 2>&1; then
        exec dbus-run-session -- "$0" "$@"
      fi

      unset _DOTFILES_STUDIO_DETACHED

      # GUIアプリが現在のdisplayと入力メソッドを参照できるようD-Busへ反映する。
      if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        dbus-update-activation-environment --systemd \
          DISPLAY WAYLAND_DISPLAY XAUTHORITY \
          XMODIFIERS GTK_IM_MODULE QT_IM_MODULE QT_IM_MODULES SDL_IM_MODULE \
          >/dev/null 2>&1 || true
      fi

      # X11 displayがある場合だけfcitx5を起動し、Mozcを有効にする。
      if command -v fcitx5 >/dev/null 2>&1 && [ -n "''${DISPLAY-}" ]; then
        fcitx5 --disable waylandim -d --replace >/dev/null 2>&1 || true
        fcitx5-remote -s mozc >/dev/null 2>&1 || true
        fcitx5-remote -o >/dev/null 2>&1 || true
      fi

      # Android StudioはXWayland経由で起動し、Composeの日本語入力を安定させる。
      unset WAYLAND_DISPLAY
      exec ${androidStudio}/bin/android-studio "$@"
    '';
}
