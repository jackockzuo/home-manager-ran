# ============================================================
# 实机硬件配置 —— RTX 4060 Laptop（闭源驱动）
# 用于 nvme1n1 全新安装 NixOS（Arch 盘整体让位）
# 注意：fileSystems 由安装时 nixos-generate-config 生成的
#       hardware-configuration.nix 提供（本文件不定义，避免冲突）
# ============================================================
{ config, pkgs, lib, ... }:

{
  # ---------- 主机名 ----------
  networking.hostName = "nixos-laptop";

  # ---------- 引导 ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------- NVIDIA（闭源驱动，与 Arch 一致） ----------
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
  };

  # ---------- 联网必需（迁移后立即能查资料） ----------
  environment.systemPackages = with pkgs; [
    # 浏览器（firefox + chromium，双保险）
    firefox
    chromium
    # 网络工具
    wget
    curl
    networkmanagerapplet
    # 网络诊断（联网排障/查资料必需）
    dnsutils        # dig/nslookup（DNS 查询）
    traceroute      # 路由追踪
    inetutils       # ping/telnet 等基础网络工具
    openssh         # ssh/scp 远程连接
  ];

  # ---------- 滚挂防护（snapper 快照回滚） ----------
  services.snapper = {
    # 定义 configs 即启用 snapper
    snapshotInterval = "15min";
    cleanupInterval = "1h";
    configs = {
      root = {
        SUBVOLUME = "/";
        freeLimit = 5;
        hourlyLimit = 5;
      };
    };
  };
  # systemd-boot 自动收录 snapper 快照（NixOS 原生，替代 Arch 的 grub-btrfs）
  boot.loader.systemd-boot.configurationLimit = 20;

  # ---------- zram（Arch 用了 zram 11.6G） ----------
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
}
