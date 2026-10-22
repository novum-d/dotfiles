# eMudhra中間CAの秘密鍵漏洩への対応

2026年10月に公表された[eMudhra中間CAの秘密鍵漏洩](https://emudhra.we-have-a-problem.com/)に対し、このリポジトリではNixで管理するシステムCA bundleで次のルートの信頼を解除します。

- `Comodo AAA Services root`（証明書のCNは `AAA Certificate Services`）
- `emSign ECC Root CA - G3`

対象名は [`lib/ca-certificate-blacklist.nix`](../lib/ca-certificate-blacklist.nix) で共有します。macOSはnix-darwinの `security.pki.caCertificateBlacklist`、NixOSとWSLはNixOSの同名optionを使います。このoptionがないNix-on-Droidは、除外済みの `cacert` をシステムの3つのCA bundleパスへ接続し、NixとOpenSSL向けの環境変数を設定します。Nix-on-Droidの固定入力は更新しません。

ルート全体の信頼解除なので、漏洩した中間CA以外でも、これらのルートだけに依存する接続が失敗することがあります。失敗時に証明書検証を無効にせず、接続先の証明書チェーンを確認してください。

## 設定の反映

各端末で通常の設定適用を実行し、ターミナルを開き直してください。

```shell
# macOS
sudo darwin-rebuild switch --flake .#novumdnoMac-mini

# NixOS
sudo nixos-rebuild switch --flake .#nixos

# WSL（Linux側）
sudo nixos-rebuild switch --flake .#windows-vm

# Nix-on-Droid
nix-on-droid switch --flake .#pixel7pro
```

## macOS標準のCA bundle

nix-darwinの設定が更新するのは `/etc/ssl/certs/ca-certificates.crt` です。macOS標準の `/etc/ssl/cert.pem` は別ファイルで、標準のcurl、Git、Pythonなどに影響します。macOSとブラウザの更新に加え、[公開されたmacOS向け手順](https://emudhra.we-have-a-problem.com/#macos-curl)に沿って、このファイルと標準pipの対応も行ってください。nix-darwinの適用だけで標準bundleやKeychain、Determinate Nix daemonの証明書参照先が更新されるとは限りません。

## 独自の証明書ストアを持つツール

システムCA bundleの変更は、独自の証明書ストアやルートを組み込んだすべてのプログラムへは適用されません。Node.jsはこの構成で `26.10.0` に固定していたため、[中間CAのブロックを含む `26.12.1`](https://github.com/nodejs/node/releases/tag/v26.12.1) に更新しています。Home Manager適用後に `mise install node` を実行し、`node --version` を確認してください。プロジェクト内で別バージョンを指定している場合は、そちらの更新も必要です。

Java、Pythonのcertifi、pip、uv、Rust製CLI、Go製CLI、Electronアプリなどは、[事案の対応済みバージョン一覧](https://emudhra.we-have-a-problem.com/#developers)を参照して個別に更新してください。既存の仮想環境、コンテナ、プロジェクトの固定ランタイム、Windows側、Android OS側もそれぞれの更新が必要です。

## 確認

設定適用後に、まず通常のHTTPS通信が成功することを確認します。

```shell
curl --fail --head https://cache.nixos.org/
```

続いて、公開された検証用ホストへの接続が証明書エラーで失敗することを確認します。DNS失敗やタイムアウトは対策成功の証拠にはなりません。

```shell
curl --noproxy '*' --cacert /etc/ssl/certs/ca-certificates.crt \
  https://dv-g3b-emudhra.we-have-a-problem.com/
curl --noproxy '*' --cacert /etc/ssl/certs/ca-certificates.crt \
  https://dv-g3b-aaa-emudhra.we-have-a-problem.com/
```

実際に使うクライアントについては、`--cacert` を省略した場合も確認してください。macOS標準のcurlは `/usr/bin/curl` を明示して確認します。ブラウザは[公開チェッカー](https://emudhra.we-have-a-problem.com/#check)で確認できます。
