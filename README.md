# ran 的 Dotfiles —— Arch 桌面环境一键搭建

一个仓库，两个小项目：

| 小项目 | 内容 | 用途 |
|---|---|---|
| **home-manager** | `flake.nix` + `modules/` + `source/` | 声明式管理个人配置（niri/kitty/fcitx5 等全部 `~/.config`） |
| **install** | `setup/install.sh` + `setup/desktop-packages.txt` | 从 archlinux.iso 一键装出完整 niri 桌面 |

> **哲学**：nix 管配置和工具链（与发行版解耦），pacman 管桌面二进制（GPU 相关避免 nix 的 GUI 兼容问题）。

---

## 一、目录结构

```
home-manager/
├── flake.nix                  # 入口：.#ran（完整）/ .#ran-desktop（纯净桌面）
├── flake.lock                 # 锁定 nixpkgs/home-manager 版本
├── home.nix                   # Arch 主入口（纯聚合，不写配置）
├── README.md                  # 本文档
├── modules/
│   ├── core.nix               # 基础层：用户/环境变量/nix 配置/GC
│   ├── desktop/               # 桌面层：nix 管配置，pacman 管二进制
│   │   ├── default.nix        #   聚合入口 + 桌面必需 CLI 工具
│   │   ├── niri.nix           #   合成器（映射 source/niri 全套）
│   │   ├── kitty.nix          #   终端
│   │   ├── fcitx5.nix         #   输入法（fcitx5 + rime 雾凇）
│   │   ├── dms.nix            #   桌面壳 DankMaterialShell
│   │   ├── swaync.nix         #   通知（毛玻璃）
│   │   ├── appearance.nix     #   外观：fastfetch/字体渲染/GTK 主题/光标
│   │   ├── screenshot.nix     #   截图标注（satty）
│   │   ├── mpv.nix            #   视频播放
│   │   ├── filemanager.nix    #   文件管理（Thunar + mimeapps）
│   │   ├── portal.nix         #   xdg-desktop-portal
│   │   └── browser.nix        #   Chrome 渲染 flags
│   └── tools/                 # 工具链层：nix 管理
│       ├── default.nix        #   聚合入口 + 开发工具包
│       ├── shell.nix          #   fish + starship + zoxide/fzf/bat
│       ├── neovim.nix         #   编辑器（含 fcitx5 状态联动）
│       ├── wine.nix           #   Wine 管理（可选导入）
│       └── qq.nix             #   QQ Wayland flags（可选导入）
├── source/                    # 配置源文件（不被 nix 计算，直接映射）
│   ├── niri/                  #   niri 全套：config/binds/layout/rule/output/blur/animations + 6 脚本
│   ├── dms/                   #   DMS 主题 + 运行时配置快照
│   └── beautify/              #   fastfetch / fontconfig / satty 源文件
└── setup/
    ├── install.sh             # ★ 从 archiso 一键安装（核心）
    └── desktop-packages.txt   # 45 个桌面二进制 pacman 清单
```

### 分层哲学

| 层 | 管理工具 | 内容 | 原因 |
|---|---|---|---|
| 桌面二进制 | **pacman** | niri/fcitx5/kitty/pipewire/字体 | GPU 相关，pacman 与驱动/系统集成最稳 |
| 桌面配置 | **nix** | `~/.config` 全部（niri/kitty/fcitx5/swaync...） | 声明式、可复现、版本管理 |
| 工具链 | **nix** | CLI/编辑器/LSP/开发工具 | 与发行版解耦，跨机一致 |
| 个体应用 | **pacman**（手动） | QQ/WPS/微信/anki 等 | 无需声明式管理 |

---

## 二、前置准备（只做一次）

### 2.1 仓库可见性

install.sh 靠 HTTPS 匿名从 GitHub 下载，**仓库必须是 public**：

> GitHub → `jackockzuo/home-manager-ran` → **Settings** → **Danger Zone** → **Change visibility** → **Make public**

### 2.2 下载 Arch ISO

```bash
# 国内镜像（清华）：
curl -L -o ~/Downloads/archlinux-x86_64.iso \
  https://mirrors.tuna.tsinghua.edu.cn/archlinux/iso/latest/archlinux-x86_64.iso
```

