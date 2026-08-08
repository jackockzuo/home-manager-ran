{ pkgs, ... }:

{
  # 1. 按照最新语法启用 Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons # <-- 更新为 Qt6 最新包名
        fcitx5-gtk
        catppuccin-fcitx5
      ];
    };
  };

  # 2. 彻底禁用云拼音（解决卡顿）
  xdg.configFile."fcitx5/conf/cloudpinyin.conf".text = ''
    Enable=False
    Toggle Key=
    Minimum Pinyin Length=2
    Backend=Baidu
  '';

  # 3. Catppuccin 主题 + Maple Mono 字体 + 横排候选框
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Vertical Candidate List=False
    Font="Maple Mono NF CN 11"
    MenuFont="Maple Mono NF CN 10"
    Theme=catppuccin-mocha-mauve
    DarkTheme=catppuccin-mocha-mauve
    UseDarkTheme=True
    PerScreenDPI=True
  '';

  # 4. 默认开启“美式英文键盘 + 拼音”
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=pinyin

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=pinyin
    Layout=

    [GroupOrder]
    0=Default
  '';
}
