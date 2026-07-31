{
  description = "Nix package for Felix Rieseberg's Clippy desktop assistant";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          clippy = pkgs.callPackage ./package.nix { };
          default = pkgs.callPackage ./package.nix { };
        });
    };
}
