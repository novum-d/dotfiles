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

`hosts/windows-vm/default.nix` に VM 固有の USB/IP 設定、`modules/wsl/default.nix` に共有する ADB・Android Studio 設定を入れる。

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
Cordova が Gradle Wrapper を生成できるよう、WSL では Nix の `gradle` も PATH に追加する。

```nix
{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.gradle_9 ];

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
sudo nixos-rebuild switch --flake .#windows-vm
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
studio .
```

起動コマンドは端末から切り離されるため、Android Studio の起動後も同じシェルをそのまま操作できる。
起動ごとの出力は `${XDG_STATE_HOME:-$HOME/.local/state}/android-studio/launcher.*.log` に保存し、端末に保存先を表示する。直近の起動ログは同じディレクトリの `launcher.log` から参照できる。

WSLではIDEの初期ヒープを512 MiB、最大ヒープを4096 MiBとし、Javaのメモリ不足時にはヒープダンプを有効にする。設定の正本は `lib/android-studio.nix` にあり、Home Managerが `~/.config/dotfiles/android-studio/studio64.vmoptions` に配置する。ランチャーが `STUDIO_VM_OPTIONS` でこのファイルを指定するため、IDEのバージョン更新にも追従する。GradleやKotlin daemon、エミュレーターのヒープ設定は別途プロジェクト側で管理する。

IME は右 Shift の単独押し、`Ctrl+Space`、または日本語キーボードの半角/全角キーで英数入力とMozcを切り替える。右 Shift をほかのキーと組み合わせた場合は、通常のShift修飾キーとして動作する。Windows側のキー処理などで右 Shift が届かない場合は `Ctrl+Space` を使う。

WSL構成ではfcitx5をsystemdユーザーサービスとして常駐させ、Android StudioとObsidianの起動時にもサービスのD-Bus登録完了を待つ。どちらもWSLgのX11経由でfcitx5を使い、ObsidianにはGTK入力モジュールの検索パスも明示する。動作状態は次で確認できる。

```shell
systemctl --user status fcitx5-wsl.service
fcitx5-remote
```

`fcitx5-remote` は `1` なら英数入力、`2` なら入力メソッドが有効な状態を表す。`0` は入力欄にフォーカスがない場合にも返るため、サービス停止とは限らない。キー操作を使わずに切り替える場合は `fcitx5-remote -t` を実行する。

WSLのAndroid Studioでは `-Drecreate.x11.input.method=true` を指定せず、付属JetBrains RuntimeのXIM処理を使う。このオプションを明示しない設定は、[JetBrainsのXIM修正の案内](https://youtrack.jetbrains.com/issue/JBR-2460)に沿っている。

Device Manager または Run target に実機が表示されれば完了。

## Android Studio のバージョン更新時

WSLのVMオプションはバージョンに依存しないパスから読み込むため、更新時のディレクトリ名変更は不要。通常のNixOSでは、Android Studio の設定ディレクトリ名が変わった場合に `AndroidStudio2026.1.1` を新しいディレクトリ名に置き換える。

変更箇所:

- `lib/android-studio.nix`
  - `vmOptionsConfigPath`

確認コマンド:

```shell
rg -n "AndroidStudio[0-9]" lib/android-studio.nix docs/android-studio-wsl-device.md
```

変更後は WSL/NixOS 設定を評価してから反映する。

```shell
nix eval .#nixosConfigurations.windows-vm.config.system.build.toplevel.drvPath
sudo nixos-rebuild switch --flake .#windows-vm
```

## トラブルシュート

### `studio .` がすぐ戻り、画面もエラーも出ない

通常起動では端末から切り離すため、コマンドがすぐ戻っても起動成功とは限らない。以前のランチャーは標準出力・標準エラーを `/dev/null` へ捨てていたため、fcitx5、D-Bus、JVM、IDEロックのエラーも表示されなかった。

まずログを確認する。既に起動済みのIDEに引数を渡しただけの場合、そのIDEの出力は最初の起動時のログに残る。

```shell
tail -n 100 "${XDG_STATE_HOME:-$HOME/.local/state}/android-studio/launcher.log"
```

エラーと終了コードを端末で直接確認する場合は、次を使う。この起動では端末がIDEの終了を待つ。

```shell
studio --foreground .
```

`VM options not found` ならHome Managerの設定が未反映か、`XDG_CONFIG_HOME` が配置先と異なる。上記の「反映」を実行し、設定ファイルの配置先と起動時のパスを一致させる。

`CannotActivateException`、`still running and does not respond` なら、画面が消えてもIDEプロセスが残っている可能性がある。[JetBrainsの復旧手順](https://youtrack.jetbrains.com/projects/WI/articles/SUPPORT-A-4102/IDE-fails-to-start-DirectoryLock-CannotActivateException-with-suppressed-BindException)に従い、次で対象を確認する。

```shell
pgrep -af '[a]ndroid-studio|[A]ndroidStudio'
```

エラーに出たPIDがAndroid Studio本体であることを確認して `kill -TERM <PID>` で終了させる。終了しない場合だけ `kill -KILL <PID>` を使う（未保存の編集は失われる）。その後 `studio .` で再起動する。

全IDEプロセスの終了後もロックのエラーが続く場合だけ、エラーに表示された設定ディレクトリの `.lock` と、存在すれば `port`、`token` を削除して再起動する。動作中のIDEのロックや設定・キャッシュディレクトリ全体は削除しない。ランチャーはプロセス終了やロック削除を自動実行しない。

### Android Studio が使用中に落ちる

IDEログ（通常は `~/.cache/Google/AndroidStudio*/log/idea.log`）、起動ログ、カーネルログを合わせて確認する。

```shell
free -h
journalctl -k -b --no-pager | grep -Ei 'oom|out of memory|killed process' | tail -20
```

`java.lang.OutOfMemoryError: Java heap space` はIDEのJavaヒープ不足を示す。一方、カーネルの `Killed process` はWSL全体のメモリ不足による強制終了の可能性があり、IDEのヒープだけを増やすと悪化し得る。[Android公式のメモリ設定](https://developer.android.com/studio/intro/studio-config#adjusting_heap_size)も踏まえ、WSLに割り当てたメモリとGradleなどの同時使用量を確認する。WSL全体の上限を変える場合は、Windows側の [.wslconfig](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#main-wsl-settings) で管理する。

### `studio .` が `Unable to detect graphics environment` で失敗する

Herdr などの常駐プロセスから起動したシェルに `DISPLAY` が引き継がれていない可能性がある。WSLg の X11 ソケットを確認する。

```shell
test -S /tmp/.X11-unix/X0
```

この構成の `studio` ランチャーは、ソケットが存在して `DISPLAY` が未設定の場合に `DISPLAY=:0` を補完する。

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
