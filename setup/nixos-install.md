# NixOS 实机安装指南（迁移自 Arch）

> 目标：nvme1n1 整盘装 NixOS（保留 nvme0n1 Windows 不动）
> 配置：flake `.#laptop`（已构建验证，含联网工具+桌面+滚挂防护）
> 前置：U 盘 + 已备份数据

## 0. 迁移前备份（必须，nvme1n1 会被格式化）

```bash
# 备份到 nvme0n1p5（2G ext4，Windows 恢复盘）或外接盘
sudo mkdir -p /mnt/backup
sudo mount /dev/nvme0n1p5 /mnt/backup   # 或外接盘 /dev/sdX1
sudo rsync -av --exclude='.cache' /home/ran/Documents /mnt/backup/
sudo rsync -av --exclude='.cache' /home/ran/Pictures /mnt/backup/
sudo rsync -av /home/ran/Downloads /mnt/backup/
sudo rsync -av ~/.config/google-chrome ~/.mozilla /mnt/backup/dotfiles-config/
sudo umount /mnt/backup
# dotfiles 已在 GitHub（main 分支），无需额外备份
```

## 1. 制作 NixOS 安装 U 盘

```bash
# 下载 NixOS ISO（国内镜像）
curl -L -o ~/Downloads/nixos.iso \
  https://mirrors.tuna.tsinghua.edu.cn/nixos-images/nixos-25.05/nixos-gnome-25.05.xxxx-x86_64-linux.iso
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
# 生成硬件配置（真实 UUID）
nixos-generate-config --root /mnt

# 拉取 dotfiles（GitHub public）
git clone https://github.com/jackockzuo/home-manager-ran.git /mnt/dotfiles

# 用生成的硬件 UUID 替换占位符（手动替换，勿复制整个 hardware-configuration.nix，
# 否则与 hardware-laptop.nix 的 fileSystems 重复定义会报错）
# 1) 查看真实 UUID：
grep -E 'by-uuid|by-label' /mnt/etc/nixos/hardware-configuration.nix
# 2) 编辑 /mnt/dotfiles/nixos/hardware-laptop.nix 替换 3 个占位符：
#    REPLACE_WITH_ROOT_UUID → 根 btrfs 分区 UUID
#    REPLACE_WITH_HOME_UUID → 同分区（home 是子卷，用同一 UUID）
#    REPLACE_WITH_EFI_UUID  → EFI 分区 UUID
sed -i 's/REPLACE_WITH_ROOT_UUID/<根UUID>/' /mnt/dotfiles/nixos/hardware-laptop.nix
sed -i 's/REPLACE_WITH_HOME_UUID/<根UUID>/' /mnt/dotfiles/nixos/hardware-laptop.nix
sed -i 's/REPLACE_WITH_EFI_UUID/<EFI-UUID>/' /mnt/dotfiles/nixos/hardware-laptop.nix
```

## 5. 安装

```bash
# 进 chroot 安装（用 flake）
cd /mnt/dotfiles
nixos-install --flake .#laptop --root /mnt
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
# 更新配置
cd ~/dotfiles && git pull && sudo nixos-rebuild switch --flake .#laptop
# 滚挂防护
snapper -c root list
```

## 常见问题

| 问题 | 解决 |
|---|---|
| 安装卡在下载 flake | 配置代理或换网络 |
| nvidia 黑屏 | 配置已含 hardware.nvidia，若仍黑屏加 `boot.kernelParams = ["nvidia_drm.modeset=1"]` |
| 中文字体 | 配置已含 noto-fonts-cjk-sans |
| 浏览器打不开 | firefox/chromium 已内置，检查网络 |
