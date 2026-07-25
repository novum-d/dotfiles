# Android development settings
{
  lib,
  pkgs,
  unstable,
  ...
}:

let
  androidHome = if pkgs.stdenv.isDarwin then "$HOME/Library/Android/sdk" else "$HOME/Android/Sdk";
in
{
  home = {
    packages = [
      pkgs.android-tools
    ]
    ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform unstable.android-cli) unstable.android-cli;

    sessionVariables = {
      ANDROID_HOME = androidHome;
      ANDROID_SDK_ROOT = androidHome;
    };

    sessionPath = lib.mkBefore [
      "${pkgs.android-tools}/bin"
      "${androidHome}/cmdline-tools/latest/bin"
      "${androidHome}/emulator"
      "${androidHome}/platform-tools"
    ];
  };
}
