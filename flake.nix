{
  description = "Cross-platform Nix configurations for macOS, NixOS, WSL, and Nix-on-Droid";

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
      systems = {
        darwin = "aarch64-darwin";
        droid = "aarch64-linux";
        linux = "x86_64-linux";
      };

      mkUnstablePackages =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      darwinUnstable = mkUnstablePackages systems.darwin;
      droidUnstable = mkUnstablePackages systems.droid;
      nixosUnstable = mkUnstablePackages systems.linux;

      droidPkgs = import nixpkgs-droid {
        system = systems.droid;
        overlays = [ nix-on-droid.overlays.default ];
        config.allowUnfree = true;
      };

      localConfig = import ./config;
      inherit (localConfig) codexModels syncthing username;

      # 全Home Manager構成へ渡す値を一箇所に集約し、環境差だけを引数にする。
      mkHomeManagerExtraArgs =
        {
          unstablePackages,
          isNixOnDroid ? false,
          isWsl ? false,
        }:
        {
          unstable = unstablePackages;
          guiPkgs = unstablePackages;
          inherit
            codexModels
            herdr
            isNixOnDroid
            isWsl
            syncthing
            ;
        };

      nixosSpecialArgs = {
        inherit username;
        unstable = nixosUnstable;
        guiPkgs = nixosUnstable;
      };
      mkNixosConfiguration =
        {
          hostModule,
          isWsl ? false,
          platformModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          system = systems.linux;
          specialArgs = nixosSpecialArgs;
          modules = platformModules ++ [
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = mkHomeManagerExtraArgs {
                  unstablePackages = nixosUnstable;
                  inherit isWsl;
                };
              };
            }
          ];
        };
    in
    {
      nixOnDroidConfigurations = rec {
        pixel7pro = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = droidPkgs;
          home-manager-path = home-manager-droid.outPath;

          modules = [
            ./hosts/pixel7pro
            {
              home-manager.extraSpecialArgs = mkHomeManagerExtraArgs {
                unstablePackages = droidUnstable;
                isNixOnDroid = true;
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
        nixos = mkNixosConfiguration {
          hostModule = ./hosts/xps15/configuration.nix;
        };
        windows-vm = mkNixosConfiguration {
          hostModule = ./hosts/windows-vm;
          isWsl = true;
          platformModules = [ nixos-wsl.nixosModules.default ];
        };
      };
      darwinConfigurations."novumdnoMac-mini" = nix-darwin.lib.darwinSystem {
        system = systems.darwin;

        specialArgs = {
          inherit username;
          unstable = darwinUnstable;
          guiPkgs = darwinUnstable;
        };

        modules = [
          ./hosts/Mac-mini
          ./modules/darwin

          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              extraSpecialArgs = mkHomeManagerExtraArgs {
                unstablePackages = darwinUnstable;
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
