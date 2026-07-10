# Android Studio で WSL/NixOS から実機を使う手順

Windows 上の USB 接続端末を WSL/NixOS 上の Android Studio に渡すための手順。

確認時点の環境では、Windows に接続した Pixel 7 Pro を `usbipd-win` で WSL に attach し、WSL/NixOS 側の `adb` から `device` として認識できることを確認した。

## 前提

- WSL 2 の NixOS を使っている
- Android Studio は WSL/NixOS 側で起動する
- Android 実機側で開発者向けオプションと USB デバッグを有効にしている
- USB ケーブルで Windows ホストに実機を接続している

## Windows 側の準備

`usbipd-win` をインストールする。

```shell
winget.exe install --id dorssel.usbipd-win --source winget --accept-package-agreements --accept-source-agreements
```

インストール後、端末の BUSID を確認する。

```shell
"C:\Program Files\usbipd-win\usbipd.exe" list
```

例:

```text
Connected:
BUSID  VID:PID    DEVICE       STATE
4-7    18d1:4ee7  Pixel 7 Pro  Not shared
```

初回だけ管理者権限で共有設定を行う。

```powershell
Start-Process -FilePath 'C:\Program Files\usbipd-win\usbipd.exe' -ArgumentList 'bind --busid 4-7' -Verb RunAs -Wait
```

`4-7` は実際の BUSID に置き換える。USB ポートを変えると BUSID も変わることがある。

## NixOS 側の設定

`hosts/wsl-nixos/configuration.nix` に USB/IP と ADB 関連の設定を入れる。

```nix
{
  wsl = {
    enable = true;
    usbip = {
      enable = true;
      autoAttach = [ "4-7" ];
    };
  };

  programs.nix-ld.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE:="0666", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    kmod
    usbutils
    android-tools
  ];
}
```

ポイント:

- `wsl.usbip.enable` で NixOS-WSL の USB/IP 統合を有効化する
- `wsl.usbip.autoAttach` に実機の BUSID を入れる
- `kmod` は `usbipd attach` が `modprobe` を呼ぶために必要
- `usbutils` は `lsusb` などの確認用
- `android-tools` は Nix 側の `adb` を提供する
- `programs.nix-ld.enable` は Android SDK 付属の汎用 Linux バイナリを NixOS 上で動かすために必要
- `18d1` は Google/Pixel の USB vendor ID。別メーカーの場合は `usbipd list` や `udevadm info` で vendor ID を確認する

Home Manager 側では、Nix の `android-tools` を Android SDK 付属の `platform-tools` より先に置く。

```nix
{ lib, pkgs, ... }:

{
  home.sessionPath = lib.mkBefore [
    "${pkgs.android-tools}/bin"
    "$HOME/Android/Sdk/cmdline-tools/latest/bin"
    "$HOME/Android/Sdk/emulator"
    "$HOME/Android/Sdk/platform-tools"
  ];
}
```

## 反映

設定を反映する。

```shell
sudo nixos-rebuild switch --flake .#wsl-nixos
```

`dbus-broker.service` の reload で一時的に非ゼロ終了する場合がある。再度 `switch` して正常終了するか確認する。

## 接続確認

`usbipd` 側で attach 状態を確認する。

```shell
"/mnt/c/Program Files/usbipd-win/usbipd.exe" list
```

期待値:

```text
4-7    18d1:4ee7  Pixel 7 Pro  Attached
```

WSL/NixOS 側で ADB の認識を確認する。

```shell
adb devices -l
```

期待値:

```text
List of devices attached
2B081FDH300BBR device usb:1-1 product:cheetah model:Pixel_7_Pro device:cheetah
```

`unauthorized` と表示される場合は、実機側に表示される USB デバッグ許可ダイアログで許可する。

Android Studio を起動する。

```shell
android-studio
```

Device Manager または Run target に実機が表示されれば完了。

## Android Studio のバージョン更新時

Android Studio の設定ディレクトリ名が変わった場合は、`AndroidStudio2026.1.1` を新しいディレクトリ名に置き換える。

変更箇所:

- `home/nix/default.nix`
  - `STUDIO_VM_OPTIONS` のパス
  - `home.file.".config/Google/AndroidStudio2026.1.1/studio64.vmoptions"`
- `hosts/wsl-nixos/configuration.nix`
  - `androidStudioWsl` 内の `STUDIO_VM_OPTIONS` のパス

確認コマンド:

```shell
rg -n "AndroidStudio[0-9]" home/nix/default.nix hosts/wsl-nixos/configuration.nix
```

変更後は WSL/NixOS 設定を評価してから反映する。

```shell
nix eval .#nixosConfigurations.wsl-nixos.config.system.build.toplevel.drvPath
sudo nixos-rebuild switch --flake .#wsl-nixos
```

## トラブルシュート

### `adb` が `Could not start dynamically linked executable` で失敗する

Android SDK 付属の `platform-tools/adb` を NixOS が直接実行できていない。`programs.nix-ld.enable = true;` を有効化して `nixos-rebuild switch` する。

### `usbipd attach` が `modprobe command is unavailable` で失敗する

NixOS 側に `kmod` を入れる。

```nix
environment.systemPackages = with pkgs; [
  kmod
];
```

### `adb devices` が `no permissions` になる

USB デバイスノードの権限を確認する。

```shell
find /dev/bus/usb -maxdepth 3 -type c -ls
```

該当ノードが `crw-rw-rw-` になっていれば ADB から開ける。なっていない場合は、udev ルールの vendor ID と `MODE:="0666"` を確認し、実機を detach/attach し直す。

```shell
"/mnt/c/Program Files/usbipd-win/usbipd.exe" detach --busid 4-7
"/mnt/c/Program Files/usbipd-win/usbipd.exe" attach --wsl --busid 4-7
adb kill-server
adb devices -l
```

### USB ポートを変えたら接続されなくなった

BUSID が変わっている可能性がある。

```shell
"/mnt/c/Program Files/usbipd-win/usbipd.exe" list
```

新しい BUSID を `wsl.usbip.autoAttach` に反映し、`nixos-rebuild switch` する。
