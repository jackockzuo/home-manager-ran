{ pkgs, ... }:

{
  # 1. 启用 Fcitx5 并加入 fcitx5-rime (中州韵) 引擎
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-rime
        rime-ice        # Rime 中州韵输入法引擎
        catppuccin-fcitx5
      ];
    };
  };



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
}
