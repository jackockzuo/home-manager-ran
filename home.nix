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
  }
  ;}
