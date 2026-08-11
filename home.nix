# ============================================================
# home.nix —— home-manager 主入口（Arch）
# 分层聚合：
#   core.nix    基础（用户/sessionVariables/nix 配置/GC）
#   desktop/    桌面环境（nix 管配置，pacman 管二进制）
#   tools/      开发工具链（nix 管）
# 个体应用（QQ/WPS/微信等）不在此配置中，由 pacman 单独安装
# ============================================================
{ pkgs, lib, ... }:

{
  imports = [
    ./modules/core.nix
    ./modules/desktop
    ./modules/tools
  ];
}
