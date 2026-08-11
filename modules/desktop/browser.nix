{ pkgs, ... }:

{
  # ---- 10. Chrome 渲染后端（修复 nvidia+wayland 闪烁/视频绿屏 + 输入卡顿）----
  # 🔴 注意：Arch 版 google-chrome-stable 启动脚本读取的是 chrome-flags.conf
  # （见 /usr/bin/google-chrome-stable: grep -v '^#' ~/.config/chrome-flags.conf），
  # 不是 google-chrome-flags.conf！之前配置在错误文件上从未生效。
  # 🔴 注意2：--use-gl=egl 不是合法值（报错 "Requested GL implementation (gl=egl-gles2)
  # not found"），Chrome 151 只接受 --use-gl=egl-angle + --use-angle=...。
  # NVIDIA Wayland 视频绿屏根因是 VA-API 硬解 + GPU 进程崩溃：
  # - 禁用 VaapiVideoDecoder（正确关闭视频硬解的 feature 名）
  # 输入卡顿修复（2026-08）：
  # - 旧组合 --use-gl=egl-angle + --use-angle=gl 在 Chrome 151 + niri 下
  #   被解析为 --use-gl=disabled → GPU 进程走 SwiftShader 软件渲染，
  #   输入事件与合成器 vblank 同步变慢 → 打字/输入卡顿。
  # - 移除强制 GL 参数，Chrome 在 Wayland + nvidia 下自动选择 EGL 硬件渲染。
  xdg.configFile."chrome-flags.conf" = {
    force = true;
    text = ''
    --ozone-platform-hint=auto
    --disable-features=VaapiVideoDecoder
  '';
  };

}
