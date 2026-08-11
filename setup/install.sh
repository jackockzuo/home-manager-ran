#!/usr/bin/env bash
# ============================================================
# install.sh —— 从 archlinux.iso 一键安装 Arch + niri 桌面环境
#
# 用法（archiso 启动后，root 下执行）：
#   curl -sSL https://raw.githubusercontent.com/jackockzuo/home-manager-ran/main/setup/install.sh | bash
#   或：bash <(curl -sSL ...)  （本地：bash setup/install.sh）
#
# 流程：
#   1. 环境检测（archiso root + UEFI）
#   2. 分区（GPT: EFI 1G + btrfs，子卷 @/@home）
#   3. pacstrap 基础系统 + 桌面二进制（desktop-packages.txt）
#   4. 配置 fstab / locale / 用户
#   5. 装 GRUB + 启用服务
#   6. 装 nix + home-manager → 应用本仓库配置（生成全部桌面配置）
#   7. 收尾提示 reboot
#
# 环境变量（可选，避免交互）：
#   DISK=       目标磁盘（如 /dev/nvme0n1），默认交互选择
#   HOSTNAME=   主机名（默认 archlinux）
#   USERNAME=   用户名（默认 ran）
#   PASSWORD=   用户密码（默认交互输入）
#   REPO_URL=   配置仓库（默认 GitHub public）
#   AUTO=1      跳过所有交互确认（自动化/CI/VM 测试用）
#   DRY_RUN=1   只打印要执行的命令，不真正执行（测试用）
# ============================================================
set -euo pipefail

# ---------- 0. 颜色/工具 ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[install]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
die()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# 危险操作保护（DRY_RUN 模拟模式）
run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo -e "${YELLOW}[dry-run]${NC} $*"
  else
    eval "$*"
  fi
}

# ---------- 1. 环境检测 ----------
if [ "${DRY_RUN:-0}" != "1" ]; then
  [ "$(id -u)" = "0" ] || die "必须以 root 运行（archiso 默认是 root）"
  [ -d /sys/firmware/efi ] || die "非 UEFI 启动，本脚本仅支持 UEFI"
  [ -f /etc/arch-release ] || warn "未检测到 archiso 环境（可能是已装系统），继续尝试..."
  mountpoint -q /mnt 2>/dev/null && die "/mnt 已挂载，请先 umount"
fi
info "环境检测通过：archiso root + UEFI"

# ---------- 2. 选择磁盘 ----------
if [ -z "${DISK:-}" ]; then
  if [ "${DRY_RUN:-0}" = "1" ]; then
    DISK="/dev/nvme0n1"  # dry-run 默认
  else
    echo ""
    echo "可用磁盘："
    lsblk -d -o NAME,SIZE,MODEL -e 7,11 | grep -v NAME
    echo ""
    read -rp "输入目标磁盘（如 /dev/nvme0n1，将【整个盘】格式化）: " DISK
  fi
fi
[ -b "$DISK" ] || die "磁盘不存在: $DISK"

# 幂等保护：目标盘已有分区表时拒绝覆盖（除非 FORCE=1 显式要求重装）
if [ "${DRY_RUN:-0}" != "1" ] && [ "${FORCE:-0}" != "1" ]; then
  if parted -s "$DISK" print >/dev/null 2>&1 && parted -s "$DISK" print 2>/dev/null | grep -q 'Number'; then
    die "磁盘 ${DISK} 已有分区（检测到数据），为防止误覆盖已中止。确认重装请加 FORCE=1"
  fi
fi

warn "即将格式化 ${DISK} 全部数据！"
if [ "${DRY_RUN:-0}" != "1" ] && [ "${AUTO:-0}" != "1" ]; then
  read -rp "确认输入 yes 继续: " confirm
  [ "$confirm" = "yes" ] || die "已取消"
fi

