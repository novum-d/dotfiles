# Continue設定
{ config, ... }:
{
  home.file = {
    ".continue/config.yaml".text =
      builtins.replaceStrings
        [ "@HOME@" ]
        [
          config.home.homeDirectory
        ]
        (builtins.readFile ./config.yaml);
    ".continue/prompts".source = ./prompts;
    ".continue/rules".source = ./rules;
  };
}
