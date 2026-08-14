#!/bin/bash
# ============================================================
# backup.sh —— 迁移前备份关键数据（需 root 运行一次）
# 用法：sudo bash setup/backup.sh
# 功能：备份 Documents/Pictures/Downloads/浏览器配置 到 nvme0n1p5 或外接盘
# 环境变量：BACKUP_DEV=备份目标设备（默认 nvme0n1p5），默认路径 /mnt/backup
# ============================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "需 root: sudo bash setup/backup.sh"; exit 1; }

BACKUP_DEV="${BACKUP_DEV:-/dev/nvme0n1p5}"
MOUNT_POINT="/mnt/backup"
BACKUP_USER="${SUDO_USER:-ran}"
HOME_DIR="/home/$BACKUP_USER"

echo "=============================================="
echo " 迁移前备份（目标: $BACKUP_DEV → $MOUNT_POINT）"
echo "=============================================="

# ---------- 1. 挂载备份目标 ----------
echo "==> [1/5] 挂载备份设备 $BACKUP_DEV ..."
mkdir -p "$MOUNT_POINT"
mount "$BACKUP_DEV" "$MOUNT_POINT" 2>/dev/null || {
  echo "  尝试自动挂载失败，检查设备..."
  lsblk -f "$BACKUP_DEV" 2>/dev/null || { echo "❌ 设备不可用，请用 BACKUP_DEV=/dev/sdX1 指定"; exit 1; }
}

# ---------- 2. 备份文档/图片/下载 ----------
echo "==> [2/5] 备份 Documents/Pictures/Downloads ..."
for dir in Documents Pictures Downloads; do
  if [ -d "$HOME_DIR/$dir" ]; then
    echo "  备份 $dir ($(du -sh "$HOME_DIR/$dir" 2>/dev/null | cut -f1))..."
    rsync -a --info=progress2 "$HOME_DIR/$dir/" "$MOUNT_POINT/$dir/" 2>/dev/null || true
  fi
done

# ---------- 3. 备份浏览器配置（书签/密码） ----------
echo "==> [3/5] 备份浏览器配置（书签/密码/历史）..."
for browser in google-chrome mozilla; do
  if [ -d "$HOME_DIR/.config/$browser" ]; then
    echo "  备份 .config/$browser ..."
    mkdir -p "$MOUNT_POINT/browser-config"
    rsync -a "$HOME_DIR/.config/$browser/" "$MOUNT_POINT/browser-config/$browser/" 2>/dev/null || true
  fi
done

# ---------- 4. 备份 dotfiles（本地未推送的改动） ----------
echo "==> [4/5] 备份 dotfiles ..."
if [ -d "$HOME_DIR/.config/home-manager" ]; then
  git -C "$HOME_DIR/.config/home-manager" add -A 2>/dev/null || true
  git -C "$HOME_DIR/.config/home-manager" diff --cached --quiet 2>/dev/null || {
    echo "  检测到未推送改动，备份到 $MOUNT_POINT/dotfiles-extra.patch"
    git -C "$HOME_DIR/.config/home-manager" diff --cached > "$MOUNT_POINT/dotfiles-extra.patch" 2>/dev/null || true
  }
fi

# ---------- 5. 收尾 ----------
echo "==> [5/5] 卸载备份设备 ..."
sync
umount "$MOUNT_POINT"
echo ""
echo "=============================================="
echo " 备份完成！数据已存入 $BACKUP_DEV"
echo " 安装 NixOS 后从该盘恢复即可。"
echo "=============================================="
