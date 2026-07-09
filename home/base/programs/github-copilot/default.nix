{ unstable, ... }:

{
  home.packages = with unstable; [
    github-copilot-cli
  ];

  home.sessionVariables = {
    COPILOT_MODEL = "gpt-5.5";
  };
}
