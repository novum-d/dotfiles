# Lazygit設定
{ ... }:

{
  programs.lazygit = {
    enable = true;

    settings = {
      gui = {
        nerdFontsVersion = "3";
        border = "rounded";
        showFileTree = true;
        showBottomLine = false;
        showCommandLog = false;
        showRandomTip = false;
        skipStashWarning = true;
      };

      git = {
        autoFetch = true;

        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };

      update = {
        method = "never";
      };

      commitMessage = {
        customMessages = [
          "✨ feat: "
          "🐛 fix: "
          "♻️ refactor: "
          "⚡ perf: "
          "📝 docs: "
          "✅ test: "
          "🏗️ chore: "
          "🔥 remove: "
          "🚑 hotfix: "
        ];
      };
    };
  };
}