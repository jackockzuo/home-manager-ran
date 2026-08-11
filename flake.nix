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
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      # home-manager 通用参数
      hmConfig = modules: home-manager.lib.homeManagerConfiguration {
        inherit pkgs modules;
      };
    in {
      # ============ Arch 桌面 ============
      # 完整配置（桌面 + 工具链）: home-manager switch --flake .#ran
      homeConfigurations."ran" = hmConfig [
        ./home.nix
      ];

      # 纯净桌面版（只桌面环境，无开发工具链）: home-manager switch --flake .#ran-desktop
      homeConfigurations."ran-desktop" = hmConfig [
        ./modules/core.nix
        ./modules/desktop
      ];
    };
}
