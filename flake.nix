{
  description = "ran 的 dotfiles：Arch 桌面环境（nix 管配置/工具链）+ home-manager 分层管理";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # home-manager 通用参数
      hmConfig = modules: home-manager.lib.homeManagerConfiguration {
        inherit pkgs modules;
      };
    in {
      # ============ Arch（当前主力系统）============
      # 完整配置（桌面 + 工具链）: home-manager switch --flake .#ran
      homeConfigurations."ran" = hmConfig [
        ./home.nix
      ];

      # 纯净桌面版（只桌面环境，无开发工具链）: home-manager switch --flake .#ran-desktop
      homeConfigurations."ran-desktop" = hmConfig [
        ./modules/core.nix
        ./modules/desktop
      ];

      # ============ NixOS（预留，暂不使用）============
      # 用法: sudo nixos-rebuild switch --flake .#nixos-vm
      nixosConfigurations."nixos-vm" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          ./nixos/hardware-vm.nix
        ];
      };
    };
}
