{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-droid.url = "github:NixOS/nixpkgs/88d3861acdd3d2f0e361767018218e51810df8a1";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-droid.url = "github:nix-community/home-manager/2539eba97a6df237d75617c25cd2dbef92df3d5b";
    home-manager-droid.inputs.nixpkgs.follows = "nixpkgs-droid";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";

      # nix-on-droid#495 の一時回避
      inputs.nixpkgs.follows = "nixpkgs-droid";
      inputs.home-manager.follows = "home-manager-droid";
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
      nixpkgs-droid,
      home-manager,
      home-manager-droid,
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

      droidPkgs = import nixpkgs-droid {
        system = "aarch64-linux";
        overlays = [ nix-on-droid.overlays.default ];
        config.allowUnfree = true;
      };

      droidUnstable = import nixpkgs-unstable {
        system = "aarch64-linux";
        config.allowUnfree = true;
      };

      localConfig = import ./config;
      inherit (localConfig) username;
    in
    {
      nixOnDroidConfigurations = rec {
        pixel7pro = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = droidPkgs;
          home-manager-path = home-manager-droid.outPath;

          modules = [
            ./hosts/pixel7pro
            {
              home-manager.extraSpecialArgs = {
                unstable = droidUnstable;
                guiPkgs = droidUnstable;
                isNixOnDroid = true;
                isWsl = false;
                inherit herdr;
              };
            }
          ];
        };

        # Keep `nix-on-droid switch --flake .` working for the primary device.
        default = pixel7pro;
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
            inherit username;
            unstable = nixosUnstable;
            guiPkgs = nixosUnstable;
          };
          modules = [
            ./hosts/xps15/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";

                extraSpecialArgs = {
                  unstable = nixosUnstable;
                  guiPkgs = nixosUnstable;
                  isNixOnDroid = false;
                  isWsl = false;
                  inherit herdr;
                };
              };
            }
          ];
        };
        windows-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit username;
            unstable = nixosUnstable;
            guiPkgs = nixosUnstable;
          };
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/windows-vm
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";

                extraSpecialArgs = {
                  unstable = nixosUnstable;
                  guiPkgs = nixosUnstable;
                  isNixOnDroid = false;
                  isWsl = true;
                  inherit herdr;
                };
              };
            }
          ];
        };
      };
      darwinConfigurations."novumdnoMac-mini" = nix-darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit unstable username;
          guiPkgs = unstable;
        };

        modules = [
          ./hosts/Mac-mini
          ./home/darwin

          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              extraSpecialArgs = {
                inherit unstable;
                inherit herdr;
                guiPkgs = unstable;
                isNixOnDroid = false;
                isWsl = false;
              };
            };

            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
            };
          }
        ];
      };
    };
}
