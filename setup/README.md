# Arch 重装傻瓜式恢复路线

流程：**官方镜像启动 → archinstall 装基础 → 一条命令恢复个性化**（nix 管开发工具链和个人配置，pacman 管系统应用）。

## 阶段 0（现在做一次）：推送仓库

```bash
cd ~/.config/home-manager
git add -A && git commit -m "backup: 完整配置 + 恢复脚本"
git push origin main
```

**前置**：GitHub 仓库设为 public（恢复脚本用 https 拉取，无需 SSH key）。

## 阶段 1：archinstall 装基础系统

```bash
# 从官方 archiso 启动后：
pacman -Sy archinstall && archinstall
```

推荐选项：

| 项 | 选择 |
|---|---|
| 镜像 | 国内选清华/中科大 |
| 文件系统 | btrfs（配合 snapper/grub-btrfs） |
| 引导 | GRUB |
| 桌面环境 | **none**（niri 由恢复脚本装） |
| 网络 | NetworkManager |
| 音频 | pipewire |
| 用户 | ran，加入 wheel |
| 显卡 | NVIDIA（或装完由恢复脚本装 nvidia-open-dkms） |

## 阶段 2：一条命令恢复

```bash
curl -sSL https://raw.githubusercontent.com/jackockzuo/home-manager-ran/main/setup/restore.sh | bash
```

自动完成（`setup/restore.sh`）：
1. 启用基础服务（NetworkManager / bluetooth / pipewire）
2. 安装 nix（官方安装器，含 flake）
3. `home-manager switch` → **自动安装全部 nix 开发工具 + 生成全部个人配置**（niri/kitty/fcitx5/neovim/fastfetch/毛玻璃…）
4. paru 批量安装 `pacman-packages.txt`（1295 个：全部显式安装包），随后自动 `dms greeter install/sync` 配置 DMS greeter 登录界面
5. 收尾检查

脚本首次运行会自动 `git clone` 仓库到 `~/dotfiles`；之后想更新配置：`cd ~/dotfiles && git pull && home-manager switch --flake .#ran`

## 阶段 3：重启验证

```bash
reboot   # 登录 DMS greeter → niri
```

- [ ] 终端 `Mod+T`（kitty）
- [ ] 输入法（fcitx5 + rime 雾凇）
- [ ] 声音（`wpctl status`）/ 蓝牙（`bluetoothctl`）/ 网络（`nmcli device`）
- [ ] 壁纸/overview 正常、`fastfetch` 面板

## 可选：恢复 DMS 用户配置（不在仓库，需手动备份）

```bash
cp -r ~/dms-backup/DankMaterialShell ~/.config/
```

## 常见坑

| 问题 | 解决 |
|---|---|
| niri 登录不了 | DMS greeter 默认以 niri 作为会话（`/etc/greetd/config.toml` 的 command 带 `--command niri`）；配置被改后重跑 `dms greeter install` 修复 |
| fcitx5 双份 | nix 装主程序，pacman 装 fcitx5-gtk/qt 模块（清单已含），勿删 |
| kitty 打不开 | 必须用 pacman 版（nix 版 EGL 与 nvidia 不兼容），清单已含 |
| 国内 GitHub 慢 | 手动 `git clone https://github.com/... ~/dotfiles` 用代理，再 `bash ~/dotfiles/setup/restore.sh` |

## DMS (DankMaterialShell) 配置管理

DMS 是**运行时写回**配置的活跃桌面壳，采用特殊策略（`modules/dms.nix`）：

| 部分 | 管理方式 |
|---|---|
| `themes/`（静态主题） | 仓库快照 `source/dms/themes`（声明式） |
| `settings.json` / `monitors.json`（运行时状态） | `home.activation` **首次部署**：仅当配置缺失时从仓库拷贝（重装恢复场景）；运行中 DMS 自由写，nix 不覆盖 |

**日常改完 DMS 设置后同步回仓库**（否则下次重装恢复的是旧快照）：
```bash
cp ~/.config/DankMaterialShell/settings.json ~/.config/home-manager/source/dms/
cp ~/.config/DankMaterialShell/monitors.json ~/.config/home-manager/source/dms/
cd ~/.config/home-manager && git add -A && git commit -m "sync dms config" && git push
```

## 日常更新流程

```bash
bash ~/dotfiles/setup/update.sh
# 或手动：
nix flake update --flake ~/dotfiles
home-manager switch --flake ~/dotfiles#ran
sudo pacman -Syu
```

DMS 配置同步（改过 DMS 设置后）：
```bash
cp ~/.config/DankMaterialShell/settings.json ~/dotfiles/source/dms/
cp ~/.config/DankMaterialShell/monitors.json ~/dotfiles/source/dms/
cd ~/dotfiles && git add -A && git commit -m "sync dms" && git push
```
