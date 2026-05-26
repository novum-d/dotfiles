# Android development settings
{ pkgs, ... }:

let
  androidHome =
    if pkgs.stdenv.isDarwin then
      "$HOME/Library/Android/sdk"
    else
      "$HOME/Android/Sdk";
in
{
  home.packages = with pkgs; [
    android-tools
  ];

  home.sessionVariables = {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
  };

  home.sessionPath = [
    "${androidHome}/cmdline-tools/latest/bin"
    "${androidHome}/emulator"
    "${androidHome}/platform-tools"
  ];
}
