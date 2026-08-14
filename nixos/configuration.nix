# ============================================================
# NixOS 系统配置 —— 共享部分（实机 + VM 通用）
# 硬件差异在 hardware-*.nix 声明
# 迁移自 Arch：niri 桌面 + home-manager + 滚挂防护
# ============================================================
{ config, pkgs, lib, ... }:

{
  # ---------- 基础 ----------
  system.stateVersion = "25.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # ---------- 用户 ----------
  users.users.ran = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "nixos"; # 首次登录后改密码
  };
  users.defaultUserShell = pkgs.fish;

  # ---------- 网络（保证迁移后能联网查资料） ----------
  networking.networkmanager.enable = true;

  # ---------- 桌面组件 ----------
  environment.systemPackages = with pkgs; [
    # 合成器/终端/锁屏/通知
    niri
    kitty
    hyprlock
    swaynotificationcenter
    # 输入法
    fcitx5
    fcitx5-rime
    fcitx5-gtk
    # 截图/剪贴板
    grim
    slurp
    wl-clipboard
    # 媒体
    mpv
    # 系统工具
    polkit_gnome
    xdg-desktop-portal-gnome
    # 字体
    noto-fonts-cjk-sans
    noto-fonts
    nerd-fonts.jetbrains-mono
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
  hardware.bluetooth.enable = true;

  # ---------- 桌面会话 ----------
  programs.fish.enable = true;
  programs.dconf.enable = true;

  # ---------- home-manager（复用现有配置） ----------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ran = import ../home.nix;
  };

  # ---------- XDG Portal ----------
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # ---------- 系统优化 ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # 定时清理 nix 历史
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
