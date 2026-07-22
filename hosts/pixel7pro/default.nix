{
  pkgs,
  unstable,
  herdr,
  ...
}:

{
  environment = {
    etcBackupExtension = ".bak";

    packages = with pkgs; [
      coreutils
      diffutils
      findutils
      gnugrep
      gnused
      gnutar
      gzip
      hostname
      less
      procps
      tzdata
      unzip
      zip
    ];
  };

  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Tokyo";
  user.shell = "${pkgs.zsh}/bin/zsh";

  home-manager = {
    config = ../../home/android;
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    extraSpecialArgs = {
      inherit unstable herdr;
      guiPkgs = unstable;
      isNixOnDroid = true;
    };
  };

  # This is Nix-on-Droid's compatibility version, not the nixpkgs release.
  system.stateVersion = "24.05";
}
