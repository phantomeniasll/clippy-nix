{
  description = "Nix package for Felix Rieseberg's Clippy desktop assistant";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # Keep llama.cpp's compiler and ROCm closure stable across routine updates
  # to the package set used for Clippy itself.
  inputs.llama-nixpkgs.url = "github:NixOS/nixpkgs/c59305bab2065cfecc4944690d9eedbb56f3a9fa";
  inputs.clippy-src.url = "github:phantomeniasll/clippy";
  inputs.clippy-src.flake = false;

  outputs = { nixpkgs, llama-nixpkgs, clippy-src, ... }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          llamaPkgs = llama-nixpkgs.legacyPackages.${system};
          clippy = pkgs.callPackage ./package.nix {
            clippySrc = clippy-src;
            inherit (llamaPkgs) fetchFromGitHub llama-cpp;
          };
        in
        {
          inherit clippy;
          default = clippy;
        });
    };
}
