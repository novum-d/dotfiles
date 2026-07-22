{
  description = "NixOS configuration of novumd";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    herdr.url = "github:ogulcancelik/herdr/v0.7.4";
    herdr.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      nix-homebrew,
      nix-on-droid,
      nixos-wsl,
      herdr,
      ...
    }:
    let
      system = "aarch64-darwin";

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      nixosUnstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      droidPkgs = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ nix-on-droid.overlays.default ];
        config.allowUnfree = true;
      };
    in
    {
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = droidPkgs;
        home-manager-path = home-manager.outPath;

        modules = [
          {
            environment = {
              etcBackupExtension = ".bak";
              packages = with droidPkgs; [
                coreutils
                curl
                diffutils
                findutils
                git
                gnugrep
                gnused
                gnutar
                openssh
                procps
                vim
                wget
              ];
            };

            nix.extraOptions = ''
              experimental-features = nix-command flakes
            '';

            time.timeZone = "Asia/Tokyo";
            system.stateVersion = "24.05";

            home-manager = {
              backupFileExtension = "hm-bak";
              useGlobalPkgs = true;
              config =
                { lib, pkgs, ... }:
                {
                  imports = [
                    ./home/base/programs/zsh
                    ./home/base/programs/git
                    ./home/base/programs/lazyvim
                    ./home/base/programs/tmux
                    ./home/base/programs/continue
                  ];

                  manual.manpages.enable = false;
                  home = {
                    stateVersion = "26.05";
                    packages = with pkgs; [
                      bat
                      eza
                      fd
                      fzf
                      jq
                      lazygit
                      ripgrep
                      tree
                      unzip
                      zip
                    ];
                    sessionVariables.EDITOR = "nvim";
                  };

                  programs.zsh.shellAliases.u =
                    lib.mkForce "nix-on-droid switch --flake .";
                };
            };
          }
        ];
      };

      formatter.x86_64-linux = nixosUnstable.writeShellApplication {
        name = "nixfmt-tree";
        runtimeInputs = with nixosUnstable; [
          findutils
          nixfmt
        ];
        text = ''
          if [ "$#" -gt 0 ]; then
            exec nixfmt "$@"
          fi

          find . -name '*.nix' -print0 | xargs -0 nixfmt
        '';
      };

      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            unstable = nixosUnstable;
            guiPkgs = nixosUnstable;
          };
          modules = [
            ./hosts/xps15/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                unstable = nixosUnstable;
                guiPkgs = nixosUnstable;
                inherit herdr;
              };
            }
          ];
        };
        wsl-nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            unstable = nixosUnstable;
            guiPkgs = nixosUnstable;
          };
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl-nixos/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                unstable = nixosUnstable;
                guiPkgs = nixosUnstable;
                inherit herdr;
              };
            }
          ];
        };
      };
      darwinConfigurations."novumdnoMac-mini" = nix-darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit unstable;
          guiPkgs = unstable;
        };

        modules = [
          ./hosts/Mac-mini
          ./home/darwin

          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit unstable;
              inherit herdr;
              guiPkgs = unstable;
            };

            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "novumd";
            };
          }
        ];
      };
    };
}