HOSTNAME="${HOSTNAME:-archlinux}"
USERNAME="${USERNAME:-ran}"
if [ -z "${PASSWORD:-}" ] && [ "${DRY_RUN:-0}" != "1" ] && [ "${AUTO:-0}" != "1" ]; then
  read -rsp "设置用户 ${USERNAME} 的密码: " PASSWORD; echo
fi
REPO_URL="${REPO_URL:-https://github.com/jackockzuo/home-manager-ran.git}"

# ---------- 3. 分区（GPT: EFI 1G + btrfs） ----------
info "分区 ${DISK} ..."
run "parted -s ${DISK} mklabel gpt"
run "parted -s ${DISK} mkpart ESP fat32 1MiB 1GiB"
run "parted -s ${DISK} set 1 esp on"
run "parted -s ${DISK} mkpart primary btrfs 1GiB 100%"
PART_EFI="${DISK}p1"; PART_ROOT="${DISK}p2"
case "$DISK" in
  *nvme*) PART_EFI="${DISK}p1"; PART_ROOT="${DISK}p2" ;;
  *sd*|*vd*|*xvd*) PART_EFI="${DISK}1"; PART_ROOT="${DISK}2" ;;
esac

info "格式化分区 ..."
run "mkfs.fat -F32 ${PART_EFI}"
run "mkfs.btrfs -f ${PART_ROOT}"

# ---------- 4. 挂载 + 创建子卷 ----------
info "挂载并创建 btrfs 子卷（@/@home/@archiso）..."
run "mount ${PART_ROOT} /mnt"
run "btrfs subvolume create /mnt/@"
run "btrfs subvolume create /mnt/@home"
run "btrfs subvolume create /mnt/@archiso"
run "umount /mnt"
run "mount -o subvol=@,compress=zstd:3,ssd ${PART_ROOT} /mnt"
run "mkdir -p /mnt/home"
run "mount -o subvol=@home,compress=zstd:3,ssd ${PART_ROOT} /mnt/home"
run "mkdir -p /mnt/boot"
run "mount ${PART_EFI} /mnt/boot"

# ---------- 5. pacstrap 基础系统 ----------
info "pacstrap 基础系统（可能需要几分钟下载）..."
MIRRORLIST_URL="https://mirrors.tuna.tsinghua.edu.cn/archlinux/mirrorlist/archlinux-cn.txt"
run "pacman -Sy --noconfirm archlinux-keyring"

# 配置国内镜像（可选，网络好可跳过）
if [ "${USE_MIRROR:-1}" = "1" ]; then
  info "配置清华镜像源..."
  run "echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist"
fi

# 基础包 + 桌面二进制（desktop-packages.txt 与本脚本同目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_PKGS="base linux linux-firmware base-devel networkmanager git curl vim sudo fish grub efibootmgr snapper grub-btrfs btrfs-progs"
DESKTOP_PKGS="$(grep -vE '^\s*#|^\s*$' "${SCRIPT_DIR}/desktop-packages.txt" | sed 's/#.*$//' | tr '\n' ' ')"

info "安装基础包 + 桌面组件（niri/fcitx5/kitty/pipewire 等）..."
run "pacstrap /mnt ${BASE_PKGS} ${DESKTOP_PKGS}"

# ---------- 6. 生成 fstab ----------
info "生成 fstab ..."
run "genfstab -U /mnt >> /mnt/etc/fstab"

# ---------- 7. chroot 配置 ----------
info "chroot 配置系统 ..."
CHROOT_SCRIPT=$(mktemp)
cat > "$CHROOT_SCRIPT" << 'CHROOTEOF'
#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${HOSTNAME}"
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"

# 时区/语言
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname

# hosts
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# 用户
useradd -m -G wheel,audio,video,network -s /usr/bin/fish "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "$USERNAME ALL=(ALL) ALL" > /etc/sudoers.d/10-$USERNAME
chmod 440 /etc/sudoers.d/10-$USERNAME

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 服务
systemctl enable NetworkManager bluetooth greetd

