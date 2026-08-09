{ config, pkgs, ... }:

{
  # ============================================================
  # 桌面环境配置管理模块（niri 生态）
  # 原则：桌面组件（niri/waybar/fuzzel/hyprlock）由 pacman 全局安装，
  #       nix 只管理它们的配置文件（~/.config/ 下所有映射）
  # ============================================================

  # 1. 映射 fuzzel 整个目录
  xdg.configFile."fuzzel" = {
    source = ../source/fuzzel;
    recursive = true; # 递归链接子文件
  };

  # 2. 映射 niri 整个目录（包括 binds.kdl、layout.kdl、scripts 文件夹等）
  xdg.configFile."niri" = {
    source = ../source/niri;
    recursive = true;
    # 覆盖旧的独立 blur.kdl 真文件（现已并入 source/niri 由 home-manager 管理）
    force = true;
  };
}
