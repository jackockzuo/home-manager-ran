# ============================================================
# core.nix —— 基础层（NixOS 下由 ~/nixos-config 系统层配合）
# 职责：用户身份、nix 客户端配置
# 不包含：环境变量（→ env.nix）、桌面组件（→ desktop/）、
#         开发工具（→ tools/）、网络（→ network/）
#
# NixOS 集成说明（见 nixos-config/flake.nix）：
# - useGlobalPkgs = true：二进制由系统层管理，HM 只管配置文件
# - 系统层已管理：nixpkgs.config.allowUnfree / nix.gc
# - 本模块只保留"用户级"职责，避免与系统层重复
# ============================================================
{
  pkgs,
  lib,
  ...
}:

{
  # ---------- 用户 ----------
  home.username = "ran";
  home.homeDirectory = "/home/ran";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # ---------- nix 客户端配置（写入 ~/.config/nix/nix.conf）----------
  nix = {
    # standalone 构建需要；NixOS 集成时由系统层提供（mkDefault 允许覆盖）
    package = lib.mkDefault pkgs.nix;
    settings = {
      # 现代 Nix 命令和 Flakes 支持
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # 国内镜像源（与系统层 /etc/nix/nix.conf 一致，用户级优先）
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
      # trusted-public-keys 由系统层 daemon 侧管理，客户端不设避免 restricted 警告
      connect-timeout = 10;
    };
  };

  # 允许 HM 接管已存在的手写 ~/.config/nix/nix.conf（替换为生成文件）
  xdg.configFile."nix/nix.conf".force = true;
}
