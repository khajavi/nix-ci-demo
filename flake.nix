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

        mkDevShell = jdk: pkgs.mkShell {
          buildInputs = [
            jdk
            (pkgs.sbt.override { jre = jdk; })
            pkgs.git
            (pkgs.python3.withPackages (ps: [ ps.pyyaml ]))
          ];

          JAVA_HOME = "${jdk.home}";

          shellHook = ''
            # Use the versioned git hooks (regenerates scripts/ci.sh on commit)
            if [ -d .git ]; then git config core.hooksPath scripts/hooks; fi
            echo "Scala dev environment loaded"
            echo "JDK: $(java -version 2>&1 | head -1)"
            echo "sbt: $(sbt --version)"
          '';
        };
      in
      {
        devShells = {
          default = mkDevShell pkgs.jdk21;
          jdk17 = mkDevShell pkgs.jdk17;
          jdk21 = mkDevShell pkgs.jdk21;
        };
      }
    );
}
