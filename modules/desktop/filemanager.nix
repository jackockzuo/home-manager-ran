{ pkgs, ... }:

{
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

}
