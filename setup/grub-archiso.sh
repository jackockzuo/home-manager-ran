#!/bin/bash
# ============================================================
# setup-grub-archiso.sh —— 配置 GRUB 本地 archiso 引导项
# 需 root 运行：sudo bash setup-grub-archiso.sh
# 前置：archiso 已复制到 /archiso/archlinux-x86_64.iso
# 效果：GRUB 菜单新增 "Arch ISO (本地恢复)" 项，免 U 盘进入 live 环境
# ============================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "需 root: sudo bash $0"; exit 1; }
ISO="/archiso/archlinux-x86_64.iso"
[ -f "$ISO" ] || { echo "❌ 未找到 $ISO，请先下载"; exit 1; }

echo "===== 提取 archiso 引导参数 ====="
# btrfs 分区 UUID（ISO 所在）
DISK_UUID=$(blkid -s UUID -o value /dev/nvme1n1p2)
[ -n "$DISK_UUID" ] || { echo "❌ 无法获取 nvme1n1p2 UUID"; exit 1; }

# archisosearchuuid 是 ISO 内部构建标识，需从 loader 配置提取（ISO 文件本身无 blkid UUID）
SEARCH_UUID=""
if command -v bsdtar >/dev/null 2>&1; then
  SEARCH_UUID=$(bsdtar -xOf "$ISO" loader/entries/01-archiso-linux.conf 2>/dev/null | grep -oE 'archisosearchuuid=[^ ]+' | head -1 | cut -d= -f2)
elif command -v 7z >/dev/null 2>&1; then
  SEARCH_UUID=$(7z e -so "$ISO" loader/entries/01-archiso-linux.conf 2>/dev/null | grep -oE 'archisosearchuuid=[^ ]+' | head -1 | cut -d= -f2)
fi
[ -n "$SEARCH_UUID" ] || { echo "❌ 无法提取 archisosearchuuid（需 bsdtar 或 7z）"; exit 1; }
echo "✓ DISK_UUID=$DISK_UUID"
echo "✓ SEARCH_UUID=$SEARCH_UUID"

echo ""
echo "===== 创建 GRUB 自定义菜单 ====="
# 写入 /etc/grub.d/41_custom（grub-mkconfig 自动包含的标准路径）
cat > /etc/grub.d/41_custom << EOF
# 本地 archiso 恢复引导（免 U 盘）
menuentry 'Arch Linux ISO (本地恢复)' --class arch --class os {
    insmod part_gpt
    insmod btrfs
    search --set=root --fs-uuid ${DISK_UUID}
    loopback loop /@archiso/archlinux-x86_64.iso
    linux (loop)/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisosearchuuid=${SEARCH_UUID} img_dev=/dev/disk/by-uuid/${DISK_UUID} img_loop=/@archiso/archlinux-x86_64.iso
    initrd (loop)/arch/boot/x86_64/initramfs-linux.img
}
EOF

echo "✓ GRUB 菜单已创建 /etc/grub.d/41_custom"
echo ""
echo "===== 重新生成 grub.cfg ====="
grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tail -5

echo ""
echo "===== 验证 ====="
grep -c 'Arch Linux ISO' /boot/grub/grub.cfg | xargs echo "grub.cfg 中 archiso 菜单项数:"
echo "✓ 完成！重启后在 GRUB 菜单可见 'Arch Linux ISO (本地恢复)'"
