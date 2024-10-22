{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

      zig-overlay.url = "github:mitchellh/zig-overlay";
      zig-overlay.inputs.nixpkgs.follows = "nixpkgs";

      flake-utils.url = "github:numtide/flake-utils";

      zigscient-src = {
        url = "github:llogick/zigscient";
        flake = false;
      };
    };

  outputs = { self, nixpkgs, zig-overlay, flake-utils, zigscient-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zig = zig-overlay.packages.${system}.master;
      in
      rec {
        formatter = pkgs.nixpkgs-fmt;
        packages.default = packages.zigscient;
        packages.zigscient = pkgs.stdenvNoCC.mkDerivation {
          name = "zigscient";
          version = "master";
          src = "${zigscient-src}";
          nativeBuildInputs = [ zig ];
          dontConfigure = true;
          dontInstall = true;
          doCheck = true;
          buildPhase = ''
            mkdir -p .cache
            ln -s ${pkgs.callPackage ./deps.nix { zig = zig; }} .cache/p
            zig build install --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline -Doptimize=ReleaseSafe --prefix $out
          '';
          checkPhase = ''
            zig build test --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline
          '';
        };
      }
    );
}
