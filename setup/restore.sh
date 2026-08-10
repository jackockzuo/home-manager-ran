#!/usr/bin/env bash
# ============================================================
# 一键恢复脚本 —— archinstall 装好基础系统后运行
# 用法（一条命令，自动下载仓库）:
#   curl -sSL https://raw.githubusercontent.com/jackockzuo/home-manager-ran/main/setup/restore.sh | bash
# 或（已 clone 仓库）:
#   bash ~/dotfiles/setup/restore.sh
#
# 功能：基础服务 → nix → home-manager（开发工具链+个人配置）
#       → pacman/AUR 应用（商业/系统/输入法/字体）
# ============================================================
set -euo pipefail

REPO_URL="https://github.com/jackockzuo/home-manager-ran.git"

if [ -d "$(dirname "${BASH_SOURCE[0]:-}")/../.git" ] 2>/dev/null; then
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
    REPO_DIR="$HOME/dotfiles"
    if [ ! -d "$REPO_DIR/.git" ]; then
        command -v git >/dev/null 2>&1 || sudo pacman -S --noconfirm --needed git
        git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    fi
fi
PKG_LIST="$REPO_DIR/setup/pacman-packages.txt"

echo "=================================================="
echo " 开始恢复（仓库: $REPO_DIR）"
echo "=================================================="

# ---------- 1/5 基础服务 ----------
echo "==> [1/5] 启用基础系统服务"
sudo systemctl enable --now NetworkManager 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true
sudo systemctl enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
sudo systemctl enable --now fstrim.timer 2>/dev/null || true

# ---------- 2/5 安装 nix ----------
echo "==> [2/5] 安装 nix（含 flake 支持）"
if ! command -v nix >/dev/null 2>&1; then
    curl -L https://nixos.org/nix/install | sh
    set +u; . "$HOME/.nix-profile/etc/profile.d/nix.sh"; set -u
fi
nix --version

# ---------- 3/5 恢复 home-manager（nix 管开发工具链 + 个人配置）----------
echo "==> [3/5] 恢复 home-manager（nix 自动安装所有个人工具与配置）"
# 用 nix run 临时执行（避免把 home-manager 装进 profile 与 home-manager-path 文件冲突）
# switch 后 home-manager-path 会进 ~/.nix-profile，之后 home-manager 命令可直接用
nix run github:nix-community/home-manager -- switch --flake "$REPO_DIR#ran"

# ---------- 4/5 安装 pacman/AUR 应用 ----------
echo "==> [4/5] 安装 pacman/AUR 应用（paru 统一处理官方仓库 + AUR）"
# archlinuxcn 仓库（若已配置则启用；未配置时 paru 走官方仓库 + AUR）
sudo pacman -S --needed --noconfirm paru 2>/dev/null || true
# 安装清单（忽略注释行和空行）
mapfile -t PKGS < <(grep -vE '^\s*#|^\s*$' "$PKG_LIST")
echo "    待安装 $((${#PKGS[@]})) 个包..."
paru -S --needed --noconfirm "${PKGS[@]}"

# DMS greeter 登录界面（替代 sddm，登录风格与 DMS 桌面壳统一）：
# 1) dms greeter install 配置 greetd 使用 dms-greeter（自动禁用 sddm、启用 greetd）
# 2) dms greeter sync 把当前 DMS 主题/壁纸/设置同步到登录界面
dms greeter install -y 2>/dev/null || true
dms greeter sync -y 2>/dev/null || true

# ---------- 5/5 收尾 ----------
echo "==> [5/5] 收尾"

# GRUB catppuccin 主题（主题包由上方 paru 安装，这里启用并重新生成）
if [ -f "/boot/grub/themes/catppuccin-mocha-grub-theme/theme.txt" ]; then
    sudo sed -i 's|^#\?GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/catppuccin-mocha-grub-theme/theme.txt"|' /etc/default/grub

    # 用壁纸替换主题背景（与 niri/DMS 暗色风格统一；壁纸缺失时保留自带背景）
    WALLPAPER="$HOME/Pictures/Wallpapers/girlgreen.jpg"
    if [ -f "$WALLPAPER" ]; then
        if command -v magick >/dev/null 2>&1; then
            magick "$WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 \
                -background black -alpha remove -alpha off -fill black -colorize 35% -strip \
                /tmp/grub-background.png
            sudo cp /tmp/grub-background.png /boot/grub/themes/catppuccin-mocha-grub-theme/background.png
            rm -f /tmp/grub-background.png
        else
            sudo cp "$WALLPAPER" /boot/grub/themes/catppuccin-mocha-grub-theme/background.png
        fi
        echo "    ✓ GRUB 背景已替换为壁纸（与 DMS 风格统一）"
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# 关闭 pam_faillock 密码失败锁定（防 greeter/polkit 弹窗误触发锁死账户）
printf 'deny = 999999\n' | sudo tee /etc/security/faillock.conf >/dev/null

# 若 nvidia 驱动已装，提示确认
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "    ✓ NVIDIA 驱动已就绪: $(nvidia-smi -L 2>/dev/null | head -1)"
fi

echo ""
echo "=================================================="
echo " 恢复完成！请执行："
echo "   1) 重启登录 DMS greeter → niri"
echo "   2) 若输入法异常: fcitx5-remote 检查"
echo "   3) 可选: 恢复 DMS 用户配置 ~/.config/DankMaterialShell"
echo "=================================================="
