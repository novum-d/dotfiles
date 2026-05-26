# Mise settings
{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        rust = "latest";
        java = "latest";
        elixir = "latest";
      };
    };
  };
}
