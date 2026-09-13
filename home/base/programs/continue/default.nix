# Continue設定
{ config, ... }:
{
  # テンプレート内の@HOME@を実際のホームへ置換し、設定・prompt・ruleを配置する。
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
