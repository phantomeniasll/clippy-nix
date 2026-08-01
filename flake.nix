{
  description = "Nix package for Felix Rieseberg's Clippy desktop assistant";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.clippy-src.url = "github:phantomeniasll/clippy";
  inputs.clippy-src.flake = false;

  outputs = { nixpkgs, clippy-src, ... }:
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
          clippy = pkgs.callPackage ./package.nix { clippySrc = clippy-src; };
          default = pkgs.callPackage ./package.nix { clippySrc = clippy-src; };
        });
    };
}
