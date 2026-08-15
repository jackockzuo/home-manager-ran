# ============================================================
# core.nix —— 基础层（NixOS 下由 ~/nixos-config 系统层配合）
# 职责：用户身份、Wayland 环境变量、nix 客户端配置
# 不包含：桌面组件、开发工具（分别由 desktop/ tools/ 提供）
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

  # ---------- 全局 Wayland 环境变量 ----------
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";

    # --- 修复 Fcitx5 Wayland 卡顿与光标跟随 ---
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus"; # fcitx5 提供 ibus 兼容，GLFW 应用走 ibus 通道
    # 不依赖
    PASSWORD_STORE = "gnome-listsecret";
  };

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
