{
  description = "Hello World Scala project with reproducible build environment";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            jdk21
            sbt
            git
          ];
          
          shellHook = ''
            echo "Scala dev environment loaded"
            echo "JDK: $(java -version 2>&1 | head -1)"
            echo "sbt: $(sbt --version)"
          '';
        };
      }
    );
}
