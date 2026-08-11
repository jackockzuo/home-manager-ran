{ pkgs, ... }:

{
  # 1. 启用 Fcitx5 并加入 fcitx5-rime (中州韵) 引擎
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # niri 的 spawn-at-startup 已负责启动 fcitx5；禁用 HM 生成的 systemd 单元，避免 DBus 名冲突
      systemd.enable = false;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-rime
        rime-ice        # Rime 中州韵输入法引擎
        catppuccin-fcitx5
      ];
    };
  };

  # 2. 🔴 屏蔽 Arch 包自带的 XDG autostart（/etc/xdg/autostart/org.fcitx.Fcitx5.desktop）
  # systemd-xdg-autostart-generator 会从它生成 app-org.fcitx.Fcitx5@autostart.service，
  # 与 niri 的 spawn-at-startup "fcitx5" 同时拉起 → 抢 DBus 名 → 后启动实例失败退出
  # （journal 报 "another fcitx already running"，输入法反复失效的根因）
  # systemd.enable = false 只管 HM 自己生成的单元，管不住 Arch 包这条路径。
  # XDG 规则：用户目录 ~/.config/autostart 同名文件优先于 /etc/xdg/autostart；
  # Hidden=true 让 generator 跳过，从源头消灭重复启动。
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Fcitx 5
    Comment=Start Input Method
    Exec=/usr/bin/fcitx5
    Hidden=true
  '';



  # 3. 彻底禁用云拼音 (有了雾凇词库，完全不需要云拼音，零延迟)
  xdg.configFile."fcitx5/conf/cloudpinyin.conf".text = ''
    Enable=False
    Toggle Key=
    Minimum Pinyin Length=2
    Backend=Baidu
  '';

  # 4. 外观：Catppuccin 紫色主题 + Maple Mono 字体 + 横排候选框
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Vertical Candidate List=False
    Font="Maple Mono NF CN 11"
    MenuFont="Maple Mono NF CN 10"
    Theme=catppuccin-mocha-mauve
    DarkTheme=catppuccin-mocha-mauve
    UseDarkTheme=True
    PerScreenDPI=True
  '';

  # 5. 🔴 声明式配置 Rime 引擎：强制使用“雾凇拼音” (rime_ice) 词库方案
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      "schema_list":
        - schema: rime_ice
  '';
  # 5b. 雾凇自定义（禁用 llm_translator：脚本缺失导致 rime 报错提示）
  xdg.dataFile."fcitx5/rime/rime_ice.custom.yaml".text = ''
    patch:

      # 1. 扩充允许输入的字符集：允许在拼音中直接输入指定的标点符号，阻止其直接上屏
      "speller/alphabet": "zyxwvutsrqponmlkjihgfedcba.,?'!:<>\\/"

      # llm_translator（AI 翻译）已禁用：脚本缺失导致 rime 报错
      # "engine/translators/@before 0": lua_translator@llm_translator
      # "recognizer/patterns/llm_pinyin": "^[a-z][a-z.,?'!:<>/\\\\]*$"

      # grammar 数据库缺失（wanxiang-lts-zh-hans.gram 不存在），禁用避免报错
      # "grammar/language": wanxiang-lts-zh-hans
  '';
  # 5c. rime.lua（llm_translator 已禁用）
  xdg.dataFile."fcitx5/rime/rime.lua".text = ''
    -- llm_translator = require("llm_translator")  -- 已禁用（脚本缺失）
  '';

  # 5d. 🔴 声明式链接 rime-ice 词库组件（替代 8月9日 的手动 ln -s 与旧拷贝，重装系统自动恢复）
  # 之前 cn_dicts/en_dicts/opencc 是手动 symlink（非声明式）；lua 目录是旧拷贝，
  # 缺 uuid.lua/lunar.db/convert_ar_num_to_zh.lua → rime_ice.schema.yaml 引用
  # lua_translator@*uuid 部署失败 → 输入法失效 + journal 疯狂刷屏（lua_gears.cc）。
  xdg.dataFile."fcitx5/rime/lua" = {
    source = "${pkgs.rime-ice}/share/rime-data/lua";
    force = true; # 覆盖旧的真实拷贝目录
  };
  xdg.dataFile."fcitx5/rime/cn_dicts" = {
    source = "${pkgs.rime-ice}/share/rime-data/cn_dicts";
  };
  xdg.dataFile."fcitx5/rime/en_dicts" = {
    source = "${pkgs.rime-ice}/share/rime-data/en_dicts";
  };
  xdg.dataFile."fcitx5/rime/opencc" = {
    source = "${pkgs.rime-ice}/share/rime-data/opencc";
  };
  xdg.dataFile."fcitx5/rime/rime_ice.dict.yaml" = {
    source = "${pkgs.rime-ice}/share/rime-data/rime_ice.dict.yaml";
  };
  xdg.dataFile."fcitx5/rime/rime_ice.schema.yaml" = {
    source = "${pkgs.rime-ice}/share/rime-data/rime_ice.schema.yaml";
  };
  xdg.dataFile."fcitx5/rime/rime_ice_suggestion.yaml" = {
    source = "${pkgs.rime-ice}/share/rime-data/rime_ice_suggestion.yaml";
  };

  # 6. 默认输入法 Profile：开机默认加载美式键盘 + Rime 雾凇拼音
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=rime

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=rime
    Layout=

    [GroupOrder]
    0=Default
  '';

  # 输入法全局快捷键（从 Super+Space 改为 Ctrl+Space——Super+Space 让给启动器 (DMS Spotlight)）
  xdg.configFile."fcitx5/config" = {
    force = true; # 覆盖 fcitx5 生成的现有配置
    text = ''
[Hotkey]
# 按住切换键的修饰键时进行轮换切换
EnumerateWithTriggerKeys=True
# 向前切换输入法
EnumerateForwardKeys=
# 向后切换输入法
EnumerateBackwardKeys=
# 轮换输入法时跳过第一个输入法
EnumerateSkipFirst=False
# 触发修饰键快捷键的时限 (毫秒)
ModifierOnlyKeyTimeout=250

[Hotkey/TriggerKeys]
0=Ctrl+space
1=Shift+space
2=Zenkaku_Hankaku
3=Hangul

[Hotkey/ActivateKeys]
0=Hangul_Hanja

[Hotkey/DeactivateKeys]
0=Hangul_Romaja

[Hotkey/AltTriggerKeys]
0=Shift_L

[Hotkey/EnumerateGroupForwardKeys]
0=Ctrl+space
1=Shift+space

[Hotkey/EnumerateGroupBackwardKeys]
0=Shift+Ctrl+space

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Hotkey/PrevCandidate]
0=Shift+Tab

