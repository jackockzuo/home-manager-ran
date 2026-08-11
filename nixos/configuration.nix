# ============================================================
# NixOS 系统配置 —— VM 测试用（为迁移 NixOS 做准备）
# 与 Arch 版对比：
#   Arch:   niri/hyprlock/kitty/mpv 等桌面组件由 pacman 管理
#   NixOS:  全部由 NixOS 系统模块管理（system packages / services）
# 本配置对应 Arch 的 pacman-packages.txt 中的系统级组件
# ============================================================
{ config, pkgs, lib, ... }:

{
  # ---------- 基础 ----------
  system.stateVersion = "24.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # 允许 unfree 包（unrar 等，NixOS 系统层必须显式允许）
  nixpkgs.config.allowUnfree = true;

  # ---------- 用户 ----------
  users.users.ran = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "nixos"; # 首次登录后建议改密码
  };
  users.defaultUserShell = pkgs.fish;

  # ---------- 网络 ----------
  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  # ---------- 桌面组件（原 pacman 管理 → NixOS 包） ----------
  environment.systemPackages = with pkgs; [
    # 合成器
    niri
    # 锁屏
    hyprlock
    # 终端
    kitty
    # 媒体
    mpv
    # 截图/剪贴板
    grim
    slurp
    wl-clipboard
    cliphist
    # 系统工具（VM 用 virtio-gpu，无 NVIDIA，不需要 nvidia-settings）
    xdg-desktop-portal-gnome
    polkit_gnome
    # 输入法
    fcitx5
    fcitx5-rime
    fcitx5-gtk
    # 字体（nerd-fonts 集合用小写 kebab-case 名称；Maple Mono 用 NF-CN 变体=Nerd Font+中文）
    nerd-fonts.jetbrains-mono
    maple-mono.NF-CN
    noto-fonts-cjk-sans
  ];

  # ---------- 服务 ----------
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "ran";
      };
    };
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  # 新版 nixpkgs 蓝牙选项在 hardware.bluetooth（services.bluetooth 已迁移）
  hardware.bluetooth.enable = true;

  # ---------- 桌面会话 ----------
  programs.fish.enable = true;
  programs.dconf.enable = true; # GTK 应用需要
  # xdg.portal 统一在下方定义（含 extraPortals）

  # ---------- NVIDIA ----------
  # VM 内用 virtio-gpu，无需 NVIDIA 配置（真实机迁移时启用）
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = true;
  # };

  # ---------- home-manager（复用现有配置） ----------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ran = import ../home.nix;
  };

  # ---------- 系统优化 ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------- 文件系统（VM 安装时用 nixos-generate-config 生成真实 UUID） ----------
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_ROOT_UUID";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_EFI_UUID";
    fsType = "vfat";
  };

  # ---------- XDG Portal（需指定具体实现，否则断言失败） ----------
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };
}
