{ pkgs, unstable, ... }:

{
  imports = [
    ../base/programs/continue
    ../base/programs/git
    ../base/programs/lazygit
    ../base/programs/lazyvim
    ../base/programs/ssh
    ../base/programs/tmux
    ../base/programs/zsh
  ];

  manual.manpages.enable = false;

  home = {
    packages =
      (with pkgs; [
        bat
        curl
        eza
        fd
        fzf
        ghq
        git-lfs
        gnumake
        jq
        just
        nil
        nixfmt
        openssl
        pkg-config
        ripgrep
        shellcheck
        shfmt
        tree
        wget
        yq-go
      ])
      ++ [
        unstable.gh
      ];

    enableNixpkgsReleaseCheck = false;
    stateVersion = "26.05";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}