### 2.3 写入 U 盘

```bash
# ⚠️ 确认 /dev/sdX 是 U 盘（lsblk 查看）
sudo dd if=~/Downloads/archlinux-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### 2.4 确认机器是 UEFI

```bash
[ -d /sys/firmware/efi ] && echo "UEFI ✓" || echo "BIOS（不支持，需 Legacy 引导）"
```

---

## 三、全新安装（核心流程）

### 3.1 启动 archiso

U 盘启动 → 选择 "Arch Linux install medium (x86_64, UEFI)" → 等待进入 root shell。

### 3.2 一条命令

```bash
curl -sSL https://raw.githubusercontent.com/jackockzuo/home-manager-ran/main/setup/install.sh | bash
```

脚本会交互询问：
1. **目标磁盘**（显示 `lsblk` 列表，输入如 `/dev/nvme0n1`，会格式化整盘！）
2. **确认**（输入 `yes`）
3. **用户密码**

### 3.3 脚本自动完成（9 步）

| 步骤 | 操作 | 说明 |
|---|---|---|
| 1 | 环境检测 | 确认 root + UEFI + /mnt 未挂载 |
| 2 | 选择磁盘 | 交互或 `DISK=` 环境变量 |
| 3 | 分区 | GPT：`p1` EFI 1G（FAT32）+ `p2` btrfs（剩余全部） |
| 4 | 子卷 | btrfs 创建 `@`（根）`@home`（家目录） |
| 5 | pacstrap | 基础包 + 45 个桌面二进制（niri/fcitx5/kitty/pipewire...） |
| 6 | fstab | 按 UUID 生成挂载表 |
| 7 | chroot 配置 | 时区/locale/hostname/用户/GRUB/服务 |
| 8 | nix + home-manager | 装 nix → clone 仓库 → `home-manager switch` 生成全部桌面配置 |
| 9 | 收尾 | 卸载 /mnt，提示 reboot |

### 3.4 免交互（自动化/CI 用）

```bash
DISK=/dev/nvme0n1 \
HOSTNAME=myarch \
USERNAME=ran \
PASSWORD=yourpass \
bash setup/install.sh
```

### 3.5 安装后

```bash
reboot
```

进入 **DMS greeter** 登录界面 → 输入密码 → **niri** 桌面。

验证清单：

| 检查项 | 命令 |
|---|---|
| 桌面会话 | `echo $XDG_CURRENT_DESKTOP` → 应为 Niri |
| 终端 | `Mod+T` 打开 kitty |
| 输入法 | `fcitx5-remote -t`，Ctrl+Space 切换 rime |
| 声音 | `wpctl status` |
| 网络 | `nmcli device` |
| 蓝牙 | `bluetoothctl` |
| 系统信息 | 终端启动自动显示 fastfetch |

### 3.6 验证记录（2026-08 VM 实测）

install.sh 全流程已在 QEMU VM（archiso 引导）实测通过：

| 步骤 | 结果 |
|---|---|
| 环境检测 / 分区（GPT+EFI+btrfs）/ 格式化 / 挂载 | ✅ |
| pacstrap 基础+桌面包 / fstab 生成 / chroot 配置 | ✅ |
| 用户创建（ran + fish + sudoers） | ✅ |
| GRUB 安装（grubx64.efi + grub.cfg + 内核） | ✅ |

**过程中发现并修复 2 个 bug**：
1. `useradd -G networkmanager` → 改为 `network`（Arch 实际 group 名，原值会导致用户创建失败）
2. BASE_PKGS 补上 `grub efibootmgr`（原清单缺引导工具，grub-install 会失败）

> 注：VM 内 OVMF 固件无持久 NVRAM 导致 grub-install 的 efibootmgr 写入警告，属 QEMU 环境限制，真机无此问题。

---

## 四、日常使用

### 4.1 更新配置

```bash
cd ~/dotfiles && git pull && home-manager switch --flake .#ran
```

### 4.2 只想桌面环境（无开发工具链）

```bash
home-manager switch --flake .#ran-desktop
```

### 4.3 安装个体应用（QQ/WPS/微信等）

```bash
sudo pacman -S <包名>   # 不在本仓库范围内，按需装
```

### 4.4 已装好系统的恢复（跳过系统安装）

```bash
# 1. 装 nix（若没有）
curl -L https://nixos.org/nix/install | sh

