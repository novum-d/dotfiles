# SSH設定
{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  hasSettingsOption = lib.hasAttrByPath [ "programs" "ssh" "settings" ] options;
in
{
  home.activation.generateSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ssh_dir="${config.home.homeDirectory}/.ssh"
    key_file="$ssh_dir/id_ed25519"

    if [ ! -e "$key_file" ]; then
      run mkdir -p "$ssh_dir"
      run chmod 700 "$ssh_dir"
      run ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "${config.home.username}@$(hostname)" -f "$key_file" -N ""
    fi

    run chmod 700 "$ssh_dir"
    if [ -e "$key_file" ]; then
      run chmod 600 "$key_file"
    fi
    if [ -e "$key_file.pub" ]; then
      run chmod 644 "$key_file.pub"
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  }
  // (
    if hasSettingsOption then
      {
        settings = {
          "*" = {
            AddKeysToAgent = "yes";
            HashKnownHosts = "yes";
            ServerAliveInterval = 60;
            ServerAliveCountMax = 3;
          };

          "github.com" = {
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519";
          };
        };
      }
    else
      {
        matchBlocks = {
          "*" = {
            addKeysToAgent = "yes";
            hashKnownHosts = true;
            serverAliveInterval = 60;
            serverAliveCountMax = 3;
          };

          "github.com" = {
            user = "git";
            identityFile = "~/.ssh/id_ed25519";
          };
        };
      }
  );
}
