#!/bin/bash
# ============================================================
# recover.sh —— 从 archiso live 环境一键挂载 + chroot 恢复
# 用法（archiso 启动后，root 下执行）：
#   curl -sSL https://raw.githubusercontent.com/jackockzuo/home-manager-ran/main/setup/recover.sh | bash
# 或本地：bash setup/recover.sh
# 流程：
#   1. 自动检测系统盘（btrfs 根分区）
#   2. 挂载 @/@home/@archiso/boot
#   3. chroot 进入系统（提示修复）
# 环境变量：
#   DISK=     系统盘（如 /dev/nvme0n1），默认自动检测
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[recover]${NC} $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---------- 1. 环境检测 ----------
[ "$(id -u)" = "0" ] || die "必须以 root 运行（archiso 默认是 root）"

# ---------- 2. 检测系统盘 ----------
if [ -z "${DISK:-}" ]; then
  echo "检测 btrfs 根分区..."
  BTRFS_DEV=$(lsblk -o NAME,FSTYPE -r | awk '$2=="btrfs" {print "/dev/"$1}' | head -1)
  [ -n "$BTRFS_DEV" ] || die "未找到 btrfs 分区，请用 DISK=/dev/xxx 指定"
  # 从分区设备反推整盘（nvme0n1p2 → nvme0n1）
  case "$BTRFS_DEV" in
    *nvme*) DISK=$(echo "$BTRFS_DEV" | sed 's/p[0-9]*$//') ;;
    *sd*|*vd*) DISK=$(echo "$BTRFS_DEV" | sed 's/[0-9]*$//') ;;
  esac
fi
[ -b "$DISK" ] || die "磁盘不存在: $DISK"

# ---------- 3. 确定分区 ----------
case "$DISK" in
  *nvme*) PART_EFI="${DISK}p1"; PART_ROOT="${DISK}p2" ;;
  *sd*|*vd*) PART_EFI="${DISK}1"; PART_ROOT="${DISK}2" ;;
esac

info "系统盘: $DISK"
info "EFI: $PART_EFI  根: $PART_ROOT"

# ---------- 4. 挂载 ----------
info "挂载系统..."
mountpoint -q /mnt || mount -o subvol=@,compress=zstd:3,ssd "$PART_ROOT" /mnt
mountpoint -q /mnt/home || { mkdir -p /mnt/home && mount -o subvol=@home,compress=zstd:3,ssd "$PART_ROOT" /mnt/home; }
mountpoint -q /mnt/boot || { mkdir -p /mnt/boot && mount "$PART_EFI" /mnt/boot; }
mountpoint -q /mnt/archiso || { mkdir -p /mnt/archiso && mount -o subvol=@archiso,compress=zstd:3,ssd "$PART_ROOT" /mnt/archiso 2>/dev/null || true; }

# 挂载必要的虚拟文件系统
mount --bind /dev /mnt/dev 2>/dev/null || true
mount --bind /proc /mnt/proc 2>/dev/null || true
mount --bind /sys /mnt/sys 2>/dev/null || true

info "挂载完成，进入 chroot（退出用 exit）..."
echo ""
echo "=============================================="
echo " 已进入系统 chroot。常见修复："
echo "   • 修复 pacman:  pacman -Syu"
echo "   • 重建 GRUB:    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
echo "                    grub-mkconfig -o /boot/grub/grub.cfg"
echo "   • 回滚快照:    snapper -c root list（找目标快照号 N）"
echo "                    snapper -c root rollback N"
echo "   • 退出:        exit（自动卸载）"
echo "=============================================="
chroot /mnt /bin/bash

# ---------- 5. 退出后卸载 ----------
info "卸载系统..."
umount /mnt/dev /mnt/proc /mnt/sys 2>/dev/null || true
umount /mnt/archiso /mnt/boot /mnt/home /mnt 2>/dev/null || true
info "完成，可安全重启。"
