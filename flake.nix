{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      ref = "2395e4f1f733dc2a048a1b048f259763b2622ea2";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-compat,
    flake-utils,
  }:
    {
      apps.aarch64-darwin = let
        pkgs = import nixpkgs {system = "aarch64-darwin";};
        writeZsh = pkgs.writers.makeScriptWriter {interpreter = "${pkgs.zsh}/bin/zsh";};
      in {
        start-pg = {
          type = "app";
          program = toString (writeZsh "start-pg" ''
            PATH="$PATH:${pkgs.postgresql_jit}/bin"
            ls "${pkgs.postgresql_jit}"
            ${(builtins.readFile ./temporary-postgresql.zsh)}
          '');
        };
        start-memcached = {
          type = "app";
          program = toString (writeZsh "start-pg" ''
            PATH="$PATH:${pkgs.memcached}/bin"
            memcached -vv
          '');
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      devShell = pkgs.mkShell {
        buildInputs = [
          (pkgs.postgresql_jit.overrideAttrs ({meta, ...}: {meta = meta // {outputsToInstall = meta.outputsToInstall ++ ["lib"];};}))
          pkgs.pkg-config
          pkgs.memcached
        ];
      };
    });
}
