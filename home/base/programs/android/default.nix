# Android SDKとCLIの共通設定
{
  lib,
  pkgs,
  unstable,
  ...
}:

let
  # Android SDKの標準配置はmacOSとLinuxで異なるため、評価時に切り替える。
  androidHome =
    if pkgs.stdenv.hostPlatform.isDarwin then "$HOME/Library/Android/sdk" else "$HOME/Android/Sdk";
in
{
  home = {
    # adbは全環境へ、Android SDK CLIは対応プラットフォームだけへ追加する。
    packages = [
      pkgs.android-tools
    ]
    ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform unstable.android-cli) unstable.android-cli;

    # Android関連ツールが同じSDKを参照できるよう環境変数をそろえる。
    sessionVariables = {
      ANDROID_HOME = androidHome;
      ANDROID_SDK_ROOT = androidHome;
    };

    # SDK Manager、emulator、adbをコマンド名だけで実行できるようにする。
    sessionPath = lib.mkBefore [
      "${pkgs.android-tools}/bin"
      "${androidHome}/cmdline-tools/latest/bin"
      "${androidHome}/emulator"
      "${androidHome}/platform-tools"
    ];
  };
}
