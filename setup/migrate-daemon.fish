#!/usr/bin/env fish
# migrate-daemon.fish
# Nix 单用户 → 多用户 daemon 迁移脚本（Arch Linux）
# 用法:  fish setup/migrate-daemon.fish
# 说明:  1) 清理孤儿 nixbld 用户/组  2) 移动旧 store 到 /nix.bak
#         3) 官方多用户安装器          4) 写入 /etc/nix/nix.conf
#         5) 重建 ran 的用户环境       6) 验证
# 验证通过后手动删除旧 store:  sudo rm -rf /nix.bak

set -l RED (set_color red)
set -l GRN (set_color green)
set -l YEL (set_color yellow)
set -l RST (set_color normal)

echo "=============================================="
echo "  Nix 多用户 (daemon) 迁移"
echo "=============================================="

# ---------- 前置检查 ----------
if test -d /nix.bak
    echo "$RED[中止] /nix.bak 已存在，先处理它再运行$RST"
    exit 1
end

if systemctl is-active --quiet nix-daemon
    echo "$GRN[跳过] nix-daemon 已在运行，无需迁移$RST"
    exit 0
end

# nixbld 组若还有文件归属则中止（防止误删在用数据）
set -l owned (find /nix /home /var /tmp -group nixbld 2>/dev/null | head -5)
if test -n "$owned"
    echo "$RED[中止] nixbld 组仍拥有文件:$RST"
    echo $owned
    exit 1
end

# ---------- 1/6 删除孤儿 nixbld 用户 ----------
echo "==> 1/6 删除孤儿 nixbld 用户"
for u in (getent passwd | string match -r 'nixbld[0-9]+')
    echo "    userdel $u"
    sudo userdel $u
end

# ---------- 2/6 删除孤儿 nixbld 组 ----------
if getent group nixbld >/dev/null 2>&1
    echo "==> 2/6 删除孤儿 nixbld 组"
    sudo groupdel nixbld
end

# ---------- 3/6 移动旧 store ----------
echo "==> 3/6 移动旧 store 到 /nix.bak（保留回滚余地）"
sudo mv /nix /nix.bak
or begin
    echo "$RED[失败] 无法移动 /nix$RST"
    exit 1
end

# ---------- 4/6 运行多用户安装器 ----------
echo "==> 4/6 运行 Nix 多用户安装器（约 1-3 分钟）"
curl -L https://nixos.org/nix/install | sudo bash -s -- --daemon
or begin
    echo "$RED[失败] 安装器失败。回滚: sudo mv /nix.bak /nix$RST"
    exit 1
end

# ---------- 5/6 写入 /etc/nix/nix.conf（daemon 只读这里）----------
echo "==> 5/6 写入 /etc/nix/nix.conf 并重启 daemon"
printf '%s\n' \
    'auto-optimise-store = true' \
    'experimental-features = nix-command flakes' \
    'substituters = https://mirror.sjtu.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org' \
    'trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    | sudo tee /etc/nix/nix.conf >/dev/null
sudo systemctl restart nix-daemon

# ---------- 6/6 重建 ran 的用户环境 ----------
echo "==> 6/6 重建用户环境（nix + home-manager + HM switch）"
if test -f /etc/profile.d/nix.fish
    source /etc/profile.d/nix.fish
end
if not command -v nix >/dev/null 2>&1
    set -gx PATH /nix/var/nix/profiles/default/bin $PATH
end

nix profile install nixpkgs#nix nixpkgs#home-manager
or begin
    echo "$RED[失败] 无法安装 nix/home-manager 到用户 profile$RST"
    exit 1
end

home-manager switch --flake ~/.config/home-manager#ran
or begin
    echo "$RED[失败] home-manager switch 失败$RST"
    exit 1
end

# ---------- 验证 ----------
echo "==> 验证"
systemctl is-active nix-daemon
nix store gc --dry-run
and echo "$GRN✅ 迁移完成！$RST"
echo
echo "  最后一步（确认一切正常后）:"
echo "    sudo rm -rf /nix.bak"
echo "  重启 shell 让 fish 环境变量生效: exec fish"
