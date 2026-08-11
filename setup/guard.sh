#!/bin/bash
# ============================================================
# setup-guard.sh —— 一键配置滚挂防护体系（需 root 运行一次）
# 用法：sudo bash setup/guard.sh
# 依次执行：
#   1. snapper-fix.sh   修 snapper 防误删 + 建 @archiso 子卷
#   2. snap-pac.sh      装 snap-pac（升级前自动快照）+ 移除 timeshift
#   3. 下载 archiso 到 /archiso/
#   4. grub-archiso.sh  配置 GRUB 本地 archiso 引导项
# ============================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "需 root: sudo bash setup/guard.sh"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_URL="${ISO_URL:-https://mirrors.tuna.tsinghua.edu.cn/archlinux/iso/latest/archlinux-x86_64.iso}"

echo "=============================================="
echo " 滚挂防护一键配置"
echo "=============================================="

echo ""
echo "===== [1/4] 修复 snapper + 建 @archiso 子卷 ====="
bash "$SCRIPT_DIR/snapper-fix.sh"

echo ""
echo "===== [2/4] 安装 snap-pac + 移除 timeshift ====="
bash "$SCRIPT_DIR/snap-pac.sh"

echo ""
echo "===== [3/4] 下载 archiso 到 /archiso/ ====="
mkdir -p /archiso
if [ -f /archiso/archlinux-x86_64.iso ]; then
  echo "✓ 已存在 /archiso/archlinux-x86_64.iso，跳过下载"
else
  echo "下载 $ISO_URL ..."
  curl -L -o /archiso/archlinux-x86_64.iso "$ISO_URL"
  echo "✓ 下载完成"
fi

echo ""
echo "===== [4/4] 配置 GRUB 引导项 ====="
bash "$SCRIPT_DIR/grub-archiso.sh"

echo ""
echo "=============================================="
echo " 全部完成！滚挂防护已就绪："
echo "   • pacman -Syu 前自动快照（snap-pac）"
echo "   • 滚挂后 GRUB 选快照回滚"
echo "   • 系统起不来时 GRUB 选 'Arch Linux ISO (本地恢复)'"
echo "=============================================="
