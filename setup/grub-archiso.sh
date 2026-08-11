#!/bin/bash
# ============================================================
# setup-grub-archiso.sh —— 配置 GRUB 本地 archiso 引导项
# 需 root 运行：sudo bash setup-grub-archiso.sh
# 前置：archiso 已复制到 /archiso/archlinux-x86_64.iso
# 效果：GRUB 菜单新增 "Arch ISO (本地恢复)" 项，免 U 盘进入 live 环境
# ============================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "需 root: sudo bash $0"; exit 1; }
[ -f /archiso/archlinux-x86_64.iso ] || { echo "❌ 未找到 /archiso/archlinux-x86_64.iso，请先下载"; exit 1; }

echo "===== 创建 GRUB 自定义菜单 ====="
mkdir -p /boot/grub/custom

# 提取 archiso 引导参数（自动获取 UUID）
UUID=$(blkid -s UUID -o value /dev/nvme1n1p2)

cat > /boot/grub/custom/archiso.cfg << EOF
# 本地 archiso 恢复引导（免 U 盘）
menuentry 'Arch Linux ISO (本地恢复)' --class arch --class os {
    insmod part_gpt
    insmod btrfs
    search --set=root --fs-uuid ${UUID}
    loopback loop /@archiso/archlinux-x86_64.iso
    linux (loop)/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisosearchuuid=$(blkid -s UUID -o value /archiso/archlinux-x86_64.iso 2>/dev/null || echo "") img_dev=/dev/disk/by-uuid/${UUID} img_loop=/@archiso/archlinux-x86_64.iso
    initrd (loop)/arch/boot/x86_64/initramfs-linux.img
}
EOF

echo "✓ GRUB 菜单已创建 /boot/grub/custom/archiso.cfg"
echo ""
echo "===== 重新生成 grub.cfg ====="
grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tail -5

echo ""
echo "===== 验证 ====="
grep -c 'Arch Linux ISO' /boot/grub/grub.cfg | xargs echo "grub.cfg 中 archiso 菜单项数:"
echo "✓ 完成！重启后在 GRUB 菜单可见 'Arch Linux ISO (本地恢复)'"
