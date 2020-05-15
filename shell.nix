let
  sources = import ./nix/sources.nix;
  haskellNix = import sources.haskell-nix {};
  pkgs = import sources.nixpkgs {};
  niv = import sources.niv { inherit pkgs; };
  hsPkgs = import ./default.nix {};
  nix-pre-commit-hooks = import sources.pre-commit-hooks;
  pre-commit-check = nix-pre-commit-hooks.run {
    src = ./.;
    hooks = {
      nixpkgs-fmt.enable = true;
      ormolu.enable = true;
    };
  };
in
hsPkgs.shellFor {
  inherit (pre-commit-check) shellHook;
  packages = ps: [ ps.blog ];
  exactDeps = true;
  buildInputs = with pkgs; [
    niv.niv
    nixpkgs-fmt
    nodejs-12_x
  ];
}
