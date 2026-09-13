{
  # FlakeとHome Managerの双方が参照する、秘密情報を含まない共通値。
  # Codexのラッパーはpreferredを優先し、利用できない場合だけfallbackを使う。
  codexModels = {
    preferred = {
      model = "gpt-5.6-sol";
      reasoningEffort = "high";
    };
    fallback = {
      model = "gpt-5.5";
      reasoningEffort = "high";
    };
  };

  # Syncthingのfolder/device IDは秘密ではないため、Pure評価できるNix式で共有する。
  syncthing = {
    obsidianFolderId = "hrdcr-v7siz";
    pixel7proDeviceId = "NMD27JO-BIQEEZU-GWOZSKD-3ZS6RQ5-H6VPOOR-5K3XLEB-OL4WZRU-AT744QM";
  };

  # システムユーザーとHome Managerユーザーを同じ名前で接続する。
  username = "novumd";
}
