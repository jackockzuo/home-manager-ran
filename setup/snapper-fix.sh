#!/bin/bash
# ============================================================
# setup-snapper-fix.sh —— 修复 snapper 滚挂防护体系
# 需 root 运行：sudo bash setup-snapper-fix.sh
# 功能：
#   1. 修复 snapper root 配置（防 timeline 快照被误删）
#   2. 创建本地 archiso 子卷（免 U 盘恢复）
# ============================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "需 root: sudo bash $0"; exit 1; }

echo "===== [1/4] 修复 snapper root 配置 ====="
# 根因：TIMELINE_MIN_AGE=3600(1h) 导致新快照未满 1 小时就被 cleanup 删除
# 修复：新快照立即保留（60s），避免"创建即删除"
sed -i 's/^TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="60"/' /etc/snapper/configs/root
# FREE_LIMIT 0.2 太激进（磁盘 20% 就开始删快照），放宽到 5%
sed -i 's/^FREE_LIMIT=.*/FREE_LIMIT="5"/' /etc/snapper/configs/root
echo "✓ root 配置已修复 (MIN_AGE=60, FREE_LIMIT=5%)"
grep -E 'TIMELINE_MIN_AGE|FREE_LIMIT' /etc/snapper/configs/root | grep -v '^#'

echo ""
echo "===== [2/4] 测试快照创建 ====="
snapper -c root create -d "fix-test"
snapper -c root list | head -5
echo "✓ 快照创建成功"

echo ""
echo "===== [3/4] 创建本地 archiso 子卷 ====="
# 在 btrfs 内建独立子卷存 archiso（零分区风险，独立于 @ 快照）
if ! btrfs subvolume list / | grep -q '@archiso'; then
  btrfs subvolume create /@archiso
  echo "✓ 子卷 @archiso 已创建"
else
  echo "✓ @archiso 已存在"
fi
mkdir -p /archiso
mount -o subvol=@archiso,compress=zstd:3 /dev/nvme1n1p2 /archiso || true
grep -q '@archiso' /etc/fstab || echo "/dev/nvme1n1p2  /archiso  btrfs  subvol=@archiso,compress=zstd:3  0  0" >> /etc/fstab
echo "✓ /archiso 挂载点已配置（fstab）"

echo ""
echo "===== [4/4] 完成 ====="
echo "下一步（需网络下载 archiso）:"
echo "  sudo cp /path/to/archlinux-x86_64.iso /archiso/"
echo "  然后配置 GRUB 菜单项（见 README 或后续步骤）"
echo ""
echo "全部完成！"
