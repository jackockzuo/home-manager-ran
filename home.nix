{ pkgs, ... }:

{
  # ⚠️ 替换为你的实际用户名（可以在终端输入 whoami 查看）
  home.username = "ran"; 
  home.homeDirectory = "/home/ran/";

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # 导入组件模块
  imports = [
    ./modules/kitty.nix
    ./modules/shell.nix
    ./modules/desktop.nix
    ./modules/fuzzel.nix
    ./modules/fcitx5.nix
  ];

  # 声明全局安装的工具软件
  home.packages = with pkgs; [
    # Wayland 工具
    awww
    swaynotificationcenter
    grim
    slurp
    wl-clipboard
    hyprpolkitagent
    
    # 常用 CLI 增强工具
    fastfetch
    btop
    yazi
    lazygit
    ripgrep
    fd
    eza
  ];

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
  }
  ;}
