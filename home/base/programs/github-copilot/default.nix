# GitHub Copilot CLIの共通設定
{ unstable, ... }:

{
  # 更新の速いCopilot CLIはunstableから取得する。
  home.packages = with unstable; [
    github-copilot-cli
  ];

  # CLIが使用する既定モデルを全環境でそろえる。
  home.sessionVariables = {
    COPILOT_MODEL = "gpt-5.5";
  };
}
