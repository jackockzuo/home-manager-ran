# ran 的用户级配置 —— NixOS + Home Manager

> 本仓库是**用户级** home-manager 配置（`~/.config/home-manager`），
> 与系统级配置仓库 [nixos-config](https://github.com/jackockzuo/nixos-config) 配合使用。

## 架构

```
nixos-config（系统层）              home-manager-ran（本仓库，用户层）
├── configuration.nix  ──引用──▶  ├── home.nix        # 入口（纯聚合）
├── hardware-configuration.nix     ├── modules/
│                                  │   ├── core.nix    # 用户/环境变量/nix 配置
│                                  │   ├── desktop/    # 桌面配置（niri/kitty/fcitx5...）
│                                  │   └── tools/      # 开发工具链
└── flake.nix                       └── source/        # 配置源文件（niri/dms/beautify）
```

- **系统层**（nixos-config）：驱动、引导、服务、桌面二进制、greetd + DMS Greeter
- **用户层**（本仓库）：`~/.config` 下全部配置 + 工具链，由 home-manager 声明式管理
- 集成方式：nixos-config 的 flake 通过 `hm-ran` input 引用本仓库的 `home.nix`，
  `useGlobalPkgs = true`（二进制由系统层管理，HM 只管配置）

## 目录结构

```
├── flake.nix              # 入口：.#ran（standalone 验证用）
├── flake.lock             # 锁定 nixpkgs/home-manager 版本
├── home.nix               # 主入口（纯聚合，被 nixos-config 引用）
├── modules/
│   ├── core.nix           # 基础：用户身份/Wayland 环境变量/nix 客户端配置
│   ├── desktop/           # 桌面：niri/kitty/fcitx5(雾凇)/DMS/swaync/GTK/截图/portal
│   └── tools/             # 工具链：shell(fish+starship)/neovim/git/direnv
└── source/                # 配置源文件（niri 全套/dms 主题/fastfetch 等）
```

## 使用

### 更新配置（NixOS 实机）

系统级和用户级一起更新（都在同一个 `nixos-rebuild` 里）：

```bash
cd ~/nixos-config && sudo nixos-rebuild switch --flake .#omen
```

> 本仓库被 nixos-config 以 `path:` 本地引用（开发中）；
> 推送 GitHub 后可改为 `github:jackockzuo/home-manager-ran` 引用。

### 独立验证本仓库配置

```bash
nix build .#homeConfigurations.ran.activationPackage
```

### 开发/维护

1. 新增桌面配置：`modules/desktop/<name>.nix`（单一关注点）
2. 在 `modules/desktop/default.nix` 的 `imports` 加入
3. 修改源文件（niri 等）：直接改 `source/`，`nixos-rebuild` 自动同步
4. 验证：`nix flake check`（注意：本仓库 standalone 验证不依赖 nixos-config）

## 格式规范

所有 `.nix` 文件使用 nixpkgs 官方格式化器 [nixfmt](https://github.com/NixOS/nixfmt)（RFC 101 风格）：

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/ tools/ flake.nix home.nix
```

## 常用配置速查

| 类别 | 内容 | 位置 |
|---|---|---|
| 输入法 | fcitx5 + rime 雾凇拼音（Ctrl+Space 切换） | `modules/desktop/fcitx5.nix` + 系统层 `i18n.inputMethod` |
| 合成器 | niri（配置在 `source/niri/`） | `modules/desktop/niri.nix` |
| 桌面壳 | DMS DankMaterialShell + greeter 登录界面 | `modules/desktop/dms.nix` + 系统层 greeter 模块 |
| 终端 | kitty + fish + starship | `modules/desktop/kitty.nix`、`modules/tools/shell.nix` |
| 编辑器 | neovim（catppuccin + fcitx5 联动） | `modules/tools/neovim.nix` |
| 外观 | fastfetch/GTK 主题/光标 | `modules/desktop/appearance.nix` |
| 工具链 | git/direnv/btop/yazi/lazygit 等 | `modules/tools/default.nix` |

## 常见问题

| 问题 | 解决 |
|---|---|
| fcitx5 反复失效（missing input schema） | 系统层 `fcitx5-rime.override { rimeDataPkgs = [ rime-data rime-ice ]; }`，不要用 HM 塞词库 symlink（会被 rime 清理） |
| 修改后不生效 | 检查本仓库修改是否已提交（`path:` 引用时 nix 只取已提交内容，见 flake 说明） |