# 2. 拉仓库 + 应用
git clone https://github.com/jackockzuo/home-manager-ran.git ~/dotfiles
cd ~/dotfiles && nix run github:nix-community/home-manager -- switch --flake ~/dotfiles#ran
```

---

## 五、常见问题

| 问题 | 原因 | 解决 |
|---|---|---|
| `curl: command not found` | archiso 基础环境缺 curl | `pacman -Sy curl` |
| install.sh 404 | 仓库不是 public | 见 2.1 |
| 安装卡在 pacstrap | 网络慢/镜像源问题 | 脚本已配清华镜像；可 `USE_MIRROR=0` 跳过 |
| fcitx5 反复失效 | XDG autostart 与 niri spawn 冲突 | `modules/desktop/fcitx5.nix` 已屏蔽 |
| Chrome 输入卡顿 | 强制 GL 参数导致软件渲染 | `desktop/browser.nix` 已修复 |
| swaync 无毛玻璃 | pacman 版无 background-blur | 需 AUR 包 `swaync-git`（清单已含） |
| 字体发虚 | 无 fontconfig 接管 | `desktop/appearance.nix` 已配置 |
| niri 登录不了 | DMS greeter 会话配置 | `dms greeter install` 修复 |
| 磁盘分区选错 | 无 | ⚠️ 安装前务必确认目标磁盘 |

---

## 六、开发/维护指南

### 6.1 新增桌面配置

1. 在 `modules/desktop/` 新建 `<name>.nix`（单一关注点）
2. 在 `modules/desktop/default.nix` 的 `imports` 加入
3. `home-manager switch --flake .#ran` 应用
4. 验证后提交推送

### 6.2 新增工具链包

编辑 `modules/tools/default.nix` 的 `home.packages`。

### 6.3 修改源文件（niri 配置等）

直接改 `source/niri/*.kdl`，`home-manager switch` 自动同步（recursive 映射）。

### 6.4 验证配置

```bash
cd ~/dotfiles
nix flake check          # 语法 + 模块校验
home-manager switch --flake .#ran   # 应用
```

---

## 七、未来方向

- **生成可复用镜像**：install.sh 装好的系统可清理后打包成自定义 ISO（需调研 mkarchiso）
- **双盘支持**：当前脚本整盘格式化，可扩展多盘/双系统场景

---

## 八、滚挂防护（免插 U 盘）

三层防御体系（snapper 快照回滚 + 本地 archiso 引导）：

### 第一层：日常滚挂 → GRUB 快照回滚
- **snapper**（已配置 root+home）+ **grub-btrfs**（已启用）
- **snap-pac**（AUR）：`pacman -Syu` 前自动快照
- 滚挂后：重启 → GRUB 菜单选 `@.snapshots/N/snapshot` → 直接回滚

### 第二层：启动不了 → 本地 archiso
- archiso 存 `/archiso/`（独立 btrfs 子卷 @archiso，不受 @ 快照影响）
- GRUB 菜单项 "Arch Linux ISO (本地恢复)" 直接从本地进 live 环境
- 进 live 后 chroot 修复 或 跑本仓库 install.sh

### 第三层：彻底损坏 → U 盘（最后手段）

### 配置脚本（setup/）
```bash
# 一键配置（推荐，需 root 运行一次，自动完成全部 4 步）
sudo bash setup/guard.sh

# 或手动分步执行：
# sudo bash setup/snapper-fix.sh     # 修 snapper 防误删 + 建 archiso 子卷
# sudo bash setup/snap-pac.sh        # 装 snap-pac + 移除 timeshift
# sudo cp archlinux-x86_64.iso /archiso/   # 下载 ISO
# sudo bash setup/grub-archiso.sh    # 配置 GRUB 菜单
```
