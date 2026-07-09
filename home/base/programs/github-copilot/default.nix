{ pkgs, ... }:

{
  home.packages = with pkgs; [
    github-copilot-cli
  ];

  home.sessionVariables = {
    COPILOT_MODEL = "gpt-5.5";
  };
}
