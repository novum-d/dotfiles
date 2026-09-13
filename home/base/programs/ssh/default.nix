# SSH設定
{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  # Home Managerのversion差に応じて、新旧どちらのSSH設定APIを使うか判定する。
  hasSettingsOption = lib.hasAttrByPath [ "programs" "ssh" "settings" ] options;
in
{
  # 初回activationで鍵がなければ生成し、既存鍵も含めて権限を毎回補正する。
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
    # 新しいHome Managerではsettings、古いversionではmatchBlocksへ同じ内容を設定する。
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
