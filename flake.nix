{
  description = "ran 的用户级配置（NixOS + home-manager）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # 本机 NixOS 通过 ~/nixos-config 的 hm-ran input 引用 ./home.nix（见 nixos-config/flake.nix）。
      # 此 standalone 配置保留用于独立验证 / 在非 NixOS 机器复用：
      #   nix build .#homeConfigurations.ran.activationPackage
      homeConfigurations.ran = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          # standalone 模式需要自行允许 unfree（unrar 等）；
          # NixOS 集成时由系统层 nixpkgs.config.allowUnfree 提供，此处不参与
          {
            nixpkgs.config.allowUnfree = true;
          }
          ./home.nix
        ];
      };
    };
}
