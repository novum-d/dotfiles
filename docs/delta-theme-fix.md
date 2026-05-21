# delta のテーマが適用されない問題の対応メモ

## 症状

`programs.delta.options.features = "weeping-willow";` を設定しているにもかかわらず、`delta` に `weeping-willow` テーマが適用されない。

確認時点では、実際に有効な `delta` 設定で `syntax-theme = Monokai Extended` が表示されており、`weeping-willow` 内の `syntax-theme = Coldark-Dark` が反映されていなかった。

## 原因

`home/base/programs/git/default.nix` の `programs.git.includes` で、テーマ定義ファイルを相対パスとして指定していた。

```nix
includes = [
  { path = "./themes.gitconfig"; }
];
```

この設定は Home Manager が生成する `~/.config/git/config` にそのまま出力されるため、Git から見ると `./themes.gitconfig` は `~/.config/git/themes.gitconfig` を指す。実際のテーマ定義ファイルはリポジトリ内の `home/base/programs/git/themes.gitconfig` にあるため、`delta "weeping-willow"` セクションが読み込まれていなかった。

その結果、`delta.features = weeping-willow` は設定されていても、対応するテーマ定義が見つからず、期待したスタイルが適用されなかった。

## 修正内容

`themes.gitconfig` を Nix の path として参照し、Home Manager の生成結果では Nix store 上の絶対パスになるように変更した。

```nix
includes = [
  { path = "${./themes.gitconfig}"; }
];
```

対象ファイル:

- `home/base/programs/git/default.nix`

## 検証

以下を確認した。

```shell
nix eval .#darwinConfigurations.novumdnoMac-mini.config.home-manager.users.novumd.programs.git.includes --json
```

評価結果で、include path が次のような Nix store の絶対パスに解決されることを確認した。

```json
[
  {
    "condition": null,
    "contentSuffix": "gitconfig",
    "contents": {},
    "path": "/nix/store/...-themes.gitconfig"
  }
]
```

また、次のビルドが成功した。

```shell
nix build .#darwinConfigurations.novumdnoMac-mini.system
```

## 反映手順

修正を実環境へ反映するには、次を実行する。

```shell
sudo darwin-rebuild switch --flake .#novumdnoMac-mini
```

反映後、次のコマンドで include path とテーマ定義の読み込みを確認できる。

```shell
git config --global --show-origin --get-all include.path
git config --global --show-origin --get-regexp '^delta\.weeping-willow\.'
delta --show-config | rg 'features|syntax-theme|minus-style|plus-style'
```

`include.path` が `/nix/store/...-themes.gitconfig` を指し、`delta.weeping-willow.*` が表示されれば、テーマ定義は Git config に読み込まれている。
