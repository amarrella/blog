let
  sources = import ./nix/sources.nix;
  haskellNix = import sources.haskell-nix {};
  nixpkgsSrc = haskellNix.sources.nixpkgs-1909;
  nixpkgsArgs = haskellNix.nixpkgsArgs;
in
{ pkgs ? import nixpkgsSrc nixpkgsArgs
}:
  pkgs.haskell-nix.stackProject {
    src = ./src;
  }
