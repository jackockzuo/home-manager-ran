# ============================================================
# core.nix —— 基础层（所有配置共用）
# 职责：用户身份、Wayland 环境变量、nix 自身配置、垃圾回收
# 不包含：桌面组件、开发工具（分别由 desktop/ tools/ 提供）
# ============================================================
{ pkgs, lib, ... }:

{
  # ---------- 用户 ----------
  home.username = "ran";
  home.homeDirectory = "/home/ran";
  home.stateVersion = "24.05";

  # 允许 unfree 包（unrar 等工具需要）
  # mkDefault：Arch 单机版生效；NixOS 上由系统层 nixpkgs.config 覆盖，
  # 避免与 home-manager useGlobalPkgs 冲突（警告：useGlobalPkgs 下不应设 nixpkgs.config）
  nixpkgs.config.allowUnfree = lib.mkDefault true;

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

  # ---------- nix 配置 ----------
  nix = {
    # mkDefault：Arch 单机版满足断言；NixOS 上由 HM 的 NixOS 模块提供
    package = lib.mkDefault pkgs.nix;
    settings = {
      # 现代 Nix 命令和 Flakes 支持
      experimental-features = [ "nix-command" "flakes" ];

      # 国内镜像源（由 ~/.config/nix/nix.conf 迁移而来，交由 HM 统一管理）
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
      # trusted-public-keys 已由 /etc/nix/nix.conf（daemon 侧）管理，客户端不设避免 restricted 警告
      connect-timeout = 10;
    };
  };

  # 允许 HM 接管已存在的手写 ~/.config/nix/nix.conf（替换为生成文件）
  xdg.configFile."nix/nix.conf".force = true;

  # ===== Nix 自动垃圾回收（每周，保留 14 天回滚历史）=====
  systemd.user.services."nix-gc" = {
    Unit.Description = "Nix store garbage collection";
    Service = {
      Type = "oneshot";
      ExecStart = [
        # 清理 14 天前的 home-manager 旧代（HM 自己的 profile）
        "${pkgs.nix}/bin/nix-env --delete-generations 14d --profile %h/.local/state/nix/profiles/home-manager"
        # 清理 14 天前的 ~/.nix-profile 旧代（含 nix-env 残留的嵌套链接）
        "${pkgs.nix}/bin/nix-env --delete-generations 14d --profile %h/.nix-profile"
        # 回收 store 中不再被引用的路径
        "${pkgs.nix}/bin/nix-store --gc"
      ];
    };
  };

  systemd.user.timers."nix-gc" = {
    Unit.Description = "Weekly Nix store garbage collection";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true; # 错过执行时间则下次登录后补跑
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
