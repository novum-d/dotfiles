{ config, pkgs, ... }:
let
  termuxProperties = pkgs.writeText "termux.properties" ''
    enforce-char-based-input = true
  '';
  termuxConfigDir = "${config.user.home}/.termux";
  termuxPropertiesPath = "${config.build.installationDir}/${termuxProperties}";
in
{
  android-integration.termux-reload-settings.enable = true;

  build.activationAfter.linkTermuxProperties = ''
    $DRY_RUN_CMD mkdir $VERBOSE_ARG -p "${termuxConfigDir}"
    if [ -e "${termuxConfigDir}/termux.properties" ] && ! [ -L "${termuxConfigDir}/termux.properties" ]; then
      $DRY_RUN_CMD mv $VERBOSE_ARG \
        "${termuxConfigDir}/termux.properties" \
        "${termuxConfigDir}/termux.properties.bak"
    fi
    $DRY_RUN_CMD ln $VERBOSE_ARG -sf \
      "${termuxPropertiesPath}" \
      "${termuxConfigDir}/termux.properties"
  '';
}
