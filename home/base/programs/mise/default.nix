# Mise settings
{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        rust = "stable";
        java = "21";
        erlang = "stable";
        elixir = "stable";
      };
    };

    settings = {
      auto_install = true;
      exec_auto_install = true;
      not_found_auto_install = true;
      task_run_auto_install = true;
    };
  };

  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
  ];
}
