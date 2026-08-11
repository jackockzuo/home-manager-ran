# ran 的 Dotfiles —— Arch 桌面环境一键搭建

> **哲学**：nix 管理配置和工具链，pacman 管理桌面二进制（GPU 相关避免 nix 的 GUI 兼容问题）。
> **目标**：从 archlinux.iso 一条命令装出完整 niri 桌面环境。

## 目录结构（每个 nix 相互独立，按关注点分层）

```
home-manager/
├── flake.nix              # 入口：. #ran（完整）/ .#ran-desktop（纯净桌面）
├── home.nix               # Arch 主入口（纯聚合，不写配置）
├── modules/
│   ├── core.nix           # 基础层：用户/环境变量/nix 配置/GC
│   ├── desktop/           # 桌面层：nix 管配置，pacman 管二进制
│   │   ├── default.nix    #   聚合 + 桌面必需 CLI 工具
│   │   ├── niri.nix       #   合成器（source/niri 全套配置）
│   │   ├── kitty.nix      #   终端
│   │   ├── fcitx5.nix     #   输入法（fcitx5 + rime 雾凇）
│   │   ├── dms.nix        #   桌面壳 DankMaterialShell
│   │   ├── swaync.nix     #   通知（毛玻璃）
│   │   ├── appearance.nix #   外观：fastfetch/字体/GTK 主题/光标
│   │   ├── screenshot.nix #   截图标注（satty）
│   │   ├── mpv.nix        #   视频播放
│   │   ├── filemanager.nix #  文件管理（Thunar + mimeapps）
│   │   ├── portal.nix     #   xdg-desktop-portal
│   │   └── browser.nix    #   Chrome 渲染 flags
│   └── tools/             # 工具链层：nix 管理（与发行版解耦）
│       ├── default.nix    #   聚合 + 开发工具包
│       ├── shell.nix      #   fish + starship + zoxide/fzf/bat
│       ├── neovim.nix     #   编辑器（含 fcitx5 状态联动）
│       ├── wine.nix       #   Wine 管理（可选导入）
│       └── qq.nix         #   QQ Wayland flags（可选导入）
├── source/                # 配置源文件（niri 全套/fastfetch/DMS）
└── setup/
    ├── install.sh         # ★ 从 archiso 一键安装（分区→系统→桌面→配置）
    ├── desktop-packages.txt # 桌面二进制 pacman 清单（GPU 相关）
    ├── restore.sh         # 已装好系统的恢复（含 nix + 全部应用）
    └── pacman-packages.txt # 完整 pacman 包清单（含个体应用）
```

## 快速安装（从 archlinux.iso）

```bash
# 1. archiso 启动后（root 终端）：
curl -sSL https://raw.githubusercontent.com/jackockzuo/home-manager-ran/main/setup/install.sh | bash

# 2. 按提示选磁盘/设密码 → 自动完成：
#    分区(GPT+EFI+btrfs) → pacstrap(基础+桌面二进制) → GRUB
#    → nix + home-manager → 生成全部桌面配置
# 3. reboot 进入 DMS greeter → niri 桌面
```

环境变量（免交互/自动化）：
```bash
DISK=/dev/nvme0n1 HOSTNAME=myarch USERNAME=ran PASSWORD=xxx bash setup/install.sh
```

## 日常使用

```bash
# 更新配置（拉最新 + 应用）
cd ~/dotfiles && git pull && home-manager switch --flake .#ran

# 只想要桌面环境（无开发工具链）
home-manager switch --flake .#ran-desktop

# 装个体应用（QQ/WPS/微信等，不在本仓库范围）
sudo pacman -S <包名>
```

## 分层哲学

| 层 | 管理工具 | 内容 | 原因 |
|---|---|---|---|
| 桌面二进制 | **pacman** | niri/fcitx5/kitty/pipewire/字体 | GPU 相关，pacman 与驱动/系统集成最稳 |
| 桌面配置 | **nix** | ~/.config 全部（niri/kitty/fcitx5/swaync...） | 声明式、可复现、版本管理 |
| 工具链 | **nix** | CLI/编辑器/LSP/开发工具 | 与发行版解耦，跨机一致 |
| 个体应用 | **pacman** | QQ/WPS/微信/anki 等 | 无需声明式管理 |

## 常见坑

| 问题 | 解决 |
|---|---|
| fcitx5 反复失效 | `modules/desktop/fcitx5.nix` 已屏蔽 XDG autostart 冲突 |
| Chrome 输入卡顿 | `desktop/browser.nix` 已修复（移除强制 GL，走 NVIDIA 硬件渲染） |
| swaync 无毛玻璃 | 需 AUR 包 `swaync-git`（pacman 版 0.12.6 无 background-blur） |
| 字体发虚 | `desktop/appearance.nix` 的 fontconfig 配置已接管 |