# pipewire 用户服务（pacman 装后默认存在 unit，enable 到用户）
systemctl enable --global pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

# ===== 滚挂防护（snapper + grub-btrfs）=====
# 1. 创建 snapper 配置（root + home）
snapper -c root create-config /
snapper -c home create-config /home 2>/dev/null || true

# 2. 修复 timeline 快照被误删（MIN_AGE 3600→60，FREE_LIMIT 放宽）
sed -i 's/^TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="60"/' /etc/snapper/configs/root
sed -i 's/^FREE_LIMIT=.*/FREE_LIMIT="5"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="60"/' /etc/snapper/configs/home 2>/dev/null || true

# 3. 启用 snapper 定时器（自动快照 + 清理）
systemctl enable snapper-timeline.timer snapper-cleanup.timer

# 4. 配置 /archiso 挂载（滚挂恢复用本地 archiso 引导）
mkdir -p /archiso
BTRFS_DEV=$(findmnt -no SOURCE / | sed 's/\[.*//')
grep -q '/archiso' /etc/fstab || echo "${BTRFS_DEV}  /archiso  btrfs  subvol=@archiso,compress=zstd:3  0  0" >> /etc/fstab

# 5. GRUB 收录快照（grub-btrfs 自动生成快照启动项）
systemctl enable grub-btrfsd.service 2>/dev/null || true
grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null

CHROOTEOF
chmod +x "$CHROOT_SCRIPT"
run "cp '$CHROOT_SCRIPT' /mnt/root/install-chroot.sh"
run "arch-chroot /mnt /root/install-chroot.sh"
rm -f "$CHROOT_SCRIPT"

# ---------- 8. 装 nix + 拉仓库 + home-manager ----------
info "安装 nix 并应用 home-manager 配置..."
NIX_SCRIPT=$(mktemp)
cat > "$NIX_SCRIPT" << 'NIXEOF'
#!/usr/bin/env bash
set -euo pipefail
USERNAME="${USERNAME}"
REPO_URL="${REPO_URL}"

# 装 nix（多用户，官方安装器）
su - "$USERNAME" -c "curl -L https://nixos.org/nix/install | sh"

# 拉取配置仓库
su - "$USERNAME" -c "git clone --depth 1 '$REPO_URL' ~/dotfiles"

# 应用 home-manager（nix run 临时执行，不污染 profile）
su - "$USERNAME" -c "
  export PATH=\"\$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:\$PATH\"
  cd ~/dotfiles
  nix run github:nix-community/home-manager -- switch --flake \$HOME/dotfiles#ran
"
NIXEOF
chmod +x "$NIX_SCRIPT"
run "cp '$NIX_SCRIPT' /mnt/root/install-nix.sh"
run "arch-chroot /mnt /root/install-nix.sh"
rm -f "$NIX_SCRIPT"

# ---------- 9. 收尾 ----------
umount -R /mnt 2>/dev/null || true
info "=============================================="
info " 安装完成！"
info "  1. reboot 进入新系统"
info "  2. 登录 DMS greeter → niri 桌面"
info "  3. 若需更多应用: sudo pacman -S <包名>（个体应用不在此脚本范围）"
info "  4. 更新配置: cd ~/dotfiles && git pull && home-manager switch"
info ""
info " 滚挂防护已内置（snapper + grub-btrfs）："
info "   • pacman -Syu 前自动快照：需装 snap-pac（AUR，手动执行）"
info "     paru -S snap-pac"
info "   • 本地 archiso 恢复引导：装完系统后下载 ISO"
info "     sudo curl -L -o /archiso/archlinux-x86_64.iso \\"
info "       https://mirrors.tuna.tsinghua.edu.cn/archlinux/iso/latest/archlinux-x86_64.iso"
info "     然后运行: sudo bash ~/dotfiles/setup/grub-archiso.sh"
info "=============================================="
