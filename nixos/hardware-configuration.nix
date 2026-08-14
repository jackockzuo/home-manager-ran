# ============================================================
# hardware-configuration.nix —— 安装时由 nixos-generate-config 生成
# 本文件为模板：实机安装时，运行 nixos-generate-config --root /mnt 后
# 用生成的 /mnt/etc/nixos/hardware-configuration.nix 覆盖本文件
# （flake 引用本文件提供真实 UUID 的 fileSystems）
# 注意：CPU 为 Intel i9-13900HX（kvm-intel + intel microcode）
# ============================================================
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_ROOT_UUID";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd:3" "ssd" "discard=async" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_HOME_UUID";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:3" "ssd" "discard=async" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_EFI_UUID";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