[Hotkey/NextCandidate]
0=Tab

[Hotkey/TogglePreedit]
0=Control+Alt+P

[Behavior]
# 默认激活：打开即中文；需要输命令时按 Ctrl+Space 切回英文
ActiveByDefault=True
# 重新聚焦时重置状态
resetStateWhenFocusIn=No
# 共享输入状态
ShareInputState=No
# 在程序中显示预编辑文本
PreeditEnabledByDefault=True
# 切换输入法时显示输入法信息
ShowInputMethodInformation=True
# 在焦点更改时显示输入法信息
showInputMethodInformationWhenFocusIn=False
# 显示紧凑的输入法信息
CompactInputMethodInformation=True
# 显示第一个输入法的信息
ShowFirstInputMethodInformation=True
# 默认页大小
DefaultPageSize=5
# 覆盖 XKB 选项
OverrideXkbOption=False
# 自定义 XKB 选项
CustomXkbOption=
# Force Enabled Addons
EnabledAddons=
# Force Disabled Addons
DisabledAddons=
# Preload input method to be used by default
PreloadInputMethod=True
# 允许在密码框中使用输入法
AllowInputMethodForPassword=False
# 输入密码时显示预编辑文本
ShowPreeditForPassword=False
# 保存用户数据的时间间隔（以分钟为单位）
AutoSavePeriod=30

'';
  };
}
