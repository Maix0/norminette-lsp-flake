{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    norminette-lsp-src = {
      url = "github:bitquence/norminette-lsp";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
    norminette-lsp-src,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryApplication overrides;
    in {
      packages = {
        norminette-lsp = mkPoetryApplication {
          projectDir = norminette-lsp-src;
          python = pkgs.python311;
          overrides = overrides.withDefaults (self: super: {
            greenlet = pkgs.python311.greenlet;
            argparse =
              super.argparse.overridePythonAttrs
              (
                old: {
                  buildInputs = (old.buildInputs or []) ++ [super.setuptools];
                }
              );
          });
        };
        default = self.packages.${system}.norminette-lsp;
      };

      devShells.default = pkgs.mkShell {
        packages = [self.packages.${system}.norminette-lsp];
      };
    });
}
