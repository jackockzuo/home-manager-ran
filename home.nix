# ============================================================
# home.nix —— home-manager 主入口（NixOS 用户配置）
# 由 ~/nixos-config 通过 hm-ran input 引用本文件（见 nixos-config/flake.nix）
# 分层聚合：
#   core.nix    基础（用户/sessionVariables/nix 配置）
#   desktop/    桌面环境配置（二进制由系统层安装，HM 管配置）
#   tools/      开发工具链（nix 管）
# ============================================================
{ ... }:

{
  imports = [
    ./modules/core.nix
    ./modules/desktop
    ./modules/tools
  ];

}
