#!/usr/bin/env bash
# 一键更新流程：nix flake 更新 → home-manager 应用 → pacman 系统更新
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [1/3] 更新 nix flake 锁定版本"
nix flake update --flake "$REPO_DIR"

echo "==> [2/3] home-manager switch（应用新配置）"
home-manager switch --flake "$REPO_DIR#ran"

echo "==> [3/3] pacman 系统更新（手动确认）"
echo "    运行: sudo pacman -Syu"
echo "    AUR:  paru -Syu"

echo ""
echo "完成！若改动涉及 niri/DMS 配置，注销重登生效。"
