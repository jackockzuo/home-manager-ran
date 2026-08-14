# NixOS 实机安装指南（迁移自 Arch）

> 目标：nvme1n1 整盘装 NixOS（保留 nvme0n1 Windows 不动）
> 配置：flake `.#laptop`（已构建验证，含联网工具+桌面+滚挂防护）
> 前置：U 盘
> 迁移资产：dotfiles 仓库（已在 GitHub，含全部 nix 配置，无需额外备份）

## 1. 制作 NixOS 安装 U 盘

```bash
# 下载 NixOS ISO（国内镜像优先，上海时区建议用清华加速；国外用官方渠道）
# 方式 A：清华镜像（国内快，已验证可用）
curl -L -o ~/Downloads/nixos.iso \
  https://mirrors.tuna.tsinghua.edu.cn/nixos-images/nixos-25.05/latest-nixos-graphical-x86_64-linux.iso
# 方式 B：官方渠道（自动重定向最新版，国内可能慢）
# curl -L -o ~/Downloads/nixos.iso \
#   https://channels.nixos.org/nixos-25.05/latest-nixos-gnome-x86_64-linux.iso
# 写入 U 盘（确认 /dev/sdX 是 U 盘！）
sudo dd if=~/Downloads/nixos.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## 2. 启动 NixOS 安装环境

U 盘启动 → 选择 "NixOS" 引导项 → 进入安装环境（有终端）。

## 3. 分区 nvme1n1（GPT + EFI + btrfs）

```bash
# ⚠️ 确认目标盘！nvme1n1 是 Arch 盘（将被清空）
lsblk
parted -s /dev/nvme1n1 mklabel gpt
parted -s /dev/nvme1n1 mkpart ESP fat32 1MiB 1GiB
parted -s /dev/nvme1n1 set 1 esp on
parted -s /dev/nvme1n1 mkpart primary btrfs 1GiB 100%

# 格式化
mkfs.fat -F32 /dev/nvme1n1p1
mkfs.btrfs -f /dev/nvme1n1p2

# 创建子卷（与配置匹配：@ 根 / @home / @archiso）
mount /dev/nvme1n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@archiso
umount /mnt

# 挂载
mount -o subvol=@,compress=zstd:3,ssd /dev/nvme1n1p2 /mnt
mkdir -p /mnt/home /mnt/boot /mnt/archiso
mount -o subvol=@home,compress=zstd:3,ssd /dev/nvme1n1p2 /mnt/home
mount -o subvol=@archiso,compress=zstd:3,ssd /dev/nvme1n1p2 /mnt/archiso
mount /dev/nvme1n1p1 /mnt/boot
```

## 4. 生成硬件配置 + 拉取 flake

```bash
# 1) 生成硬件配置（真实 UUID）
nixos-generate-config --root /mnt

# 2) 拉取 dotfiles（GitHub public）
git clone https://github.com/jackockzuo/home-manager-ran.git /mnt/dotfiles

# 3) 用生成的 hardware-configuration.nix 覆盖仓库模板
#    （flake 已引用 ./nixos/hardware-configuration.nix，真实 UUID 自动生效）
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/dotfiles/nixos/hardware-configuration.nix

# 4) 确认 fileSystems 已包含真实 UUID（应看到 btrfs 分区和子卷）
grep -A3 'fileSystems' /mnt/dotfiles/nixos/hardware-configuration.nix
```

## 5. 安装

```bash
# 进 chroot 安装（用 flake，绝对路径避免 chroot 后相对路径失效）
nixos-install --flake /mnt/dotfiles#laptop --root /mnt
# 若 flake 拉取慢，可先设置代理或稍等

# 设置用户密码（initialPassword=nixos，安装后改）
reboot
```

## 6. 联网验证（迁移后第一件事）

```bash
# 登录后（密码 nixos 或已改）
nmcli device wifi connect <SSID> password <密码>   # 无线
# 或 nmcli device connect <eth>                     # 有线
ping -c 2 baidu.com
# 打开浏览器查资料：firefox / chromium 已内置
```

## 7. 迁移后确认清单

```bash
# 桌面
echo $XDG_CURRENT_DESKTOP   # 应输出 Niri
# 输入法
fcitx5-remote -t
# 滚挂防护
snapper -c root list
```

### 7.1 把 dotfiles clone 到 home（安装时 flake 在 /mnt/dotfiles，日常更新需要 ~/dotfiles）

```bash
# clone 到 home（home-manager 配置的 dotfiles 路径）
git clone https://github.com/jackockzuo/home-manager-ran.git ~/dotfiles
# 若需要，也把安装时生成的硬件配置同步过来
cp /etc/nixos/hardware-configuration.nix ~/dotfiles/nixos/ 2>/dev/null || true
```

### 7.2 日常更新配置

```bash
cd ~/dotfiles && git pull && sudo nixos-rebuild switch --flake .#laptop
```

## 8. Chrome 配置（NVIDIA 兼容，迁移后必做）

用户主浏览器是 Chrome，NVIDIA 下需要 X11 模式 flags（与 Arch 验证过的相同）：

```bash
# 登录后创建（nix 不管理 Chrome，手动配置）
cat > ~/.config/chrome-flags.conf << 'EOF'
--ozone-platform=x11
--use-gl=angle
--use-angle=gl
--disable-features=DefaultANGLEVulkan,Vulkan,VulkanFromANGLE
EOF

# 重启 Chrome 生效
pkill -f chrome; google-chrome-stable &
```

> 原理：Chrome 151 默认 Vulkan 后端在 nvidia 上渲染器初始化失败（只显示模糊玻璃），强制 GL/X11 模式可解决。
## 9. 常见问题

| 问题 | 解决 |
|---|---|
| 安装卡在下载 flake | 配置代理或换网络 |
| nvidia 黑屏 | 配置已含 hardware.nvidia，若仍黑屏加 `boot.kernelParams = ["nvidia_drm.modeset=1"]` |
| 中文字体 | 配置已含 noto-fonts-cjk-sans |
| 浏览器打不开 | firefox/chromium 已内置，检查网络 |
| Chrome 模糊玻璃/不显示 | NVIDIA + Vulkan 兼容问题，装完执行下方 Chrome flags 配置 |

### 迁移后需调整的 Arch 特有引用（NixOS 差异）

home-manager 配置中 3 处 Arch 特有项在 NixOS 上的表现：

| 配置 | Arch 行为 | NixOS 行为 | 处理 |
|---|---|---|---|
| `modules/desktop/fcitx5.nix` Exec=/usr/bin/fcitx5 | 屏蔽 XDG autostart 防重复 | NixOS 由系统模块管 fcitx5，此屏蔽无副作用 | 无需处理 |
| `modules/desktop/filemanager.nix` Thunar 图片转换用 /usr/bin/notify-send | 正常 | NixOS 无 /usr/bin，动作报错 | 迁移后改路径或忽略（非致命） |
| `modules/tools/shell.nix` clean-system 函数（pacman） | 清理 Arch 系统 | NixOS 无 pacman，调用报错 | 迁移后从配置移除该函数 |
