{
  description = "ran 的 dotfiles：Arch/NixOS 双系统配置（nix 管配置/工具链）";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      # home-manager 通用参数
      hmConfig = modules: home-manager.lib.homeManagerConfiguration {
        inherit pkgs modules;
      };
    in {
      # ============ Arch（迁移前的当前系统，保留作对比） ============
      # 用法: home-manager switch --flake .#ran
      homeConfigurations."ran" = hmConfig [
        ./home.nix
      ];

      # 纯净桌面版（只桌面环境）: home-manager switch --flake .#ran-desktop
      homeConfigurations."ran-desktop" = hmConfig [
        ./modules/core.nix
        ./modules/desktop
      ];

      # ============ NixOS（迁移目标） ============
      # 实机安装: sudo nixos-install --flake .#laptop
      # 更新: sudo nixos-rebuild switch --flake .#laptop
      nixosConfigurations."laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          ./nixos/hardware-laptop.nix
          # 安装时由 nixos-generate-config 生成，覆盖为真实 UUID（见 nixos-install.md）
          ./nixos/hardware-configuration.nix
        ];
      };
    };
}
