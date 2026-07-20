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
  home.packages = with pkgs; [
    android-tools
    unstable.android-cli
  ];

  home.sessionVariables = {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
  };

  home.sessionPath = lib.mkBefore [
    "${pkgs.android-tools}/bin"
    "${androidHome}/cmdline-tools/latest/bin"
    "${androidHome}/emulator"
    "${androidHome}/platform-tools"
  ];
}
