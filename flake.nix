{
  description = "ran 的系统配置：Arch 用 home-manager，NixOS 用 nixosConfigurations + home-manager";

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
    in {
      # ============ Arch（当前主力系统）============
      # 用法: home-manager switch --flake .#ran
      homeConfigurations."ran" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # 注意：modules 是列表 [ ]，结尾用 ]; 闭合
        modules = [
          ./home.nix
        ];
      };

      # ============ NixOS（迁移目标，VM 测试用）============
      # 用法: sudo nixos-rebuild switch --flake .#nixos-vm
      # 注意：home-manager.users.ran 已在 nixos/configuration.nix 中导入 home.nix，
      # 这里不再重复，避免选项重复定义
      nixosConfigurations."nixos-vm" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
