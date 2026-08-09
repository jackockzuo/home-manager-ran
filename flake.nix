{
  description = "Home Manager configuration of ran";

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
      # 名字对应你命令中的 .#ran（与 home.username 一致）
      homeConfigurations."ran" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # 注意：modules 是列表 [ ]，结尾用 ]; 闭合
        modules = [
          ./home.nix
        ];
      };
    };
}
