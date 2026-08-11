# ============================================================
# 实机硬件配置 —— RTX 4060 Laptop（闭源驱动）
# 用于 nvme1n1 全新安装 NixOS（Arch 盘整体让位）
# ============================================================
{ config, pkgs, lib, ... }:

{
  # ---------- 主机名（与 Arch 版保持一致） ----------
  networking.hostName = "nixos-laptop";

  # ---------- 引导 ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------- 文件系统（实机安装时用 nixos-generate-config 生成真实 UUID） ----------
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_ROOT_UUID";
    fsType = "btrfs";
    options = [ "compress=zstd:3" "ssd" "discard=async" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_HOME_UUID";
    fsType = "btrfs";
    options = [ "compress=zstd:3" "ssd" "discard=async" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_EFI_UUID";
    fsType = "vfat";
  };

  # ---------- NVIDIA（闭源驱动，与 Arch 的 nvidia 一致） ----------
  hardware.graphics.enable = true;  # 旧名 hardware.opengl
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;                 # 闭源驱动（RTX 4060 用 nvidia 稳定版）
    nvidiaSettings = true;
    # 笔记本无 MUX 切换（独显直连），不用 PRIME offload/sync，
    # 避免断言冲突；powerManagement 用基础模式
    powerManagement.enable = true;
    # 注意：不开 finegrained（与无 PRIME 冲突）
  };

  # ---------- 从 Arch 迁移的系统组件（pacman-packages.txt 系统级） ----------
  environment.systemPackages = with pkgs; [
    # NVIDIA 工具（nvidia-settings 由 hardware.nvidia.nvidiaSettings 自动安装）
    # 系统监控/硬件
    htop
    smartmontools
    acpi
    acpid
    brightnessctl
    # 文件系统工具（btrfs 对应 Arch 的 btrfs-progs/btrfs-assistant）
    btrfs-progs
    # 网络工具
    wget
    tmux
    # 蓝牙 GUI 管理器（Arch 的 bluez-utils CLI 对应；bluetoothctl 由 hardware.bluetooth 自带）
    blueman
  ];

  # ---------- 服务（对应 Arch 的 systemd 服务） ----------
  services.acpid.enable = true;
  services.udisks2.enable = true;
  # 蓝牙由共享配置 hardware.bluetooth.enable 启用，这里补工具链
  hardware.bluetooth.powerOnBoot = true;

  # ---------- zram（Arch 用了 zram-generator，11.6G） ----------
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  # ---------- 电源管理（笔记本） ----------
  powerManagement.enable = true;
  services.tlp.enable = true;   # 与 Arch 的电源习惯一致（可选，如实机不用可删）
}
