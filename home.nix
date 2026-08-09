{ pkgs, ... }:

{
  # ⚠️ 替换为你的实际用户名（可以在终端输入 whoami 查看）
  home.username = "ran";
  home.homeDirectory = "/home/ran/";

  # 允许 unfree 包（unrar 等迁移工具需要）
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  programs.git = {
      enable = true;
      settings = {
        user = {
          name = "ran";
          email = "jackocksmic@outlook.com";
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
  # 导入组件模块
  imports = [
    ./modules/kitty.nix
    ./modules/shell.nix
    ./modules/niri.nix
    ./modules/fcitx5.nix
    ./modules/neovim.nix
    ./modules/beautify.nix
    ./modules/dms.nix
  ];

  # 声明全局安装的工具软件
  home.packages = with pkgs; [
    # Wayland 截图/剪贴板工具（桌面组件已移 pacman：niri/waybar/fuzzel/hyprlock/awww/swaync/hyprpolkitagent/mpvpaper）
    grim
    slurp
    wl-clipboard
    # 常用 CLI 增强工具
    fastfetch
    btop
    yazi
    lazygit
    ripgrep
    fd
    eza
    cliphist   # 历史剪贴板
    udiskie    # U盘自动挂载
    duf     # 磁盘空间直观柱状图
    dust    # 文件夹空间占用树状图

    # ===== 从 pacman 迁移的个人小工具（2026-08）=====
    # 终端增强
    fzf
    zoxide
    jq
    tree
    moreutils
    # 终端美化
    timg
    ueberzugpp
    cava
    matugen
    # Wayland/X11 辅助
    wf-recorder
    xclip
    xdotool
    ydotool
    # 下载/转换
    yt-dlp
    pandoc
    p7zip
    unrar
    imagemagick
    # 文档/代码
    typst
    tinymist
    tree-sitter
    # 杂项
    topgrade
    mcat
    dgop
  ];
  programs.direnv = {
      enable = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
  programs.tealdeer = {
       enable = true;
       settings = {
         updates = { auto_update = true; };
       };
    };
    programs.gh = {
        enable = true;
        settings = { git_protocol = "ssh"; };
      };
  # GTK 全局统一主题 (Catppuccin Mocha)
  gtk = {
    gtk4.theme = null;
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Mauve-Dark";
      package = pkgs.catppuccin-gtk.override { accents = [ "mauve" ]; variant = "mocha"; };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 24;
  };
  # 全局 Wayland 环境变量
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
    GLFW_IM_MODULE = "ibus";
    # 不依赖
    PASSWORD_STORE = "gnome-listsecret";
  };
  nix = {
    # HM 生成 nix.conf 时必须指定 Nix 包（断言要求）
    package = pkgs.nix;
    settings = {
      # 开启自动去重优化
      auto-optimise-store = true;

      # 现代 Nix 命令和 Flakes 支持
      experimental-features = [ "nix-command" "flakes" ];

      # 国内镜像源（由 ~/.config/nix/nix.conf 迁移而来，交由 HM 统一管理）
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
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
