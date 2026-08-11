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
# snap-pac 在 AUR，必须由用户在交互终端安装（paru 内部 sudo 需要密码）
AUR_USER="${SUDO_USER:-$USER}"
if command -v snap-pac >/dev/null 2>&1; then
  echo "✓ snap-pac 已安装"
elif [ -t 0 ]; then
  if command -v paru >/dev/null 2>&1; then
    su - "$AUR_USER" -c "paru -S --noconfirm snap-pac"
  elif command -v yay >/dev/null 2>&1; then
    su - "$AUR_USER" -c "yay -S --noconfirm snap-pac"
  else
    echo "⚠️ 无 AUR 助手，请以用户 $AUR_USER 手动安装 snap-pac（AUR）"
    exit 1
  fi
else
  echo "⚠️ 检测到无交互终端，无法自动安装 AUR 包。"
  echo "   请在【另开的终端】以用户 $AUR_USER 执行："
  echo "     paru -S snap-pac"
  echo "   然后重新运行本脚本（或 guard.sh）继续。"
  exit 1
fi
echo "✓ snap-pac 已安装"

echo ""
echo "===== [2/3] 验证 pacman hook 已生效 ====="
found_hooks=0
for hook in /etc/pacman.d/hooks/*snapper*; do
  [ -e "$hook" ] && echo "  ✓ $(basename "$hook")" && found_hooks=1
done
[ "$found_hooks" = "1" ] || echo "⚠️ 未找到 snapper hook（可能 snap-pac 安装异常）"
echo "✓ hook 检查完成（pacman -Syu 前自动快照）"

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
