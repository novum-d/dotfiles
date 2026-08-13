{ username, ... }:

{
  imports = [ ../../modules/wsl ];

  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    useWindowsDriver = true;
    usbip = {
      enable = true;
      autoAttach = [ "4-7" ];
    };
    wslConf = {
      automount.root = "/mnt";
      interop.appendWindowsPath = true;
      network.hostname = "windows-vm";
    };
  };

  networking.hostName = "windows-vm";

  system.stateVersion = "26.05";
}
