#!/bin/bash
# ============================================================
# setup-snap-pac.sh —— 安装 snap-pac + 移除 timeshift
# 需 root 运行：sudo bash setup-snap-pac.sh
# 功能：
#   1. 安装 snap-pac（pacman 升级前自动快照，含预装 paru）
#   2. 启用系统降级快照支持（snap-pac 自带）
#   3. 移除 timeshift（与 snapper 重复）
# ============================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "需 root: sudo bash $0"; exit 1; }

echo "===== [1/3] 安装 snap-pac ====="
# snap-pac 在 AUR；优先 paru，否则用 pacman 装后补
if command -v paru >/dev/null 2>&1; then
  su - ran -c "paru -S --noconfirm snap-pac" || paru -S --noconfirm snap-pac
elif command -v yay >/dev/null 2>&1; then
  su - ran -c "yay -S --noconfirm snap-pac"
else
  echo "⚠️ 无 AUR 助手，请手动安装 snap-pac（AUR）"
  exit 1
fi
echo "✓ snap-pac 已安装"

echo ""
echo "===== [2/3] 验证 pacman hook 已生效 ====="
ls /etc/pacman.d/hooks/ | grep -i snapper | head -5
echo "✓ hook 文件存在（pacman -Syu 前自动快照）"

echo ""
echo "===== [3/3] 移除 timeshift ====="
if pacman -Q timeshift 2>/dev/null; then
  pacman -Rns --noconfirm timeshift
  echo "✓ timeshift 已移除"
else
  echo "✓ timeshift 未安装"
fi

echo ""
echo "===== 验证最终快照体系 ====="
snapper list-configs
echo ""
echo "完成！下次 pacman -Syu 会自动创建升级前快照。"
echo "滚挂后重启 → GRUB 菜单选快照回滚。"
