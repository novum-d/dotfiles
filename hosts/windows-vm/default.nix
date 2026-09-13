# Windows VM固有のNixOS-WSL設定
{ username, ... }:

{
  # WSL共通モジュールへ、この仮想マシン固有の識別子とUSBポートを重ねる。
  imports = [ ../../modules/wsl ];

  wsl = {
    # Windowsとの相互運用とスタートメニュー連携を有効にする。
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    useWindowsDriver = true;
    usbip = {
      # autoAttachのBUSIDは接続先PCの物理USBポートに依存するホスト固有値。
      enable = true;
      autoAttach = [ "4-7" ];
    };
    wslConf = {
      automount.root = "/mnt";
      interop.appendWindowsPath = true;
      network.hostname = "windows-vm";
    };
  };

  # NixOSとWindows側のWSL設定で同じホスト名を使う。
  networking.hostName = "windows-vm";

  system.stateVersion = "26.05";
}
