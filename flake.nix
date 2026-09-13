{
  description = "Cross-platform Nix configurations for macOS, NixOS, WSL, and Nix-on-Droid";

  inputs = {
    # 通常のmacOS・NixOS・WSLには同じ安定版Nixpkgsを使い、
    # 更新頻度を上げたいツールだけunstableから取得する。
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Nix-on-DroidはPRootとの互換性を優先し、既知の動作するrevisionへ固定する。
    nixpkgs-droid.url = "github:NixOS/nixpkgs/88d3861acdd3d2f0e361767018218e51810df8a1";

    # Home Managerも、それぞれが利用するNixpkgsと同じrevision系列へそろえる。
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-droid.url = "github:nix-community/home-manager/2539eba97a6df237d75617c25cd2dbef92df3d5b";
    home-manager-droid.inputs.nixpkgs.follows = "nixpkgs-droid";

    # macOSのシステム設定とHomebrew本体をNixから管理する。
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Android上ではNixOSではなく、Nix-on-Droid独自のモジュールを評価する。
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";

      # nix-on-droid#495 の一時回避
      inputs.nixpkgs.follows = "nixpkgs-droid";
      inputs.home-manager.follows = "home-manager-droid";
    };

    # WSL出力にNixOS-WSLのシステムモジュールを追加する。
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
      # パッケージセットを作るCPU・OSの組み合わせを一箇所で定義する。
      systems = {
        darwin = "aarch64-darwin";
        droid = "aarch64-linux";
        linux = "x86_64-linux";
      };

      # 各プラットフォーム向けに、非自由パッケージを許可したunstableを用意する。
      mkUnstablePackages =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      darwinUnstable = mkUnstablePackages systems.darwin;
      droidUnstable = mkUnstablePackages systems.droid;
      nixosUnstable = mkUnstablePackages systems.linux;

      # 各systemで同じnixfmtラッパーを公開し、Flakeに固定されたNixpkgsから実行する。
      mkFormatter =
        packageSet:
        packageSet.writeShellApplication {
          name = "nixfmt-tree";
          runtimeInputs = with packageSet; [
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

      # Nix-on-Droidでは専用Nixpkgsとoverlayを組み合わせる。
      droidPkgs = import nixpkgs-droid {
        system = systems.droid;
        overlays = [ nix-on-droid.overlays.default ];
        config.allowUnfree = true;
      };

      # 公開して問題ない共通値だけをconfig/default.nixから読み込む。
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

      # NixOSシステムモジュールへ渡す値。Home Manager用の値とは分けておく。
      nixosSpecialArgs = {
        inherit username;
        unstable = nixosUnstable;
        guiPkgs = nixosUnstable;
      };

      # 実機NixOSとWSLで共通するnixosSystemの組み立てを関数化する。
      # 呼び出し側はホスト、WSL判定、追加モジュールだけを指定する。
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
      # Android端末では専用パッケージセットとホストモジュールを組み合わせる。
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

        # 出力名を省略した`nix-on-droid switch --flake .`でも主端末を選べるようにする。
        default = pixel7pro;
      };

      # macOS、NixOS/WSL、Nix-on-Droidの各systemから`nix fmt`を利用できるようにする。
      formatter = {
        ${systems.darwin} = mkFormatter darwinUnstable;
        ${systems.droid} = mkFormatter droidUnstable;
        ${systems.linux} = mkFormatter nixosUnstable;
      };

      # NixOS実機とWSLは共通関数へ環境ごとの差だけを渡す。
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

      # Mac固有設定、macOS共通設定、Home Manager、nix-homebrewを1出力へ接続する。
      darwinConfigurations."novumdnoMac-mini" = nix-darwin.lib.darwinSystem {
        system = systems.darwin;

        specialArgs = {
          inherit username;
          unstable = darwinUnstable;
          guiPkgs = darwinUnstable;
        };

        modules = [
          # ホスト固有設定とmacOS共通のシステム設定。
          ./hosts/Mac-mini
          ./modules/darwin

          # macOS用Home ManagerとHomebrew管理をnix-darwinへ統合する。
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
