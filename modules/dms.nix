{ config, pkgs, lib, ... }:

{
  # ============================================================
  # DMS (DankMaterialShell) 配置管理
  #
  # 策略（因 DMS 运行时会写回配置，不能只读 symlink）：
  # - themes/（静态主题）→ symlink 管理，DMS 只读
  # - settings.json / monitors.json（运行时状态）→ activation 首次部署
  #   仅当目标不存在时从仓库拷贝（重装恢复场景）；
  #   运行中 DMS 自由写，home-manager 不覆盖。
  # - 日常改完 DMS 设置后，如需同步回仓库：手动 cp 更新 source/dms/
  # ============================================================

  # 静态主题目录（DMS 只读，可 symlink）
  xdg.configFile."DankMaterialShell/themes" = {
    source = ../source/dms/themes;
    recursive = true;
    force = true; # 覆盖已存在的真实目录（内容与快照一致）
  };

  # 动态配置：仅在配置缺失时部署（重装恢复），不干扰运行中的 DMS
  home.activation.restoreDmsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/DankMaterialShell"
    if [ ! -e "$HOME/.config/DankMaterialShell/settings.json" ]; then
      $DRY_RUN_CMD cp -r "${../source/dms}/." "$HOME/.config/DankMaterialShell/"
      $DRY_RUN_CMD chmod -R u+w "$HOME/.config/DankMaterialShell"
    fi
  '';
}
