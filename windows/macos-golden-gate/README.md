# Windows 11 macOS Golden Gate 風セットアップ

Windows 11 の見た目と操作感を macOS Golden Gate 風に寄せるためのローカル手順です。

このカスタマイズは Windows の GUI アプリ、Windhawk MOD、Rainmeter skin、カーソルテーマに依存するため、dotfiles では以下を管理します。

- winget で入れられるベースアプリのインストール
- 適用する MOD / skin / 設定のチェックリスト
- 再セットアップ時に迷わないためのリンク集

## 1. ベースアプリをインストール

PowerShell を通常権限で開き、dotfiles のルートから実行します。

```powershell
.\windows\macos-golden-gate\install.ps1
```

関連リンクも同時に開きたい場合:

```powershell
.\windows\macos-golden-gate\install.ps1 -OpenManualSetupLinks
```

winget import を使う場合:

```powershell
winget import --import-file .\windows\macos-golden-gate\packages.json --accept-package-agreements --accept-source-agreements
```

インストール対象:

- WinDynamicDesktop
- Windhawk
- Rainmeter
- Microsoft PowerToys

## 2. 壁紙

WinDynamicDesktop を開き、`Golden Gate abstract` を検索して適用します。

## 3. Windhawk

Windhawk を開き、以下の MOD を検索してインストールします。

- `Taskbar dock animation`
- `Mac OS minimize animation`
- `Windows 11 file explorer styler`
- `Translucent windows`
- `Resource redirect`
- `Windows 11 taskbar styler`
- `Windows 11 start menu styler`

推奨テーマ:

- `Windows 11 file explorer styler`: `liquid glass`
- `Windows 11 taskbar styler`: `liquid glass alternate`
- `Windows 11 start menu styler`: `liquid glass`

`Resource redirect` は macOS 風アイコンパックを使う前提です。配布元、ファイル名、適用した redirect 設定は環境差が出やすいため、適用後にこの README へ追記してください。

## 4. Rainmeter

Rainmeter をインストールしたら、以下の skin を導入します。

- Droptop 4: 上部メニューバー
- Monterey Rainmeter: 時計、カレンダー、天気などのウィジェット

リンク:

- <https://www.droptopfour.com/>
- <https://github.com/creewick/MontereyRainmeter>

## 5. カーソル

macOS 風カーソルとして `apple_cursor` を使います。

リンク:

- <https://github.com/ful1e5/apple_cursor>

手順:

1. GitHub Releases から Windows 用の cursor pack をダウンロードします。
2. 展開したフォルダ内の `install.inf` を右クリックします。
3. `インストール` を選択します。
4. Windows の `マウス ポインター` 設定から macOS 風カーソルを選びます。

## 6. PowerToys Command Palette

PowerToys を開き、Command Palette を有効化します。

推奨:

- 起動ショートカット: `Alt + Space`
- Windows 標準の入力切替や既存ランチャーと競合する場合は、PowerToys 側でショートカットを変更します。

## 再セットアップ用チェックリスト

- [ ] WinDynamicDesktop で `Golden Gate abstract` を適用
- [ ] Windhawk の MOD をすべてインストール
- [ ] File Explorer / Taskbar / Start Menu に `liquid glass` 系テーマを適用
- [ ] Rainmeter に Droptop 4 を導入
- [ ] Rainmeter に Monterey Rainmeter を導入
- [ ] macOS 風カーソルをインストール
- [ ] PowerToys Command Palette を `Alt + Space` で起動

## 注意

Windhawk MOD と Rainmeter skin は Windows Update や各アプリの更新で挙動が変わることがあります。更新後に表示が崩れた場合は、まず Windhawk の MOD を一時的に無効化して原因を切り分けてください。
