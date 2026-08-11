{ pkgs, lib, ... }:

{
  # ============================================================
  # appearance.nix —— 桌面外观（fastfetch/字体渲染/GTK 主题/光标）
  # 注意：source 相对路径基于本文件位置（modules/desktop/）
  # ============================================================

  # ---- 1. fastfetch 定制系统信息面板 ----
  # 效果：终端启动时显示彩色键名的树状信息面板（OS/KER/PAK/AGE/USR/WM/DES/SHE/TER/PC/CPU/MEM/SWP/GPU/MON/DIS）
  xdg.configFile."fastfetch/config.jsonc" = {
    source = ../../source/beautify/fastfetch/config.jsonc;
    force = true; # 覆盖原作者旧配置
  };

  # ---- 2. fontconfig 字体渲染 ----
  # 效果：全局抗锯齿 + hintslight 微调 + 中文回退（Noto Sans CJK SC）+ monospace 优先 JetBrains Mono
  xdg.configFile."fontconfig/fonts.conf" = {
    source = ../../source/beautify/fontconfig/fonts.conf;
    force = true; # 覆盖原作者旧配置
  };

  # ---- 3. GTK 全局统一主题 (Catppuccin Mocha) ----
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

  # ---- 4. 鼠标光标（Catppuccin Mocha Mauve） ----
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 24;
  };
}
