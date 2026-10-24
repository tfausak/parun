{
  inputs = {
    cabal-gild.inputs.nixpkgs.follows = "nixpkgs";
    cabal-gild.url = "github:tfausak/cabal-gild-nix";
    hooky.inputs.nixpkgs.follows = "nixpkgs";
    hooky.url = "github:tfausak/hooky-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      cabal-gild,
      hooky,
      nixpkgs,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      inherit (nixpkgs.lib) fileset;

      source = fileset.toSource {
        root = ./.;
        fileset = fileset.unions [
          ./cabal.project
          ./CHANGELOG.md
          ./data
          ./LICENSE.txt
          ./parun.cabal
          ./README.md
          ./source
        ];
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          parun = pkgs.lib.pipe (pkgs.haskellPackages.callCabal2nix "parun" source { }) [
            pkgs.haskell.lib.compose.doBenchmark
            # Nothing in the tree uses Template Haskell, so the dynamic objects
            # GHC builds alongside the static ones are never loaded. cabal.project
            # says the same thing for local builds; this builder runs Setup
            # directly and never reads that file.
            pkgs.haskell.lib.compose.disableSharedExecutables
            pkgs.haskell.lib.compose.disableSharedLibraries
            (pkgs.haskell.lib.compose.enableCabalFlag "pedantic")
            (pkgs.haskell.lib.compose.overrideCabal (old: {
              postInstall = (old.postInstall or "") + ''
                install -D -m 755 dist/build/parun-benchmark/parun-benchmark "$out/bin/parun-benchmark"
              '';

              testFlags = (old.testFlags or [ ]) ++ [
                "--hide-successes"
                "--timeout"
                "120s"
              ];
            }))
          ];
        in
        {
          default = parun;
          benchmark = pkgs.runCommand "parun-benchmark-results" { } ''
            mkdir -p "$out"
            ${parun}/bin/parun-benchmark --csv "$out/bench.csv" +RTS -T
          '';
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          cabal = pkgs.runCommand "parun-cabal-check" { nativeBuildInputs = [ pkgs.cabal-install ]; } ''
            cd ${source}
            cabal check
            touch "$out"
          '';

          gild =
            pkgs.runCommand "parun-gild-check"
              { nativeBuildInputs = [ cabal-gild.packages.${system}.default ]; }
              ''
                cd ${source}
                cabal-gild --mode check parun.cabal
                touch "$out"
              '';

          hlint = pkgs.runCommand "parun-hlint-check" { nativeBuildInputs = [ pkgs.hlint ]; } ''
            cd ${source}
            hlint --hint=${./.hlint.yaml} --threads="$NIX_BUILD_CORES" source
            touch "$out"
          '';

          nixfmt = pkgs.runCommand "parun-nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check ${./flake.nix}
            touch "$out"
          '';

          ormolu = pkgs.runCommand "parun-ormolu-check" { nativeBuildInputs = [ pkgs.ormolu ]; } ''
            cd ${source}
            find source -name '*.hs' -print0 | xargs -0 ormolu --mode check
            touch "$out"
          '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ci = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.cabal-install
              pkgs.ghc
            ];
          };
        in
        {
          inherit ci;

          default = pkgs.mkShell {
            inputsFrom = [ ci ];

            nativeBuildInputs = [
              cabal-gild.packages.${system}.default
              hooky.packages.${system}.default
              pkgs.bash
              pkgs.coreutils
              pkgs.fzf
              pkgs.gh
              pkgs.ghcid
              pkgs.git
              pkgs.hlint
              pkgs.jq
              pkgs.nixfmt
              pkgs.ormolu
              pkgs.ripgrep
              pkgs.xdg-utils
            ];

            shellHook = ''
              if test -d .git && ! test -f .git/hooks/pre-commit
              then hooky install
              fi
            '';
          };
        }
      );
    };
}
