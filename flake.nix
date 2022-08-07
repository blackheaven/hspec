{
  description = "hspec";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellPackages = pkgs.haskell.packages.ghc923.override {
          overrides = hself: hsuper:
            {
              hpack = hsuper.hpack_0_35_0;
              # hspec-meta = hsuper.hspec-meta_2_9_3;
              # hspec-discover = hsuper.hspec-discover_2_10_0;
              # hspec = hsuper.hspec_2_10_0;
            };
        };

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));
      in
      rec
      {
        packages.hspec-discover = haskellPackages.callCabal2nix "hspec-discover" ./hspec-discover rec { };
        packages.hspec-core = haskellPackages.callCabal2nix "hspec-core" ./hspec-core rec { };
        packages.hspec = # (ref:haskell-package-def)
          haskellPackages.callCabal2nix "hspec" ./. rec {
            # Dependency overrides go here
            hspec-core = packages.hspec-core;
            hspec-discover = packages.hspec-discover;
          };

        # defaultPackage = pkgs.linkFarmFromDrvs "all-hspec" (pkgs.lib.unique (builtins.attrValues packages));
        defaultPackage = packages.hspec;

        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            haskell-language-server
            ghcid
            cabal-install
          ];
          inputsFrom = [
            self.defaultPackage.${system}.env
          ];
        };
      });
}
