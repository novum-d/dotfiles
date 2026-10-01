# Zed本体はHomebrewで導入し、ユーザー設定だけをHome Managerで管理する。
_: {
  programs.zed-editor = {
    enable = true;
    package = null;
    # Markdownは編集画面で開く。JetBrainsキーマップではCmd+KがGitパネルと競合する。
    userSettings.markdown_preview.open_markdown_files_in_preview = false;
    userKeymaps = [
      {
        context = "Editor && extension == md";
        bindings.cmd-shift-v = "markdown::OpenPreviewToTheSide";
      }
    ];
  };
}
