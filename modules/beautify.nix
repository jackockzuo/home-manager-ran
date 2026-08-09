{ pkgs, ... }:

{
  # ============================================================
  # 美化迁移模块（来自 minimal-niri-dotfiles，按需精简）
  # 快捷键一律不迁移；依赖原作者私有脚本的动作已跳过
  # ============================================================

  # ---- 1. fastfetch 定制系统信息面板 ----
  # 效果：终端启动时显示彩色键名的树状信息面板（OS/KER/PAK/AGE/USR/WM/DES/SHE/TER/PC/CPU/MEM/SWP/GPU/MON/DIS）
  xdg.configFile."fastfetch/config.jsonc" = {
    source = ../minimal-niri-dotfiles/.config/fastfetch/config.jsonc;
    force = true; # 覆盖原作者旧配置
  };

  # ---- 2. (已移除) foot 终端 —— 已完全切换为 kitty（见 kitty.nix / home.packages）----

  # ---- 3. fontconfig 字体渲染 ----
  # 效果：全局抗锯齿 + hintslight 微调 + 中文回退（Noto Sans CJK SC）+ monospace 优先 JetBrains Mono
  xdg.configFile."fontconfig/fonts.conf" = {
    source = ../minimal-niri-dotfiles/.config/fontconfig/fonts.conf;
    force = true; # 覆盖原作者旧配置
  };

  # ---- 4. mako 通知 ----
  # 效果：右上角、带图标、8s 超时、2px 边框、边距 10
  services.mako = {
    enable = true;
    settings = {
      border-size = 2;
      icons = 1;
      anchor = "top-right";
      default-timeout = 8000;
      margin = 10;
      padding = 10;
      font = "adwaita sans regular 11";
      history = 1;
      max-visible = 20;
      max-history = 100;
    };
  };

  # ---- 5. satty 截图标注 ----
  # 效果：默认画笔、右键直接保存到剪贴板、缩放 1.1、Noto Sans + 中文回退字体
  xdg.configFile."satty/config.toml" = {
    source = ../minimal-niri-dotfiles/.config/satty/config.toml;
    force = true; # 覆盖原作者旧配置
  };

  # ---- 6. mpv ----
  # 效果：Vulkan 渲染 + auto-safe 硬解
  xdg.configFile."mpv/config" = {
    force = true; # 覆盖原作者旧配置
    text = ''
    #使用vulkan后端
    gpu-api=vulkan
    #通用自动模式硬解
    hwdec=auto-safe
  '';
  };

  # ---- 7. Thunar 右键自定义动作（精简版）----
  # 效果：复制路径 / 在此打开终端 / 多媒体信息 / 粘贴为链接 / 粘贴剪贴板图片 / 图片转png
  # 跳过了依赖原作者私有脚本的：视频转gif、压缩视频大小、快速查看、获取所有权
  xdg.configFile."Thunar/uca.xml" = {
    force = true; # 覆盖原作者旧配置
    text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
    	<icon></icon>
    	<name>复制路径</name>
    	<submenu></submenu>
    	<unique-id>1777523758694078-1</unique-id>
    	<command>echo -n %F | wl-copy</command>
    	<description></description>
    	<range>*</range>
    	<patterns>*</patterns>
    	<directories/>
    	<audio-files/>
    	<image-files/>
    	<other-files/>
    	<text-files/>
    	<video-files/>
    </action>
    <action>
    	<icon>utilities-terminal</icon>
    	<name>Open Terminal Here</name>
    	<submenu></submenu>
    	<unique-id>1763109685799433-1</unique-id>
    	<command>kitty</command>
    	<description>Example for a custom action</description>
    	<range></range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    </action>
    <action>
    	<icon></icon>
    	<name>多媒体信息</name>
    	<submenu></submenu>
    	<unique-id>1769424941490550-1</unique-id>
    	<command>kitty --class &quot;media_info&quot; -e media-info %f </command>
    	<description></description>
    	<range>*</range>
    	<patterns>*</patterns>
    	<audio-files/>
    	<video-files/>
    </action>
    <action>
    	<icon></icon>
    	<name>粘贴为链接</name>
    	<submenu></submenu>
    	<unique-id>1769427857102992-1</unique-id>
    	<command>sh -c &apos;wl-paste -t text/uri-list | python3 -c &quot;
    import sys, os, urllib.parse
    dest_dir = sys.argv[1]
    for line in sys.stdin:
        src = urllib.parse.unquote(line.strip()).replace(&quot;file://&quot;, &quot;&quot;)
        if not src or not os.path.exists(src): continue
        filename = os.path.basename(src)
        target = os.path.join(dest_dir, filename)
        root, ext = os.path.splitext(filename)
        counter = 1
        while os.path.exists(target):
            target = os.path.join(dest_dir, f&quot;{root} ({counter}){ext}&quot;)
            counter += 1
        try: os.symlink(src, target)
        except: pass
    &quot; %f&apos;</command>
    	<description></description>
    	<range>*</range>
    	<patterns>*</patterns>
    	<directories/>
    </action>
    <action>
    	<icon></icon>
    	<name>粘贴剪贴板图片</name>
    	<submenu></submenu>
    	<unique-id>1769429285959977-2</unique-id>
    	<command>bash -c &apos;d=&quot;%f&quot;;[ -d &quot;$d&quot; ]||d=&quot;$(dirname &quot;$d&quot;)&quot;;cd &quot;$d&quot;||exit;n=&quot;img_$(date -Iseconds|cut -d+ -f1|tr T _|tr : -)&quot;;t=$(wl-paste -l);if echo &quot;$t&quot;|grep -q &quot;^image/&quot;;then wl-paste -t image/png&gt;&quot;$n.png&quot;;elif echo &quot;$t&quot;|grep -q &quot;text/uri-list&quot;;then u=$(wl-paste -t text/uri-list|head -n1);if [[ &quot;$u&quot; == file://* ]];then p=&quot;''${u#file://}&quot;;f=$(python3 -c &quot;import sys,urllib.parse;print(urllib.parse.unquote(sys.argv[1]))&quot; &quot;$p&quot;);[ -f &quot;$f&quot; ]&amp;&amp;cp &quot;$f&quot; &quot;$n.''${f##*.}&quot;;fi;fi&apos;</command>
    	<description></description>
    	<range>*</range>
    	<patterns>*</patterns>
    	<directories/>
    </action>
    <action>
    	<icon></icon>
    	<name>图片转png</name>
    	<submenu></submenu>
    	<unique-id>1769516013413116-2</unique-id>
    	<command>bash -c &apos;exec 1&gt;&gt;/tmp/img_err.log 2&gt;&amp;1; /usr/bin/notify-send &quot;图片转换&quot; &quot;正在后台处理 $# 张图片...&quot;; for f in &quot;$@&quot;; do magick -background none &quot;$f&quot; -delete 1--1 &quot;$(echo &quot;$f&quot; | sed &quot;s/\.[^.]*$//&quot;).png&quot;; done; /usr/bin/notify-send &quot;图片转换&quot; &quot;处理完成&quot;&apos; -- %F</command>
    	<description></description>
    	<range>*</range>
    	<patterns>*</patterns>
    	<image-files/>
    </action>
    </actions>
  '';
  };

  # ---- 8. 默认应用 (mimeapps) ----
  # 效果：图片→imv、视频→mpv、文本→nvim、目录→nautilus
  # 跳过了 .exe 走 shorin-proton-wrapper 的项（Arch shorin 专属）
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "video/webm" = "mpv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "application/x-shellscript" = "nvim.desktop";
      "text/plain" = "nvim.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };

  # ---- 9. xdg-desktop-portal ----
  # 效果：截屏/录屏走 gnome portal、文件选择器用 gtk（修复屏幕分享/录屏）
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gnome;gtk;
    org.freedesktop.impl.portal.Access=gtk;
    org.freedesktop.impl.portal.Notification=gtk;
    org.freedesktop.impl.portal.FileChooser=gtk;
    org.freedesktop.impl.portal.Secret=gnome-keyring;
    org.freedesktop.impl.portal.ScreenCast=gnome
    org.freedesktop.impl.portal.Screenshot=gnome
  '';

  # ---- 10. QQ 原生 Wayland ----
  # 效果：QQ 以原生 Wayland 模式运行（替代 XWayland 转译）
  xdg.configFile."qq-flags.conf" = {
    force = true; # 覆盖原作者旧配置
    text = ''
    --ozone-platform=wayland
  '';
  };

  # ---- 11. SDDM 登录界面（sddm-sugar-candy 主题，复刻 hyprlock 磨砂质感）----
  # 效果：模糊壁纸背景 + 居中时钟/日期 + 圆角输入框（与锁屏 hyprlock 风格统一）
  # 主题需 pacman 安装 sddm-sugar-candy（见 setup/pacman-packages.txt）
  xdg.dataFile."sddm/themes/sugar-candy/theme.conf.user".text = ''
    [General]
    Background="/home/ran/Pictures/Wallpapers/wallhaven-d88d53.png"
    DimBackgroundImage="0.25"
    ScaleImageCropped="true"
    ScreenWidth="1920"
    ScreenHeight="1080"

    FullBlur="true"
    PartialBlur="false"
    BlurRadius="60"

    HaveFormBackground="false"
    FormPosition="center"
    MainColor="#cdd6f4"
    AccentColor="#cba6f7"
    BackgroundColor="#11111b"
    RoundCorners="12"
    InterfaceShadowSize="5"
    InterfaceShadowOpacity="0.5"
    Font="JetBrains Maple Mono"

    ForceLastUser="true"
    ForcePasswordFocus="true"
    ForceHideVirtualKeyboardButton="true"

    HourFormat="HH:mm"
    DateFormat="dddd, d MMMM"
    HeaderText=""
  '';
}
