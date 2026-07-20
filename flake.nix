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
    in
    {
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
