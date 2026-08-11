# ============================================================
# NixOS VM 硬件配置 —— 用于 nixos-disk.img 验证安装
# 与实机差异：virtio-gpu（无 NVIDIA）、virtio 磁盘、VM 专用 fileSystems
# ============================================================
{ config, pkgs, lib, ... }:

{
  # ---------- 主机名（VM 专用） ----------
  networking.hostName = "nixos-vm";

  # ---------- 引导 ----------
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

  # ---------- VM 图形（virtio-gpu，无 NVIDIA） ----------
  # 无需任何 NVIDIA 配置；virtio-gpu 由内核模块自动加载
  services.xserver.videoDrivers = [ "modesetting" ];
}
