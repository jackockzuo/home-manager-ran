{ pkgs, ... }:

{
  # ---- 11. QQ 原生 Wayland ----
  # 效果：QQ 以原生 Wayland 模式运行（替代 XWayland 转译）
  xdg.configFile."qq-flags.conf" = {
    force = true; # 覆盖原作者旧配置
    text = ''
    --ozone-platform=wayland
  '';
  };

}
