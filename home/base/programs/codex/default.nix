{ config, unstable, ... }:

{
  programs.codex = {
    enable = true;
    package = unstable.codex;
    settings = {
      approval_policy = "on-request";
      approvals_reviewer = "auto_review";
      model = "gpt-5.6-sol";
      model_reasoning_effort = "high";
      projects = {
        "${config.home.homeDirectory}" = {
          trust_level = "trusted";
        };
        "${config.home.homeDirectory}/repos/dotfiles" = {
          trust_level = "trusted";
        };
      };
      sandbox_mode = "workspace-write";
    };
  };
}
