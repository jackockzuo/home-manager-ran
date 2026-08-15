# ============================================================
# tools/default.nix —— 开发工具链聚合（nix 管理）
# 原则：工具链由 nix 管理（与发行版解耦）；个体应用不在此列
# 每个子模块独立关注点，可按需增删
# 新增 → 新建 <关注点>.nix 并在此加一行；预留 → 取消注释
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./shell.nix # fish + starship + zoxide/fzf/bat
    ./neovim.nix # 编辑器（含 fcitx5 状态联动）
    ./social.nix # 社交（QQ 原生 Wayland 等）
    ./opencode.nix # AI 编码助手（opencode CLI）
    # ./wine.nix     # Wine 程序管理（需要时取消注释）

    # ---- 🔮 预留模块（需要时取消注释）----
    # ./dev.nix # 开发语言/数据库客户端
    # ./ai.nix # 本地 AI（Ollama/LM Studio）
    # ./office.nix # 办公效率（Obsidian/PDF 工具）
  ];

  # 开发工具链（nix 管理）
  home.packages = with pkgs; [
    # CLI 增强
    btop # 系统监控
    yazi # 终端文件管理器
    lazygit # git TUI
    ripgrep # 搜索
    fd # 查找
    duf # 磁盘空间
    dust # 空间树状图
    # 终端增强
    jq # JSON 处理
    tree # 目录树
    moreutils # 额外工具
    # 终端美化
    timg # 终端图片
    ueberzugpp # 终端图片后端
    cava # 音频可视化
    matugen # 主题生成
    # 下载/转换
    yt-dlp # 视频下载
    pandoc # 文档转换
    p7zip # 压缩
    unrar # 解压
    imagemagick # 图片处理
    # 文档/代码
    typst # 排版
    tinymist # typst LSP
    tree-sitter # 语法树
    # GUI
    neovide # neovim GUI（轻量优雅，继承 nvim 配置与主题）
    # 杂项
    topgrade # 一键升级
    mcat
    dgop
  ];

  # 开发者工具配置
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
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
    };
  };
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
